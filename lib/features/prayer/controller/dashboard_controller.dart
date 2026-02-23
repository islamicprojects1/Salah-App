import 'dart:async';
import 'package:flutter/material.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/storage_keys.dart';
import 'package:salah/core/error/app_logger.dart';
import 'package:salah/core/feedback/app_feedback.dart';
import 'package:salah/core/services/storage_service.dart';
import 'package:salah/core/di/injection_container.dart';
import 'package:salah/core/routes/app_routes.dart';
import 'package:salah/core/services/location_service.dart';
import 'package:salah/core/widgets/app_dialogs.dart';
import 'package:salah/features/auth/data/repositories/user_repository.dart';
import 'package:salah/features/auth/data/services/auth_service.dart';
import 'package:salah/features/prayer/data/models/prayer_log_model.dart';
import 'package:salah/features/prayer/data/models/prayer_time_model.dart';
import 'package:salah/features/prayer/data/repositories/prayer_repository.dart';
import 'package:salah/features/prayer/data/services/live_context_service.dart';
import 'package:salah/features/prayer/data/services/notification_service.dart';
import 'package:salah/features/prayer/data/services/notification_scheduler.dart';
import 'package:salah/features/prayer/data/services/prayer_logger.dart';
import 'package:salah/features/prayer/data/services/prayer_time_service.dart';
import 'package:salah/features/prayer/data/services/qada_detection_service.dart';
import 'package:salah/features/prayer/presentation/widgets/qada_review_bottom_sheet.dart';
import 'package:permission_handler/permission_handler.dart';

/// Dashboard controller – thin orchestrator for the main prayer screen.
///
/// All heavy lifting is delegated to:
/// - [PrayerLogger] — prayer log operations
/// - [NotificationScheduler] — notification scheduling
/// - [LiveContextService] — real-time prayer context
/// - [QadaDetectionService] — missed prayer detection
class DashboardController extends GetxController with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  // --- Dependencies ---
  final PrayerTimeService _prayerService;
  final LocationService _locationService;
  final AuthService _authService;
  final UserRepository _userRepo;
  final PrayerRepository _prayerRepo;
  final NotificationService _notificationService;
  final LiveContextService _liveContextService;
  final QadaDetectionService _qadaService;
  final PrayerLogger _prayerLogger;
  final NotificationScheduler _notificationScheduler;

  DashboardController({
    required PrayerTimeService prayerService,
    required LocationService locationService,
    required AuthService authService,
    required UserRepository userRepo,
    required PrayerRepository prayerRepo,
    required NotificationService notificationService,
    required LiveContextService liveContextService,
    required QadaDetectionService qadaService,
    required PrayerLogger prayerLogger,
    required NotificationScheduler notificationScheduler,
  })  : _prayerService = prayerService,
        _locationService = locationService,
        _authService = authService,
        _userRepo = userRepo,
        _prayerRepo = prayerRepo,
        _notificationService = notificationService,
        _liveContextService = liveContextService,
        _qadaService = qadaService,
        _prayerLogger = prayerLogger,
        _notificationScheduler = notificationScheduler;

  // --- Observables ---
  final isLoading = true.obs;
  final currentPrayer = Rxn<PrayerTimeModel>();
  final nextPrayer = Rxn<PrayerTimeModel>();
  final timeUntilNextPrayer = ''.obs;
  final todayPrayers = <PrayerTimeModel>[].obs;
  final currentCity = ''.obs;
  final currentStreak = 0.obs;
  final currentTabIndex = 0.obs;
  final dailyPrayerCounts = <DateTime, int>{}.obs;

  /// Single source of truth from [LiveContextService].
  RxList<PrayerLogModel> get todayLogs => _liveContextService.todayLogs;

  Timer? _timer;
  Timer? _midnightTimer;
  StreamSubscription<dynamic>? _notificationsSubscription;

  // --- Tab Navigation ---
  void changeTab(int index) => currentTabIndex.value = index;

  // --- Lifecycle ---

  @override
  void onInit() {
    WidgetsBinding.instance.addObserver(this);
    super.onInit();
    _syncLocationLabel();
    ever(_locationService.cityName, (_) => _syncLocationLabel());
    ever(_locationService.isUsingDefaultLocation, (_) => _syncLocationLabel());
    _initDashboard();
    ever(_liveContextService.prayerContext, (ctx) {
      currentPrayer.value = ctx.currentPrayer;
      nextPrayer.value = ctx.nextPrayer;
      timeUntilNextPrayer.value = ctx.formattedCountdown;
    });
    ever(_prayerService.isLoading, (loading) {
      if (!loading && !isLoading.value) {
        _loadPrayerTimes();
      }
    });
  }

  @override
  void onReady() {
    super.onReady();
    _listenForEncouragements();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _prayerLogger.processPendingPrayerLogFromNotification();
      _qadaService.checkForUnloggedPrayers();
      if (_qadaService.hasMidnightPassed()) {
        _handleMidnightRollover();
      }
    }
  }

  // --- Location ---

  void _syncLocationLabel() {
    currentCity.value = _locationService.locationDisplayLabel;
  }

  bool get isUsingDefaultLocation =>
      _locationService.isUsingDefaultLocation.value;

  Future<void> openSelectCity() async {
    final result = await Get.toNamed(AppRoutes.selectCity);
    final updated = result as bool?;
    if (updated == true) {
      await _prayerService.calculatePrayerTimes();
      _loadPrayerTimes();
    }
  }

  // --- Qada ---

  RxList get unloggedPrayers => _qadaService.allPendingQada;

  Future<void> openQadaReview() async {
    await _qadaService.checkForUnloggedPrayers();
    if (_qadaService.allPendingQada.isEmpty) {
      Get.snackbar(
        'qada_hint_title'.tr,
        'qada_none'.tr,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      return;
    }
    await QadaReviewBottomSheet.show();
  }

  Future<void> _maybeShowQadaHint() async {
    try {
      if (_qadaService.allPendingQada.isEmpty) return;
      final storage = sl<StorageService>();
      final today = DateTime.now().toIso8601String().substring(0, 10);
      if (storage.read<String>(StorageKeys.lastQadaHintDate) == today) return;
      await AppDialogs.show(
        title: 'qada_hint_title'.tr,
        message: 'qada_hint_message'.tr,
        cancelText: 'close'.tr,
        confirmText: 'qada_review_action'.tr,
        onCancel: () {
          storage.write(StorageKeys.lastQadaHintDate, today);
          Get.back();
        },
        onConfirm: () {
          storage.write(StorageKeys.lastQadaHintDate, today);
          Get.back();
          QadaReviewBottomSheet.show();
        },
      );
    } catch (e) {
      AppLogger.debug('Qada hint failed', e);
    }
  }

  // --- Notification Permission Hint ---

  Future<void> _maybeShowNotificationPermissionHint() async {
    try {
      final storage = sl<StorageService>();
      final enabled =
          storage.read<bool>(StorageKeys.notificationsEnabled) ?? true;
      if (!enabled) return;
      final status = await Permission.notification.status;
      if (status.isGranted) return;
      final hintShown =
          storage.read<bool>(StorageKeys.notificationPermissionHintShown) ??
              false;
      if (hintShown) return;
      await AppDialogs.show(
        title: 'notification_permission'.tr,
        message: 'notification_permission_hint'.tr,
        cancelText: 'close'.tr,
        confirmText: 'open_settings'.tr,
        onCancel: () {
          storage.write(StorageKeys.notificationPermissionHintShown, true);
          Get.back();
        },
        onConfirm: () {
          storage.write(StorageKeys.notificationPermissionHintShown, true);
          openAppSettings();
          Get.back();
        },
      );
    } catch (e) {
      AppLogger.debug('Notification permission hint failed', e);
    }
  }

  // --- Init & Data Loading ---

  Future<void> _initDashboard() async {
    isLoading.value = true;
    try {
      await _locationService.init();
      _syncLocationLabel();
      await _loadPrayerTimes();

      isLoading.value = false;

      _loadStreak();
      _prayerLogger.processPendingPrayerLogFromNotification();
      _startTimer();
      _scheduleMidnightRollover();
      _qadaService.checkForUnloggedPrayers();
      _loadHeatmapData();

      Future.delayed(const Duration(seconds: 2), () async {
        await _notificationService.requestPermissions();
        _maybeShowNotificationPermissionHint();
        _maybeShowQadaHint();
      });
    } catch (e) {
      AppLogger.error('Dashboard init failed', e);
      AppFeedback.showError('error'.tr, 'dashboard_load_error'.tr);
      isLoading.value = false;
    }
  }

  Future<void> _loadPrayerTimes() async {
    final prayers = _prayerService.getTodayPrayers();
    todayPrayers.assignAll(prayers);
    _updateCurrentAndNextPrayer();
    _notificationScheduler.scheduleNotifications(todayPrayers);
  }

  Future<void> _loadHeatmapData() async {
    final userId = _authService.userId;
    if (userId == null) return;
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 182));
      final logs = await _prayerRepo.getPrayerLogsInRange(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );
      final Map<DateTime, int> counts = {};
      for (final log in logs) {
        if (log.prayer == PrayerName.sunrise) continue;
        final day = DateTime(
          log.prayedAt.year,
          log.prayedAt.month,
          log.prayedAt.day,
        );
        counts[day] = (counts[day] ?? 0) + 1;
        if ((counts[day] ?? 0) > 5) counts[day] = 5;
      }
      dailyPrayerCounts.assignAll(counts);
    } catch (e) {
      AppLogger.debug('Heatmap load failed (non-critical)', e);
    }
  }

  Future<void> _loadStreak() async {
    final userId = _authService.userId;
    if (userId == null) return;
    currentStreak.value = await _prayerRepo.getCurrentStreak(userId);
  }

  // --- Encouragements ---

  void _listenForEncouragements() {
    final userId = _authService.userId;
    if (userId == null) return;
    _notificationsSubscription?.cancel();
    _notificationsSubscription = _userRepo
        .getUnreadUserNotificationsStream(userId)
        .listen(
      (snapshot) {
        for (final doc in snapshot.docs) {
          final data = doc.data();
          if (data['type'] == 'encouragement') {
            AppFeedback.showSnackbar(
              data['fromName'] ?? 'عضو عائلة',
              data['message'] ?? 'شجعك على الصلاة',
            );
          }
          _userRepo.markUserNotificationAsRead(
            userId: userId,
            notificationId: doc.id,
          );
        }
      },
      onError: (e) {
        AppLogger.debug('Dashboard: encourages stream error: $e');
      },
    );
  }

  // --- Prayer Time Tracking ---

  void _updateCurrentAndNextPrayer() {
    final now = DateTime.now();
    PrayerTimeModel? next;
    PrayerTimeModel? current;
    for (final prayer in todayPrayers) {
      if (prayer.dateTime.isAfter(now)) {
        next = prayer;
        break;
      }
      if (prayer.prayerType != PrayerName.sunrise) {
        current = prayer;
      }
    }
    currentPrayer.value = current;
    nextPrayer.value = next;
    _updateTimeUntilNext();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateTimeUntilNext(),
    );
  }

  void _updateTimeUntilNext() {
    if (nextPrayer.value == null) {
      timeUntilNextPrayer.value = '--:--:--';
      return;
    }
    final difference = nextPrayer.value!.dateTime.difference(DateTime.now());
    if (difference.isNegative) {
      _loadPrayerTimes();
      return;
    }
    final hours = difference.inHours;
    final minutes = difference.inMinutes.remainder(60);
    final seconds = difference.inSeconds.remainder(60);
    timeUntilNextPrayer.value =
        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // --- Prayer Logging (delegates to PrayerLogger) ---

  Future<void> logPrayer(PrayerTimeModel prayer) async {
    final streak = await _prayerLogger.logPrayer(prayer);
    if (streak != null) {
      currentStreak.value = streak;
      _celebrateAllPrayersDone();
    }
  }

  Future<void> logPastPrayer(PrayerTimeModel prayer) async {
    final streak = await _prayerLogger.logPastPrayer(prayer);
    if (streak != null) {
      currentStreak.value = streak;
      _celebrateAllPrayersDone();
    }
  }

  Future<void> logAllUnloggedPrayers() async {
    final streak =
        await _prayerLogger.logAllUnloggedPrayers(todayPrayers);
    if (streak != null) {
      currentStreak.value = streak;
    }
  }

  // --- Refresh ---

  Future<void> refreshDashboard() async {
    final userId = _authService.userId;
    if (userId == null) return;
    await _locationService.getCurrentLocation();
    await _loadPrayerTimes();
    await _loadStreak();
  }

  // --- Midnight Rollover & Celebration ---

  void _scheduleMidnightRollover() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 0, 0, 5);
    final delay = tomorrow.difference(now);
    _midnightTimer = Timer(delay, _handleMidnightRollover);
  }

  void _handleMidnightRollover() {
    _qadaService.resetAllSnoozeCounts();
    _loadPrayerTimes();
    _loadStreak();
    _loadHeatmapData();
    _qadaService.checkForUnloggedPrayers();
    _scheduleMidnightRollover();
  }

  void _celebrateAllPrayersDone() {
    AppFeedback.showSuccess('all_prayers_complete'.tr, 'god_accept_prayers'.tr);
  }

  /// Call before logout to stop Firestore listeners and avoid permission-denied.
  void cancelStreamsForLogout() {
    _notificationsSubscription?.cancel();
    _notificationsSubscription = null;
  }

  @override
  void onClose() {
    _timer?.cancel();
    _midnightTimer?.cancel();
    _notificationsSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }
}
