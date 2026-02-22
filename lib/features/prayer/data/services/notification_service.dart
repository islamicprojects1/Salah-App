import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/api_constants.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/features/auth/data/services/auth_service.dart';
import 'package:salah/features/prayer/data/models/prayer_log_model.dart';
import 'package:salah/features/prayer/data/repositories/prayer_repository.dart';
import 'package:salah/features/prayer/data/services/firestore_service.dart';
import 'package:salah/features/prayer/data/services/live_context_service.dart';
import 'package:salah/features/prayer/data/services/prayer_time_service.dart';
import 'package:salah/features/prayer/data/services/qada_detection_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:salah/core/routes/app_routes.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import 'package:salah/core/services/storage_service.dart';
import 'package:salah/core/constants/storage_keys.dart';
import 'package:salah/core/feedback/app_feedback.dart';
import 'package:salah/core/helpers/prayer_names.dart';
import 'package:salah/core/di/injection_container.dart';
import 'package:salah/core/error/app_logger.dart';

/// Service for managing local notifications.
class NotificationService extends GetxService {
  // ============================================================
  // PRIVATE
  // ============================================================

  late final FlutterLocalNotificationsPlugin _notifications;
  late final StorageService _storage;

  bool _isInitialized = false;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  Future<NotificationService> init() async {
    if (_isInitialized) return this;
    _isInitialized = true;
    _notifications = FlutterLocalNotificationsPlugin();
    _storage = sl<StorageService>();

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _notifications.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _createNotificationChannels();

    return this;
  }

  Future<bool> requestPermissions() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  Future<void> _createNotificationChannels() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin == null) return;

    // Adhan channel (legacy – full adhan)
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'prayer_adhan',
        'Prayer (Adhan)',
        description: 'Prayer notifications with Adhan sound',
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound('athan'),
        playSound: true,
      ),
    );

    // Takbeer channel (short, at prayer time)
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        ApiConstants.prayerTakbeerChannelId,
        'Prayer (Takbeer)',
        description: 'Short takbeer at prayer time',
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound('takbir_1'),
        playSound: true,
      ),
    );

    // Approaching channels (prayer-specific sounds)
    const approachSounds = [
      'fagrsoon',
      'zohrsoon',
      'asrsoon',
      'maghribsoon',
      'eshaasoon',
    ];
    const prayerKeys = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
    for (var i = 0; i < approachSounds.length; i++) {
      await androidPlugin.createNotificationChannel(
        AndroidNotificationChannel(
          '${ApiConstants.prayerApproachChannelPrefix}${prayerKeys[i]}',
          'Approaching ${prayerKeys[i]}',
          description: 'Approaching prayer alert',
          importance: Importance.high,
          sound: RawResourceAndroidNotificationSound(approachSounds[i]),
          playSound: true,
        ),
      );
    }

    // Vibrate / silent channels
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'prayer_vibrate',
        'Prayer (Vibrate)',
        description: 'Prayer notifications with vibration only',
        importance: Importance.high,
        enableVibration: true,
        playSound: false,
      ),
    );

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'prayer_silent',
        'Prayer (Silent)',
        description: 'Prayer notifications without sound or vibration',
        importance: Importance.high,
        enableVibration: false,
        playSound: false,
      ),
    );

    // Social & Reminders
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        ApiConstants.socialNotificationChannelId,
        'Social Notifications',
        description: 'Notifications from family and groups',
        importance: Importance.defaultImportance,
      ),
    );

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        ApiConstants.reminderNotificationChannelId,
        'Prayer Reminders',
        description: 'Reminders to log your prayers',
        importance: Importance.high,
      ),
    );

    // Family pulse
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'family_channel',
        'Family Pulse',
        description: 'Notifications when family members pray or achieve goals',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );
  }

  // ============================================================
  // NOTIFICATION TAP HANDLER
  // ============================================================

  void _onNotificationTapped(NotificationResponse response) {
    final actionId = response.actionId;
    final payload = response.payload;

    if (actionId != null && payload != null && payload.contains('|')) {
      final parts = payload.split('|');
      if (parts.length >= 4) {
        final type = parts[0];
        final idStr = parts[1];
        final prayerKey = parts[2];
        final adhanIso = parts[3];
        final notifId = int.tryParse(idStr);

        if ((actionId == 'prayed' || actionId == 'confirmPrayed') &&
            notifId != null) {
          _handlePrayedAction(type, notifId, prayerKey, adhanIso);
          return;
        }
        if (actionId == 'snooze' && notifId != null) {
          _handleSnoozeAction(prayerKey, adhanIso, type, notifId);
          return;
        }
        if (actionId == 'markAsQada' && notifId != null) {
          _handleMarkAsQadaAction(prayerKey, adhanIso, notifId);
          return;
        }
        if (actionId == 'willPrayNow') {
          Get.toNamed(AppRoutes.dashboard);
          return;
        }
      }
    }

    try {
      Get.toNamed(AppRoutes.dashboard);
      final auth = sl<AuthService>();
      final userId = auth.currentUser.value?.uid;
      if (userId != null) {
        sl<FirestoreService>().addAnalyticsEvent(
          userId: userId,
          event: 'notification_tapped',
          data: {'payload': response.payload},
        );
      }
    } catch (e) {
      AppLogger.debug('Notification tapped / analytics failed', e);
    }
  }

  Future<void> _handlePrayedAction(
    String type,
    int notifId,
    String prayerKey,
    String adhanIso,
  ) async {
    try {
      final userId = sl<AuthService>().userId;
      if (userId == null) {
        final baseId = type == 'adhan' ? notifId : notifId - 100;
        _savePendingPrayerLog(prayerKey, adhanIso, baseId);
        Get.toNamed(AppRoutes.dashboard);
        return;
      }
      final prayer = PrayerNames.fromKey(prayerKey);
      final adhanTime = DateTime.tryParse(adhanIso);
      if (adhanTime == null) return;

      final log = PrayerLogModel.create(
        oderId: userId,
        prayer: prayer,
        adhanTime: adhanTime,
      );
      final synced = await sl<PrayerRepository>().addPrayerLog(
        userId: userId,
        log: log,
      );

      final baseId = type == 'adhan' ? notifId : notifId - 100;
      // FIX: cancelNotification takes a positional int, but here we call internal cancel
      await _notifications.cancel(id: baseId);
      await _notifications.cancel(id: baseId + 100);

      if (sl.isRegistered<QadaDetectionService>()) {
        sl<QadaDetectionService>().resetSnoozeCount(prayer);
      }
      try {
        sl<LiveContextService>().onPrayerLogged();
      } catch (e) {
        AppLogger.debug('LiveContextService.onPrayerLogged failed', e);
      }

      if (synced) {
        AppFeedback.showSuccess('done'.tr, 'prayer_logged_toast'.tr);
      } else {
        AppFeedback.showSuccess('done'.tr, 'saved_will_sync_later'.tr);
      }
      Get.toNamed(AppRoutes.dashboard);
    } catch (e) {
      AppLogger.debug('Handle prayed action failed (saving pending)', e);
      final baseId = type == 'adhan' ? notifId : notifId - 100;
      _savePendingPrayerLog(prayerKey, adhanIso, baseId);
      Get.toNamed(AppRoutes.dashboard);
    }
  }

  void _savePendingPrayerLog(String prayerKey, String adhanIso, int baseId) {
    try {
      sl<StorageService>().write(
        StorageKeys.pendingPrayerLog,
        jsonEncode({
          'prayerKey': prayerKey,
          'adhanTime': adhanIso,
          'baseId': baseId,
        }),
      );
    } catch (e) {
      AppLogger.debug('Save pending prayer log failed', e);
    }
  }

  void _handleSnoozeAction(
    String prayerKey,
    String adhanIso,
    String type,
    int notifId,
  ) {
    final baseId = type == 'adhan' ? notifId : notifId - 100;
    final reminderId = baseId + 100;
    final prayer = PrayerNames.fromKey(prayerKey);
    final prayerName = PrayerNames.displayName(prayer);

    Duration? delay;
    if (sl.isRegistered<QadaDetectionService>()) {
      delay = sl<QadaDetectionService>().incrementSnoozeAndGetDelay(prayer);
    } else {
      delay = const Duration(minutes: 10);
    }

    if (delay == null) return;

    final isFinal = sl.isRegistered<QadaDetectionService>()
        ? sl<QadaDetectionService>().isNextReminderFinal(prayer)
        : false;

    final snoozeTime = DateTime.now().add(delay);
    scheduleNotificationWithActions(
      id: reminderId,
      title: 'notification_prayer_title'.trParams({'prayer': prayerName}),
      body: 'notification_prayer_body'.tr,
      scheduledTime: snoozeTime,
      payload: 'reminder|$reminderId|$prayerKey|$adhanIso',
      channelId: ApiConstants.reminderNotificationChannelId,
      finalReminder: isFinal,
    );
    AppFeedback.showSuccess(
      'done'.tr,
      'snooze_toast_minutes'.trParams({'minutes': '${delay.inMinutes}'}),
    );
  }

  void _handleMarkAsQadaAction(String prayerKey, String adhanIso, int notifId) {
    final baseId = notifId - 100;
    cancelNotification(baseId);
    cancelNotification(notifId);
    try {
      final prayer = PrayerNames.fromKey(prayerKey);
      if (sl.isRegistered<QadaDetectionService>()) {
        sl<QadaDetectionService>().resetSnoozeCount(prayer);
      }
      _savePendingMissedPrayer(prayerKey, adhanIso);
      AppFeedback.showSuccess('done'.tr, 'qada_saved_toast'.tr);
    } catch (e) {
      AppLogger.debug('Handle mark as qada failed', e);
    }
    Get.toNamed(AppRoutes.dashboard);
  }

  void _savePendingMissedPrayer(String prayerKey, String adhanIso) {
    try {
      sl<StorageService>().write(
        StorageKeys.pendingMissedPrayer,
        jsonEncode({'prayerKey': prayerKey, 'adhanTime': adhanIso}),
      );
    } catch (e) {
      AppLogger.debug('Save pending missed prayer failed', e);
    }
  }

  // ============================================================
  // NOTIFICATION DETAILS
  // ============================================================

  NotificationDetails _getNotificationDetails(String channelId) {
    final soundMode = _storage.getNotificationSoundMode();

    String finalChannelId = channelId;
    if (channelId == ApiConstants.prayerNotificationChannelId) {
      finalChannelId = _getPrayerChannelId(soundMode);
    }

    final androidDetails = AndroidNotificationDetails(
      finalChannelId,
      finalChannelId.contains('prayer')
          ? 'Prayer Notifications'
          : 'Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: soundMode != NotificationSoundMode.silent,
    );

    return NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  /// FIX: For adhan mode, respect the takbeer-at-prayer toggle; for other
  /// modes return the appropriate channel directly.
  String _getPrayerChannelId(NotificationSoundMode mode) {
    switch (mode) {
      case NotificationSoundMode.adhan:
        return _storage.takbeerAtPrayerEnabled
            ? ApiConstants.prayerTakbeerChannelId
            : 'prayer_adhan';
      case NotificationSoundMode.vibrate:
        return 'prayer_vibrate';
      case NotificationSoundMode.silent:
        return 'prayer_silent';
    }
  }

  String _getApproachChannelId(PrayerName prayer) =>
      '${ApiConstants.prayerApproachChannelPrefix}${prayer.name}';

  String _getNotifKeyForPrayer(PrayerName prayer) {
    switch (prayer) {
      case PrayerName.fajr:
        return StorageKeys.fajrNotification;
      case PrayerName.dhuhr:
        return StorageKeys.dhuhrNotification;
      case PrayerName.asr:
        return StorageKeys.asrNotification;
      case PrayerName.maghrib:
        return StorageKeys.maghribNotification;
      case PrayerName.isha:
        return StorageKeys.ishaNotification;
      default:
        return '';
    }
  }

  int _prayerToNotificationId(PrayerName prayer) {
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
      default:
        return 0;
    }
  }

  NotificationDetails _getNotificationDetailsWithActions(
    String channelId, {
    bool adhanOnly = false,
    bool finalReminder = false,
  }) {
    final soundMode = _storage.getNotificationSoundMode();
    String finalChannelId = channelId;
    if (channelId == ApiConstants.prayerNotificationChannelId) {
      finalChannelId = _getPrayerChannelId(soundMode);
    }

    final List<AndroidNotificationAction> actions;
    if (adhanOnly) {
      actions = [
        const AndroidNotificationAction(
          'prayed',
          '✅ صليت',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ];
    } else if (finalReminder) {
      actions = [
        const AndroidNotificationAction(
          'confirmPrayed',
          '✅ صليت',
          showsUserInterface: false,
          cancelNotification: true,
        ),
        const AndroidNotificationAction(
          'markAsQada',
          '📿 سأقضيها',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ];
    } else {
      actions = [
        const AndroidNotificationAction(
          'confirmPrayed',
          '✅ صليت',
          showsUserInterface: false,
          cancelNotification: true,
        ),
        const AndroidNotificationAction(
          'snooze',
          '⏰ بعد شوي',
          showsUserInterface: false,
          cancelNotification: true,
        ),
        const AndroidNotificationAction(
          'willPrayNow',
          '🕌 سأصلي الآن',
          showsUserInterface: false,
          cancelNotification: false,
        ),
      ];
    }

    final androidDetails = AndroidNotificationDetails(
      finalChannelId,
      'Prayer Notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: soundMode != NotificationSoundMode.silent,
      enableVibration: soundMode != NotificationSoundMode.silent,
      actions: actions,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: soundMode != NotificationSoundMode.silent,
    );

    return NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  // ============================================================
  // SCHEDULE / SHOW
  // ============================================================

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? channelId,
    String? payload,
  }) async {
    await _notifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _getNotificationDetails(
        channelId ?? ApiConstants.prayerNotificationChannelId,
      ),
      payload: payload,
    );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? channelId,
    String? payload,
  }) async {
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);
    await _notifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzTime,
      notificationDetails: _getNotificationDetails(
        channelId ?? ApiConstants.prayerNotificationChannelId,
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  Future<void> scheduleNotificationWithActions({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String payload,
    required String channelId,
    bool adhanOnly = false,
    bool finalReminder = false,
  }) async {
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);
    await _notifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzTime,
      notificationDetails: _getNotificationDetailsWithActions(
        channelId,
        adhanOnly: adhanOnly,
        finalReminder: finalReminder,
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  Future<void> schedulePrayerNotificationWithActions({
    required int id,
    required String prayerName,
    required String prayerKey,
    required DateTime prayerTime,
  }) async {
    final soundMode = _getSoundMode();
    final channelId = _getPrayerChannelId(soundMode);
    await scheduleNotificationWithActions(
      id: id,
      title: '${'prayer_time'.tr} - $prayerName',
      body: '${'prayer_time_body'.tr} $prayerName',
      scheduledTime: prayerTime,
      payload: 'adhan|$id|$prayerKey|${prayerTime.toIso8601String()}',
      channelId: channelId,
      adhanOnly: true,
    );
  }

  Future<void> schedulePrayerReminderWithActions({
    required int id,
    required String prayerName,
    required String prayerKey,
    required DateTime prayerTime,
    bool finalReminder = false,
  }) async {
    final reminderTime = prayerTime.add(
      Duration(minutes: ApiConstants.prayerReminderDelayMinutes),
    );
    await scheduleNotificationWithActions(
      id: id,
      title: '${'prayer_reminder'.tr} - $prayerName',
      body: 'prayer_reminder_30'.trParams({'prayer': prayerName}),
      scheduledTime: reminderTime,
      payload: 'reminder|$id|$prayerKey|${prayerTime.toIso8601String()}',
      channelId: ApiConstants.reminderNotificationChannelId,
      finalReminder: finalReminder,
    );
  }

  Future<void> scheduleApproachingNotification({
    required int id,
    required String prayerName,
    required String prayerKey,
    required PrayerName prayer,
    required DateTime prayerTime,
    required int minutesBefore,
  }) async {
    final approachTime = prayerTime.subtract(Duration(minutes: minutesBefore));
    final payload =
        'approaching|$id|$prayerKey|${prayerTime.toIso8601String()}';
    final channelId = _getApproachChannelId(prayer);
    await scheduleNotification(
      id: id,
      title: 'approaching_prayer_title'.trParams({'prayer': prayerName}),
      body: 'approaching_prayer_body'.trParams({'minutes': '$minutesBefore'}),
      scheduledTime: approachTime,
      payload: payload,
      channelId: channelId,
    );
  }

  // ============================================================
  // SOCIAL NOTIFICATIONS
  // ============================================================

  Future<void> showEncouragementNotification({
    required String senderName,
    required String message,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: senderName,
      body: message,
      channelId: ApiConstants.socialNotificationChannelId,
    );
  }

  Future<void> showReminderNotification({
    required String senderName,
    required String prayerName,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: 'remind'.trParams({'name': senderName}),
      body: 'remind_prayer'.trParams({'prayer': prayerName}),
      channelId: ApiConstants.socialNotificationChannelId,
    );
  }

  // ============================================================
  // MANAGEMENT
  // ============================================================

  /// FIX: original code called `_notifications.cancel(id: notificationId)`
  /// with a named param, but the API signature is `cancel(int id)` positional.
  Future<void> cancelNotification(int notificationId) async {
    await _notifications.cancel(id: notificationId);
  }

  Future<void> cancelPrayerReminder(PrayerName prayer) async {
    final baseId = _prayerToNotificationId(prayer);
    await cancelNotification(baseId);
    await cancelNotification(baseId + 100);
  }

  Future<void> rescheduleAllForToday() async {
    try {
      await cancelAllNotifications();

      if (!sl.isRegistered<PrayerTimeService>()) return;
      final prayerTimeService = sl<PrayerTimeService>();
      final prayers = prayerTimeService.getTodayPrayers();
      if (prayers.isEmpty) return;

      final loggedPrayers = <PrayerName>{};
      if (sl.isRegistered<QadaDetectionService>()) {
        final qadaService = sl<QadaDetectionService>();
        await qadaService.checkForUnloggedPrayers();
        final unloggedNames = qadaService.todayUnlogged
            .map((u) => u.prayer)
            .toSet();
        for (final p in PrayerName.values) {
          if (p == PrayerName.sunrise) continue;
          if (!unloggedNames.contains(p)) loggedPrayers.add(p);
        }
      }

      final soundMode = _getSoundMode();
      final now = DateTime.now();

      final notificationsEnabled =
          _storage.read<bool>(StorageKeys.notificationsEnabled) ?? true;
      if (!notificationsEnabled) return;

      final adhanMasterEnabled =
          _storage.read<bool>(StorageKeys.adhanNotificationsEnabled) ?? true;
      final reminderEnabled =
          _storage.read<bool>(StorageKeys.reminderNotification) ?? true;

      for (final prayer in prayers) {
        final pType = prayer.prayerType;
        if (pType == null || pType == PrayerName.sunrise) continue;
        if (loggedPrayers.contains(pType)) continue;
        if (prayer.dateTime.isBefore(now)) continue;

        final baseId = _prayerToNotificationId(pType);
        final channelId = _getPrayerChannelId(soundMode);
        final prayerKey = pType.name;

        final individualPrayerEnabled =
            _storage.read<bool>(_getNotifKeyForPrayer(pType)) ?? true;

        final approachingEnabled = _storage.approachingAlertEnabled;
        if (approachingEnabled && individualPrayerEnabled) {
          final approachId =
              ApiConstants.approachingNotificationIdBase + baseId - 1;
          final minutesBefore = pType == PrayerName.fajr
              ? _storage.approachingFajrMinutes
              : _storage.approachingAlertMinutes;
          final approachTime = prayer.dateTime.subtract(
            Duration(minutes: minutesBefore),
          );
          if (approachTime.isAfter(now)) {
            await scheduleApproachingNotification(
              id: approachId,
              prayerName: prayer.name,
              prayerKey: prayerKey,
              prayer: pType,
              prayerTime: prayer.dateTime,
              minutesBefore: minutesBefore,
            );
          }
        }

        if (adhanMasterEnabled && individualPrayerEnabled) {
          await scheduleNotificationWithActions(
            id: baseId,
            title: '${'prayer_time'.tr} - ${prayer.name}',
            body: '${'prayer_time_body'.tr} ${prayer.name}',
            scheduledTime: prayer.dateTime,
            payload:
                'adhan|$baseId|$prayerKey|${prayer.dateTime.toIso8601String()}',
            channelId: channelId,
            adhanOnly: true,
          );
        }

        if (reminderEnabled) {
          final reminderTime = prayer.dateTime.add(
            Duration(minutes: ApiConstants.prayerReminderDelayMinutes),
          );
          if (reminderTime.isAfter(now)) {
            await scheduleNotificationWithActions(
              id: baseId + 100,
              title: '${'prayer_reminder'.tr} - ${prayer.name}',
              body: 'prayer_reminder_30'.trParams({'prayer': prayer.name}),
              scheduledTime: reminderTime,
              payload:
                  'reminder|${baseId + 100}|$prayerKey|${prayer.dateTime.toIso8601String()}',
              channelId: ApiConstants.reminderNotificationChannelId,
            );
          }
        }
      }
    } catch (e) {
      AppLogger.debug('Notification reschedule failed (non-critical)', e);
    }
  }

  NotificationSoundMode _getSoundMode() {
    if (sl.isRegistered<StorageService>()) {
      final mode = _storage.read<String>(StorageKeys.notificationSoundMode);
      if (mode != null) {
        return NotificationSoundMode.values.firstWhere(
          (e) => e.name == mode,
          orElse: () => NotificationSoundMode.adhan,
        );
      }
    }
    return NotificationSoundMode.adhan;
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return _notifications.pendingNotificationRequests();
  }
}
