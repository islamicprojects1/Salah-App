import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/helpers/prayer_names.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/api_constants.dart';
import 'package:salah/core/constants/storage_keys.dart';
import 'package:salah/core/feedback/app_feedback.dart';
import 'package:salah/core/services/storage_service.dart';
import 'package:salah/core/di/injection_container.dart';
import 'package:salah/core/routes/app_routes.dart';
import 'package:salah/core/services/location_service.dart';
import 'package:salah/features/auth/data/repositories/user_repository.dart';
import 'package:salah/features/auth/data/services/auth_service.dart';
import 'package:salah/features/family/data/services/family_service.dart';
import 'package:salah/features/prayer/data/models/prayer_log_model.dart';
import 'package:salah/features/prayer/data/models/prayer_time_model.dart';
import 'package:salah/features/prayer/data/repositories/prayer_repository.dart';
import 'package:salah/features/prayer/data/services/firestore_service.dart';
import 'package:salah/features/prayer/data/services/live_context_service.dart';
import 'package:salah/features/prayer/data/services/notification_service.dart';
import 'package:salah/features/prayer/data/services/prayer_time_service.dart';
import 'package:salah/features/prayer/data/services/qada_detection_service.dart';
import 'package:salah/features/prayer/presentation/widgets/qada_review_bottom_sheet.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:salah/core/widgets/app_dialogs.dart';

/// Dashboard controller – UI logic only. All data comes from [PrayerRepository],
/// [UserRepository], [PrayerTimeService], [LocationService], [NotificationService].
/// Reactive: observables are updated from repository streams/calls; UI uses Obx.
class DashboardController extends GetxController with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  final PrayerTimeService _prayerService;
  final LocationService _locationService;
  final AuthService _authService;
  final UserRepository _userRepo;
  final PrayerRepository _prayerRepo;
  final NotificationService _notificationService;
  final LiveContextService _liveContextService;
  final QadaDetectionService _qadaService;

  DashboardController({
    required PrayerTimeService prayerService,
    required LocationService locationService,
    required AuthService authService,
    required UserRepository userRepo,
    required PrayerRepository prayerRepo,
    required NotificationService notificationService,
    required LiveContextService liveContextService,
    required QadaDetectionService qadaService,
  }) : _prayerService = prayerService,
       _locationService = locationService,
       _authService = authService,
       _userRepo = userRepo,
       _prayerRepo = prayerRepo,
       _notificationService = notificationService,
       _liveContextService = liveContextService,
       _qadaService = qadaService;

  final isLoading = true.obs;
  final currentPrayer = Rxn<PrayerTimeModel>();
  final nextPrayer = Rxn<PrayerTimeModel>();
  final timeUntilNextPrayer = ''.obs;
  final todayPrayers = <PrayerTimeModel>[].obs;

  /// Single source of truth from [LiveContextService]
  RxList<PrayerLogModel> get todayLogs => _liveContextService.todayLogs;
  final currentCity = ''.obs;
  final currentStreak = 0.obs;
  final currentTabIndex = 0.obs;
  final dailyPrayerCounts = <DateTime, int>{}.obs;

  void changeTab(int index) => currentTabIndex.value = index;

  void changeTabIndex(int index) => currentTabIndex.value = index;

  Timer? _timer;
  Timer? _midnightTimer;
  StreamSubscription<dynamic>? _notificationsSubscription;

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

    // React to prayer times being recalculated (e.g. after city/method change)
    ever(_prayerService.isLoading, (loading) {
      if (!loading && !isLoading.value) {
        _loadPrayerTimes();
      }
    });
  }

  @override
  void onReady() {
    super.onReady();
    // Only start notification listener after the dashboard screen is built so ToastService has a valid overlay
    _listenForEncouragements();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _processPendingPrayerLogFromNotification();
      // todayLogs come from LiveContextService stream
      // Check for missed prayers on app resume
      _qadaService.checkForUnloggedPrayers();
      // Detect midnight rollover on resume
      if (_qadaService.hasMidnightPassed()) {
        _handleMidnightRollover();
      }
    }
  }

  void _syncLocationLabel() {
    currentCity.value = _locationService.locationDisplayLabel;
  }

  /// True when times are based on default (e.g. Makkah) instead of user location.
  bool get isUsingDefaultLocation =>
      _locationService.isUsingDefaultLocation.value;

  /// Navigate to city selection (e.g. from location hint banner).
  void openSelectCity() => Get.toNamed(AppRoutes.selectCity);

  /// If there are unlogged prayers, show hint at most once per day and offer to open qada review.
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
    } catch (_) {}
  }

  /// If notifications are enabled in app but system permission is denied, show hint once.
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
    } catch (_) {}
  }

  Future<void> _initDashboard() async {
    isLoading.value = true;
    try {
      // 1. Critical Data (Blocking)
      await _locationService.init();
      _syncLocationLabel();
      await _loadPrayerTimes();

      // 2. Show UI immediately
      isLoading.value = false;

      // 3. Background Data (Non-blocking) — todayLogs from LiveContextService
      _loadStreak();
      _processPendingPrayerLogFromNotification();
      // _listenForEncouragements() moved to onReady() so toasts only run after overlay is built
      _startTimer();
      _scheduleMidnightRollover();
      _qadaService.checkForUnloggedPrayers();

      // 4. Heavy/External operations (Deferred)
      // Load heatmap data
      _loadHeatmapData();

      // Request permissions and one-time hints after a delay
      Future.delayed(const Duration(seconds: 2), () async {
        await _notificationService.requestPermissions();
        _maybeShowNotificationPermissionHint();
        _maybeShowQadaHint();
      });
    } catch (_) {
      AppFeedback.showError('error'.tr, 'dashboard_load_error'.tr);
      isLoading.value = false;
    }
  }

  Future<void> _loadPrayerTimes() async {
    final prayers = _prayerService.getTodayPrayers();
    todayPrayers.assignAll(prayers);
    _updateCurrentAndNextPrayer();
    _scheduleNotifications();
  }

  /// Load prayer data for the heatmap (last 6 months).
  Future<void> _loadHeatmapData() async {
    final userId = _authService.userId;
    if (userId == null) return;
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(
        const Duration(days: 182),
      ); // ~6 months
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
        if ((counts[day] ?? 0) > 5) counts[day] = 5; // Cap at 5
      }
      dailyPrayerCounts.assignAll(counts);
    } catch (_) {
      // Silently fail — heatmap is non-critical
    }
  }

  /// Process prayer log that was requested from notification action (when app wasn't ready)
  Future<void> _processPendingPrayerLogFromNotification() async {
    final storage = sl<StorageService>();
    final raw = storage.read<String>(StorageKeys.pendingPrayerLog);
    if (raw == null || raw.isEmpty) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final prayerKey = map['prayerKey'] as String?;
      final adhanIso = map['adhanTime'] as String?;
      final baseId = map['baseId'] as int?;
      if (prayerKey == null || adhanIso == null) return;
      final userId = _authService.userId;
      if (userId == null) return;
      final adhanTime = DateTime.tryParse(adhanIso);
      if (adhanTime == null) return;
      final prayer = PrayerNames.fromKey(prayerKey);
      final displayName = PrayerNames.displayName(prayer);
      final log = PrayerLogModel.create(
        oderId: userId,
        prayer: prayer,
        adhanTime: adhanTime,
      );
      final synced = await _prayerRepo.addPrayerLog(userId: userId, log: log);
      _addPulseIfFamily(displayName);
      if (baseId != null) {
        await _notificationService.cancelNotification(baseId);
        await _notificationService.cancelNotification(baseId + 100);
      }
      await storage.remove(StorageKeys.pendingPrayerLog);
      _liveContextService.onPrayerLogged();
      if (synced) {
        AppFeedback.showSuccess(
          'done'.tr,
          'prayer_logged_from_notif'.trParams({'prayer': displayName}),
        );
      } else {
        AppFeedback.showSuccess('done'.tr, 'saved_will_sync_later'.tr);
      }
    } catch (_) {}
  }

  // _prayerKeyToName removed – use PrayerNames.fromKey() instead

  void _addPulseIfFamily(String prayerDisplayName) {
    try {
      final familyService = sl<FamilyService>();
      final family = familyService.currentFamily.value;
      final user = _authService.currentUser.value;
      if (family == null || user == null) return;
      familyService.addPulseEvent(
        familyId: family.id,
        type: 'prayer_logged',
        userId: user.uid,
        userName: user.displayName ?? 'me'.tr,
        prayerName: prayerDisplayName,
      );
    } catch (_) {}
  }

  Future<void> _loadStreak() async {
    final userId = _authService.userId;
    if (userId == null) return;
    currentStreak.value = await _prayerRepo.getCurrentStreak(userId);
  }

  Future<void> _scheduleNotifications() async {
    try {
      final storage = sl<StorageService>();
      final enabled =
          storage.read<bool>(StorageKeys.notificationsEnabled) ?? true;
      await _notificationService.cancelAllNotifications();
      if (!enabled) return;

      final userId = _authService.userId;
      if (userId == null) return;

      final now = DateTime.now();
      for (final prayer in todayPrayers) {
        // نتجاوز الشروق لأنها ليست صلاة مفروضة
        if (prayer.prayerType == PrayerName.sunrise) continue;

        // لا نذكّر بصلاة وقتها مضى بالكامل
        if (!prayer.dateTime.isAfter(now)) continue;

        // إذا كانت الصلاة مسجّلة اليوم لا نرسل لا أذان ولا Reminder
        final alreadyLogged = await _prayerRepo.hasLoggedPrayerToday(
          userId,
          prayer.prayerType ?? PrayerName.fajr,
        );
        if (alreadyLogged) continue;

        final prayerType = prayer.prayerType ?? PrayerName.fajr;
        final baseId = _notificationIdForPrayer(prayerType);

        final adhanOn = _isAdhanEnabledForPrayer(storage, prayerType);
        final reminderOn = _isReminderEnabledForPrayer(storage, prayerType);

        if (adhanOn) {
          final prayerKey = prayerType.name;
          await _notificationService.schedulePrayerNotificationWithActions(
            id: baseId,
            prayerName: prayer.name,
            prayerKey: prayerKey,
            prayerTime: prayer.dateTime,
          );
        }
        if (reminderOn) {
          final prayerKey = prayerType.name;
          await _notificationService.schedulePrayerReminderWithActions(
            id: baseId + 100,
            prayerName: prayer.name,
            prayerKey: prayerKey,
            prayerTime: prayer.dateTime,
          );
        }
      }

      // Schedule the daily review notification (same delay as reminder)
      final ishaPrayer = todayPrayers
          .where((p) => p.prayerType == PrayerName.isha)
          .firstOrNull;
      if (ishaPrayer != null) {
        final reviewTime = ishaPrayer.dateTime.add(
          Duration(minutes: ApiConstants.prayerReminderDelayMinutes),
        );
        if (reviewTime.isAfter(now)) {
          await _notificationService.scheduleNotification(
            id: 999, // Fixed ID for daily review
            title: 'daily_review_title'.tr,
            body: 'daily_review_notification'.tr,
            scheduledTime: reviewTime,
            payload: 'daily_review',
          );
        }
      }
    } catch (_) {
      AppFeedback.showError('error'.tr, 'notification_schedule_error'.tr);
    }
  }

  bool _isAdhanEnabledForPrayer(StorageService storage, PrayerName prayer) {
    final adhanMaster =
        storage.read<bool>(StorageKeys.adhanNotificationsEnabled) ?? true;
    if (!adhanMaster) return false;
    final key = switch (prayer) {
      PrayerName.fajr => StorageKeys.fajrNotification,
      PrayerName.dhuhr => StorageKeys.dhuhrNotification,
      PrayerName.asr => StorageKeys.asrNotification,
      PrayerName.maghrib => StorageKeys.maghribNotification,
      PrayerName.isha => StorageKeys.ishaNotification,
      _ => StorageKeys.fajrNotification,
    };
    return storage.read<bool>(key) ?? true;
  }

  bool _isReminderEnabledForPrayer(StorageService storage, PrayerName prayer) {
    return storage.read<bool>(StorageKeys.reminderNotification) ?? true;
  }

  int _notificationIdForPrayer(PrayerName prayer) {
    switch (prayer) {
      case PrayerName.fajr:
        return 1;
      case PrayerName.dhuhr:
        return 2;
      case PrayerName.asr:
        return 3;
      case PrayerName.maghrib:
        return 4;
      case PrayerName.isha:
        return 5;
      case PrayerName.sunrise:
        return 6;
    }
  }

  void _listenForEncouragements() {
    final userId = _authService.userId;
    if (userId == null) return;
    _notificationsSubscription?.cancel();
    _notificationsSubscription = _userRepo
        .getUnreadUserNotificationsStream(userId)
        .listen((snapshot) {
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
        });
  }

  void _updateCurrentAndNextPrayer() {
    final now = DateTime.now();
    PrayerTimeModel? next;
    PrayerTimeModel? current;
    for (var prayer in todayPrayers) {
      if (prayer.dateTime.isAfter(now)) {
        next = prayer;
        break;
      }
      // Skip Shuruq (Sunrise) as it's not an obligatory prayer to be performed
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
      const Duration(seconds: 2),
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

  /// Log a prayer. Uses [PrayerRepository]; duplicate check via todayLogs + optional repo check.
  Future<void> logPrayer(PrayerTimeModel prayer) async {
    final userId = _authService.userId;
    if (userId == null) return;
    try {
      final isLogged = PrayerNames.isPrayerLogged(
        todayLogs,
        prayer.name,
        prayer.prayerType,
      );
      if (isLogged) {
        AppFeedback.showSnackbar('alert'.tr, 'already_logged_snackbar'.tr);
        return;
      }
      final log = PrayerLogModel.create(
        oderId: '',
        prayer: PrayerNames.fromDisplayName(prayer.name),
        adhanTime: prayer.dateTime,
      );
      final synced = await _prayerRepo.addPrayerLog(userId: userId, log: log);
      _addPulseIfFamily(prayer.name);
      final prayerType = prayer.prayerType ?? PrayerName.fajr;
      final baseId = _notificationIdForPrayer(prayerType);
      await _notificationService.cancelNotification(baseId);
      await _notificationService.cancelNotification(baseId + 100);
      _qadaService.resetSnoozeCount(prayerType);
      _qadaService.onPrayerLogged();
      _liveContextService.onPrayerLogged();
      if (synced) {
        await sl<FirestoreService>().addAnalyticsEvent(
          userId: userId,
          event: 'prayer_logged',
          data: {
            'prayer': PrayerNames.fromDisplayName(prayer.name).name,
            'adhanTime': prayer.dateTime.toIso8601String(),
          },
        );
      }
      if (todayLogs.length + 1 >= 5) {
        currentStreak.value = await _prayerRepo.updateStreak(userId);
        _celebrateAllPrayersDone();
      }
      if (synced) {
        AppFeedback.showSuccess('success_done'.tr, 'prayer_accepted'.tr);
      } else {
        AppFeedback.showSuccess('success_done'.tr, 'saved_will_sync_later'.tr);
      }
    } catch (e) {
      AppFeedback.showError(
        'error'.tr,
        'error_log_prayer'.trParams({'error': e.toString()}),
      );
    }
  }

  /// Log a past prayer (e.g. user forgot to tap notification).
  /// Uses adhan time as prayedAt to mark it as retroactive.
  Future<void> logPastPrayer(PrayerTimeModel prayer) async {
    final userId = _authService.userId;
    if (userId == null) return;
    try {
      final isLogged = PrayerNames.isPrayerLogged(
        todayLogs,
        prayer.name,
        prayer.prayerType,
      );
      if (isLogged) {
        AppFeedback.showSnackbar(
          'already_logged'.tr,
          'prayer_already_logged'.tr,
        );
        return;
      }
      final log = PrayerLogModel.create(
        oderId: userId,
        prayer: PrayerNames.fromDisplayName(prayer.name),
        adhanTime: prayer.dateTime,
      );
      final synced = await _prayerRepo.addPrayerLog(userId: userId, log: log);
      _addPulseIfFamily(prayer.name);

      // Cancel any pending notification for this prayer
      final prayerType = prayer.prayerType ?? PrayerName.fajr;
      final baseId = _notificationIdForPrayer(prayerType);
      await _notificationService.cancelNotification(baseId);
      await _notificationService.cancelNotification(baseId + 100);
      _qadaService.resetSnoozeCount(prayerType);
      _qadaService.onPrayerLogged();
      _liveContextService.onPrayerLogged();

      if (todayLogs.length + 1 >= 5) {
        currentStreak.value = await _prayerRepo.updateStreak(userId);
        _celebrateAllPrayersDone();
      }
      if (synced) {
        AppFeedback.showSuccess(
          'prayer_logged_success'.tr,
          'prayer_accepted'.tr,
        );
      } else {
        AppFeedback.showSuccess(
          'prayer_logged_success'.tr,
          'saved_will_sync_later'.tr,
        );
      }
    } catch (e) {
      AppFeedback.showError('error'.tr, 'prayer_log_failed'.tr);
    }
  }

  /// Batch-log all unlogged past prayers in one tap.
  Future<void> logAllUnloggedPrayers() async {
    final userId = _authService.userId;
    if (userId == null) return;
    final now = DateTime.now();
    int logged = 0;
    bool anyQueued = false;
    for (final prayer in todayPrayers) {
      if (prayer.prayerType == PrayerName.sunrise) continue;
      if (prayer.dateTime.isAfter(now)) continue; // Skip future prayers
      final isLogged = PrayerNames.isPrayerLogged(
        todayLogs,
        prayer.name,
        prayer.prayerType,
      );
      if (isLogged) continue;
      try {
        final log = PrayerLogModel.create(
          oderId: userId,
          prayer: PrayerNames.fromDisplayName(prayer.name),
          adhanTime: prayer.dateTime,
        );
        final synced = await _prayerRepo.addPrayerLog(userId: userId, log: log);
        if (!synced) anyQueued = true;
        _addPulseIfFamily(prayer.name);
        logged++;
      } catch (_) {}
    }
    if (logged > 0) {
      _liveContextService.onPrayerLogged();
      if (todayLogs.length + logged >= 5) {
        currentStreak.value = await _prayerRepo.updateStreak(userId);
      }
      final message = anyQueued
          ? 'saved_will_sync_later'.tr
          : '$logged ${'prayers_logged_count'.tr}';
      AppFeedback.showSuccess('prayer_logged_success'.tr, message);
    }
  }

  Future<void> refreshDashboard() async {
    final userId = _authService.userId;
    if (userId == null) return;
    await _locationService.getCurrentLocation();
    await _loadPrayerTimes();
    await _loadStreak();
  }

  // ============================================================
  // MIDNIGHT ROLLOVER & CELEBRATION
  // ============================================================

  /// Schedule a timer that fires at midnight to handle day rollover.
  void _scheduleMidnightRollover() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 0, 0, 5);
    final delay = tomorrow.difference(now);
    _midnightTimer = Timer(delay, _handleMidnightRollover);
  }

  /// Called when day changes: reload everything, check yesterday's qada.
  void _handleMidnightRollover() {
    _qadaService.resetAllSnoozeCounts();
    _loadPrayerTimes();
    _loadStreak();
    _loadHeatmapData();
    _qadaService.checkForUnloggedPrayers();
    // Schedule next midnight rollover
    _scheduleMidnightRollover();
  }

  /// Celebrate when all 5 obligatory prayers are logged today.
  void _celebrateAllPrayersDone() {
    AppFeedback.showSuccess('all_prayers_complete'.tr, 'god_accept_prayers'.tr);
    // Notify family if applicable
    _addPulseIfFamily('all_prayers_complete'.tr);
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
