import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/helpers/prayer_names.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/storage_keys.dart';
import 'package:salah/core/feedback/app_feedback.dart';
import 'package:salah/core/services/auth_service.dart';
import 'package:salah/core/services/storage_service.dart';
import 'package:salah/core/services/location_service.dart';
import 'package:salah/core/services/notification_service.dart';
import 'package:salah/core/services/prayer_time_service.dart';
import 'package:salah/core/services/live_context_service.dart';
import 'package:salah/core/services/firestore_service.dart';
import 'package:salah/data/models/prayer_log_model.dart';
import 'package:salah/data/models/prayer_time_model.dart';
import 'package:salah/data/repositories/prayer_repository.dart';
import 'package:salah/data/repositories/user_repository.dart';
import 'package:salah/core/services/family_service.dart';

/// Dashboard controller – UI logic only. All data comes from [PrayerRepository],
/// [UserRepository], [PrayerTimeService], [LocationService], [NotificationService].
/// Reactive: observables are updated from repository streams/calls; UI uses Obx.
class DashboardController extends GetxController {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  final PrayerTimeService _prayerService;
  final LocationService _locationService;
  final AuthService _authService;
  final UserRepository _userRepo;
  final PrayerRepository _prayerRepo;
  final NotificationService _notificationService;
  final LiveContextService _liveContextService;

  DashboardController({
    required PrayerTimeService prayerService,
    required LocationService locationService,
    required AuthService authService,
    required UserRepository userRepo,
    required PrayerRepository prayerRepo,
    required NotificationService notificationService,
    required LiveContextService liveContextService,
  }) : _prayerService = prayerService,
       _locationService = locationService,
       _authService = authService,
       _userRepo = userRepo,
       _prayerRepo = prayerRepo,
       _notificationService = notificationService,
       _liveContextService = liveContextService;

  final isLoading = true.obs;
  final currentPrayer = Rxn<PrayerTimeModel>();
  final nextPrayer = Rxn<PrayerTimeModel>();
  final timeUntilNextPrayer = ''.obs;
  final todayPrayers = <PrayerTimeModel>[].obs;
  final todayLogs = <PrayerLogModel>[].obs;
  final currentCity = ''.obs;
  final currentStreak = 0.obs;
  final currentTabIndex = 0.obs;
  final dailyPrayerCounts = <DateTime, int>{}.obs;

  void changeTab(int index) => currentTabIndex.value = index;

  void changeTabIndex(int index) => currentTabIndex.value = index;

  Timer? _timer;
  StreamSubscription<List<PrayerLogModel>>? _logsSubscription;
  StreamSubscription<dynamic>? _notificationsSubscription;

  @override
  void onInit() {
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
  }

  void _syncLocationLabel() {
    currentCity.value = _locationService.locationDisplayLabel;
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

      // 3. Background Data (Non-blocking)
      _loadPrayerLogs();
      _loadStreak();
      _processPendingPrayerLogFromNotification();
      _listenForEncouragements();
      _startTimer();

      // 4. Heavy/External operations (Deferred)
      // Load heatmap data
      _loadHeatmapData();

      // Request permissions after a delay to let UI settle
      Future.delayed(const Duration(seconds: 2), () {
        _notificationService.requestPermissions();
      });
    } catch (_) {
      AppFeedback.showError('خطأ', 'فشل تحميل لوحة التحكم');
      isLoading.value = false;
    }
  }

  Future<void> _loadPrayerTimes() async {
    final prayers = _prayerService.getTodayPrayers();
    todayPrayers.assignAll(prayers);
    _updateCurrentAndNextPrayer();
    _scheduleNotifications();
  }

  void _loadPrayerLogs() {
    final userId = _authService.userId;
    if (userId == null) return;
    _logsSubscription?.cancel();
    _logsSubscription = _prayerRepo.getTodayPrayerLogs(userId).listen((logs) {
      todayLogs.assignAll(logs);
      _updateCurrentAndNextPrayer();
    });
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
    final storage = Get.find<StorageService>();
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
      await _prayerRepo.addPrayerLog(userId: userId, log: log);
      _addPulseIfFamily(displayName);
      if (baseId != null) {
        await _notificationService.cancelNotification(baseId);
        await _notificationService.cancelNotification(baseId + 100);
      }
      await storage.remove(StorageKeys.pendingPrayerLog);
      _liveContextService.onPrayerLogged();
      AppFeedback.showSuccess('تم', 'تم تسجيل صلاة $displayName من الإشعار');
    } catch (_) {}
  }

  // _prayerKeyToName removed – use PrayerNames.fromKey() instead

  void _addPulseIfFamily(String prayerDisplayName) {
    try {
      if (!Get.isRegistered<FamilyService>()) return;
      final familyService = Get.find<FamilyService>();
      final family = familyService.currentFamily.value;
      final user = _authService.currentUser.value;
      if (family == null || user == null) return;
      familyService.addPulseEvent(
        familyId: family.id,
        type: 'prayer_logged',
        userId: user.uid,
        userName: user.displayName ?? 'أنا',
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
      final storage = Get.find<StorageService>();
      final enabled =
          storage.read<bool>(StorageKeys.notificationsEnabled) ?? true;
      await _notificationService.cancelAllNotifications();
      if (!enabled) return;

      final userId = _authService.userId;
      if (userId == null) return;

      // Per-type toggles
      final adhanOn = storage.read<bool>(StorageKeys.fajrNotification) ?? true;
      final reminderOn =
          storage.read<bool>(StorageKeys.reminderNotification) ?? true;

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

        final baseId = _notificationIdForPrayer(
          prayer.prayerType ?? PrayerName.fajr,
        );

        if (adhanOn) {
          final prayerKey = (prayer.prayerType ?? PrayerName.fajr).name;
          await _notificationService.schedulePrayerNotificationWithActions(
            id: baseId,
            prayerName: prayer.name,
            prayerKey: prayerKey,
            prayerTime: prayer.dateTime,
          );
        }
        if (reminderOn) {
          final prayerKey = (prayer.prayerType ?? PrayerName.fajr).name;
          await _notificationService.schedulePrayerReminderWithActions(
            id: baseId + 100,
            prayerName: prayer.name,
            prayerKey: prayerKey,
            prayerTime: prayer.dateTime,
          );
        }
      }

      // Schedule the daily review notification (30 min after Isha)
      final ishaPrayer = todayPrayers
          .where((p) => p.prayerType == PrayerName.isha)
          .firstOrNull;
      if (ishaPrayer != null) {
        final reviewTime = ishaPrayer.dateTime.add(const Duration(minutes: 30));
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
        AppFeedback.showSnackbar('تنبيه', 'لقد قمت بتسجيل هذه الصلاة مسبقاً');
        return;
      }
      final log = PrayerLogModel.create(
        oderId: '',
        prayer: PrayerNames.fromDisplayName(prayer.name),
        adhanTime: prayer.dateTime,
      );
      await _prayerRepo.addPrayerLog(userId: userId, log: log);
      _addPulseIfFamily(prayer.name);
      final baseId = _notificationIdForPrayer(
        prayer.prayerType ?? PrayerName.fajr,
      );
      await _notificationService.cancelNotification(baseId);
      await _notificationService.cancelNotification(baseId + 100);
      await Get.find<FirestoreService>().addAnalyticsEvent(
        userId: userId,
        event: 'prayer_logged',
        data: {
          'prayer': PrayerNames.fromDisplayName(prayer.name).name,
          'adhanTime': prayer.dateTime.toIso8601String(),
        },
      );
      if (todayLogs.length + 1 >= 5) {
        currentStreak.value = await _prayerRepo.updateStreak(userId);
      }
      AppFeedback.showSuccess('تم بنجاح', 'تقبل الله طاعاتكم');
    } catch (e) {
      AppFeedback.showError('خطأ', 'فشل تسجيل الصلاة: $e');
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
      await _prayerRepo.addPrayerLog(userId: userId, log: log);
      _addPulseIfFamily(prayer.name);

      // Cancel any pending notification for this prayer
      final baseId = _notificationIdForPrayer(
        prayer.prayerType ?? PrayerName.fajr,
      );
      await _notificationService.cancelNotification(baseId);
      await _notificationService.cancelNotification(baseId + 100);

      if (todayLogs.length + 1 >= 5) {
        currentStreak.value = await _prayerRepo.updateStreak(userId);
      }
      AppFeedback.showSuccess('prayer_logged_success'.tr, 'prayer_accepted'.tr);
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
        await _prayerRepo.addPrayerLog(userId: userId, log: log);
        _addPulseIfFamily(prayer.name);
        logged++;
      } catch (_) {}
    }
    if (logged > 0) {
      if (todayLogs.length + logged >= 5) {
        currentStreak.value = await _prayerRepo.updateStreak(userId);
      }
      AppFeedback.showSuccess(
        'prayer_logged_success'.tr,
        '$logged ${'prayers_logged_count'.tr}',
      );
    }
  }

  Future<void> refreshDashboard() async {
    final userId = _authService.userId;
    if (userId == null) return;
    await _locationService.getCurrentLocation();
    await _loadPrayerTimes();
    _loadPrayerLogs();
    await _loadStreak();
  }

  @override
  void onClose() {
    _timer?.cancel();
    _logsSubscription?.cancel();
    _notificationsSubscription?.cancel();
    super.onClose();
  }
}
