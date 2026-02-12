import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:salah/core/routes/app_routes.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:salah/core/services/firestore_service.dart';
import 'package:salah/core/services/auth_service.dart';
import 'package:salah/core/services/storage_service.dart';
import 'package:salah/core/constants/storage_keys.dart';
import 'package:salah/core/helpers/prayer_names.dart';
import 'package:salah/data/models/prayer_log_model.dart';
import 'package:salah/data/repositories/prayer_repository.dart';
import 'package:salah/core/services/live_context_service.dart';
import '../constants/api_constants.dart';

/// Service for managing local notifications
class NotificationService extends GetxService {
  // ============================================================
  // PRIVATE
  // ============================================================

  late final FlutterLocalNotificationsPlugin _notifications;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  bool _isInitialized = false;

  /// Initialize the service
  Future<NotificationService> init() async {
    if (_isInitialized) return this;
    _isInitialized = true;
    _notifications = FlutterLocalNotificationsPlugin();

    // Initialize timezone
    tz_data.initializeTimeZones();

    // Android settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Initialize with settings
    await _notifications.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels (Android)
    await _createNotificationChannels();

    return this;
  }

  /// Request notification permissions
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

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      // 1. Prayer Channels (Three variants)

      // Adhan Channel
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

      // Vibrate Channel
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

      // Silent Channel
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

      // 2. Social & Reminders
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
    }
  }

  /// Handle notification tap or action – open dashboard; if action "prayed" log prayer, if "snooze" reschedule.
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

        if (actionId == 'prayed' && notifId != null) {
          _handlePrayedAction(type, notifId, prayerKey, adhanIso);
          return;
        }
        if (actionId == 'snooze' && notifId != null) {
          _handleSnoozeAction(prayerKey, adhanIso, type, notifId);
          return;
        }
      }
    }

    try {
      Get.toNamed(AppRoutes.dashboard);
      final auth = Get.find<AuthService>();
      final userId = auth.currentUser.value?.uid;
      if (userId != null) {
        Get.find<FirestoreService>().addAnalyticsEvent(
          userId: userId,
          event: 'notification_tapped',
          data: {'payload': response.payload},
        );
      }
    } catch (_) {}
  }

  void _handlePrayedAction(
    String type,
    int notifId,
    String prayerKey,
    String adhanIso,
  ) {
    try {
      final userId = Get.find<AuthService>().userId;
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
      Get.find<PrayerRepository>().addPrayerLog(userId: userId, log: log);

      final baseId = type == 'adhan' ? notifId : notifId - 100;
      cancelNotification(baseId);
      cancelNotification(baseId + 100);

      if (Get.isRegistered<LiveContextService>()) {
        Get.find<LiveContextService>().onPrayerLogged();
      }
      Get.toNamed(AppRoutes.dashboard);
    } catch (_) {
      final baseId = type == 'adhan' ? notifId : notifId - 100;
      _savePendingPrayerLog(prayerKey, adhanIso, baseId);
      Get.toNamed(AppRoutes.dashboard);
    }
  }

  void _savePendingPrayerLog(String prayerKey, String adhanIso, int baseId) {
    try {
      Get.find<StorageService>().write(
        StorageKeys.pendingPrayerLog,
        jsonEncode({
          'prayerKey': prayerKey,
          'adhanTime': adhanIso,
          'baseId': baseId,
        }),
      );
    } catch (_) {}
  }

  // _prayerKeyToName removed – use PrayerNames.fromKey() instead

  void _handleSnoozeAction(
    String prayerKey,
    String adhanIso,
    String type,
    int notifId,
  ) {
    final baseId = type == 'adhan' ? notifId : notifId - 100;
    final reminderId = baseId + 100;
    final prayerName = PrayerNames.displayName(PrayerNames.fromKey(prayerKey));
    final in10 = DateTime.now().add(const Duration(minutes: 10));
    scheduleNotificationWithActions(
      id: reminderId,
      title: 'notification_prayer_title'.trParams({'prayer': prayerName}),
      body: 'notification_prayer_body'.tr,
      scheduledTime: in10,
      payload: 'reminder|$reminderId|$prayerKey|$adhanIso',
      channelId: ApiConstants.reminderNotificationChannelId,
    );
  }

  // ============================================================
  // NOTIFICATION DETAILS
  // ============================================================

  NotificationDetails _getNotificationDetails(String channelId) {
    final storage = Get.find<StorageService>();
    final soundMode = storage.getNotificationSoundMode();

    // If it's the prayer channel, use the dynamic one
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

  String _getPrayerChannelId(NotificationSoundMode mode) {
    switch (mode) {
      case NotificationSoundMode.adhan:
        return 'prayer_adhan';
      case NotificationSoundMode.vibrate:
        return 'prayer_vibrate';
      case NotificationSoundMode.silent:
        return 'prayer_silent';
    }
  }

  /// Notification details with action buttons (صليت / لاحقاً) for Android
  NotificationDetails _getNotificationDetailsWithActions(String channelId) {
    final storage = Get.find<StorageService>();
    final soundMode = storage.getNotificationSoundMode();
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
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'prayed',
          'notification_i_prayed'.tr,
          showsUserInterface: false,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'snooze',
          'notification_later'.tr,
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    return NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  // ============================================================
  // SHOW NOTIFICATIONS
  // ============================================================

  /// Show instant notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = ApiConstants.prayerNotificationChannelId,
  }) async {
    await _notifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _getNotificationDetails(channelId),
      payload: payload,
    );
  }

  /// Schedule notification at specific time
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    String channelId = ApiConstants.prayerNotificationChannelId,
  }) async {
    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _notifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzScheduledTime,
      notificationDetails: _getNotificationDetails(channelId),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  /// Schedule notification with action buttons (صليت / لاحقاً)
  Future<void> scheduleNotificationWithActions({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String payload,
    required String channelId,
  }) async {
    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);
    await _notifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzScheduledTime,
      notificationDetails: _getNotificationDetailsWithActions(channelId),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  // ============================================================
  // PRAYER NOTIFICATIONS
  // ============================================================

  /// Schedule prayer time notification
  Future<void> schedulePrayerNotification({
    required int id,
    required String prayerName,
    required DateTime prayerTime,
  }) async {
    final key = _displayNameToKey(prayerName);
    await schedulePrayerNotificationWithActions(
      id: id,
      prayerName: prayerName,
      prayerKey: key,
      prayerTime: prayerTime,
    );
  }

  /// Schedule prayer time notification with action buttons (صليت / لاحقاً)
  Future<void> schedulePrayerNotificationWithActions({
    required int id,
    required String prayerName,
    required String prayerKey,
    required DateTime prayerTime,
  }) async {
    final payload = 'adhan|$id|$prayerKey|${prayerTime.toIso8601String()}';
    await scheduleNotificationWithActions(
      id: id,
      title: 'notification_prayer_title'.trParams({'prayer': prayerName}),
      body: 'notification_prayer_body'.tr,
      scheduledTime: prayerTime,
      payload: payload,
      channelId: ApiConstants.prayerNotificationChannelId,
    );
  }

  /// Schedule prayer reminder (30 min after adhan) with action buttons
  Future<void> schedulePrayerReminder({
    required int id,
    required String prayerName,
    required DateTime prayerTime,
  }) async {
    final key = _displayNameToKey(prayerName);
    await schedulePrayerReminderWithActions(
      id: id,
      prayerName: prayerName,
      prayerKey: key,
      prayerTime: prayerTime,
    );
  }

  /// Schedule prayer reminder with action buttons (صليت / لاحقاً)
  Future<void> schedulePrayerReminderWithActions({
    required int id,
    required String prayerName,
    required String prayerKey,
    required DateTime prayerTime,
  }) async {
    final reminderTime = prayerTime.add(
      const Duration(minutes: ApiConstants.prayerReminderDelayMinutes),
    );
    final payload = 'reminder|$id|$prayerKey|${prayerTime.toIso8601String()}';
    await scheduleNotificationWithActions(
      id: id,
      title: 'notification_prayer_title'.trParams({'prayer': prayerName}),
      body: 'notification_prayer_body'.tr,
      scheduledTime: reminderTime,
      payload: payload,
      channelId: ApiConstants.reminderNotificationChannelId,
    );
  }

  String _displayNameToKey(String name) {
    final n = name.trim().toLowerCase();
    if (n.contains('فجر') || n == 'fajr') return 'fajr';
    if (n.contains('ظهر') || n == 'dhuhr') return 'dhuhr';
    if (n.contains('عصر') || n == 'asr') return 'asr';
    if (n.contains('مغرب') || n == 'maghrib') return 'maghrib';
    if (n.contains('عشاء') || n == 'isha') return 'isha';
    return 'fajr';
  }

  // ============================================================
  // SOCIAL NOTIFICATIONS
  // ============================================================

  /// Show encouragement notification
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

  /// Show reminder from family/group
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

  /// Cancel specific notification
  Future<void> cancelNotification(int notificationId) async {
    await _notifications.cancel(id: notificationId);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}
