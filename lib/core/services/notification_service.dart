import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:salah/core/routes/app_routes.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:salah/core/services/firestore_service.dart';
import 'package:salah/core/services/auth_service.dart';
import 'package:salah/core/services/storage_service.dart';
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

  /// Initialize the service
  Future<NotificationService> init() async {
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
          sound: RawResourceAndroidNotificationSound('adhan'),
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

  /// Handle notification tap – open dashboard when user taps notification
  void _onNotificationTapped(NotificationResponse response) {
    try {
      Get.toNamed(AppRoutes.dashboard);
      final auth = Get.find<AuthService>();
      final userId = auth.currentUser.value?.uid;
      if (userId != null) {
        Get.find<FirestoreService>().addAnalyticsEvent(
          userId: userId,
          event: 'notification_tapped',
          data: {
            'payload': response.payload,
          },
        );
      }
    } catch (_) {}
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
      finalChannelId.contains('prayer') ? 'Prayer Notifications' : 'Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: soundMode != NotificationSoundMode.silent,
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
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

  // ============================================================
  // PRAYER NOTIFICATIONS
  // ============================================================

  /// Schedule prayer time notification
  Future<void> schedulePrayerNotification({
    required int id,
    required String prayerName,
    required DateTime prayerTime,
  }) async {
    await scheduleNotification(
      id: id,
      title: 'حان وقت صلاة $prayerName',
      body: 'حيّ على الصلاة',
      scheduledTime: prayerTime,
      payload: 'prayer_$prayerName',
      channelId: ApiConstants.prayerNotificationChannelId, // This will be mapped in _getNotificationDetails
    );
  }

  /// Schedule prayer reminder (30 min after adhan)
  Future<void> schedulePrayerReminder({
    required int id,
    required String prayerName,
    required DateTime prayerTime,
  }) async {
    final reminderTime = prayerTime.add(
      const Duration(minutes: ApiConstants.prayerReminderDelayMinutes),
    );

    await scheduleNotification(
      id: id,
      title: 'هل صليت $prayerName؟',
      body: 'اضغط لتسجيل صلاتك',
      scheduledTime: reminderTime,
      payload: 'reminder_$prayerName',
      channelId: ApiConstants.reminderNotificationChannelId,
    );
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
      title: 'تذكير من $senderName',
      body: 'ذكّرك بصلاة $prayerName',
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
