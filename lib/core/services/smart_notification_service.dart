import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/constants/storage_keys.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../data/models/notification_models.dart';
import '../constants/api_constants.dart';
import 'storage_service.dart';

/// Smart Notification Service
/// يدير الإشعارات الذكية مع Quick Actions والتذكيرات المبنية على نمط المستخدم
class SmartNotificationService extends GetxService {
  // ============================================================
  // PRIVATE MEMBERS
  // ============================================================

  late final FlutterLocalNotificationsPlugin _notificationsPlugin;
  late final StorageService _storageService;

  // Stream controller for notification actions
  final _actionStreamController =
      StreamController<NotificationActionType>.broadcast();

  /// Stream of notification actions
  Stream<NotificationActionType> get actionStream =>
      _actionStreamController.stream;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  bool _isInitialized = false;

  /// Initialize the service
  Future<SmartNotificationService> init() async {
    if (_isInitialized) return this;
    _isInitialized = true;
    _notificationsPlugin = FlutterLocalNotificationsPlugin();
    _storageService = Get.find<StorageService>();

    // Initialize notification settings with action support
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          _handleBackgroundNotificationResponse,
    );

    return this;
  }

  // ============================================================
  // PRAYER TIME NOTIFICATIONS
  // ============================================================

  /// Show prayer time notification with quick actions
  Future<void> showPrayerTimeNotification({
    required int id,
    required String prayerName,
    required String prayerNameEn,
    required DateTime prayerTime,
    String language = 'ar',
  }) async {
    final notificationsEnabled =
        _storageService.read<bool>(StorageKeys.notificationsEnabled) ?? true;
    if (!notificationsEnabled) return;

    final adhanMasterEnabled =
        _storageService.read<bool>(StorageKeys.adhanNotificationsEnabled) ??
        true;
    if (!adhanMasterEnabled) return;

    final isArabic = language == 'ar';

    final title = isArabic
        ? 'حان وقت $prayerName 🕌'
        : 'Time for $prayerNameEn 🕌';

    final body = isArabic ? 'هيا لنصلي معاً' : "Let's pray together";

    final soundMode = _storageService.getNotificationSoundMode();
    final channelId = _getPrayerChannelId(soundMode);

    // Android notification details with actions
    final androidDetails = AndroidNotificationDetails(
      channelId,
      isArabic ? 'إشعارات الصلاة' : 'Prayer Notifications',
      channelDescription: isArabic
          ? 'إشعارات مواقيت الصلاة'
          : 'Prayer time notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: soundMode == NotificationSoundMode.adhan,
      enableVibration: soundMode != NotificationSoundMode.silent,
      category: AndroidNotificationCategory.reminder,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          NotificationActionType.prayNow.name,
          isArabic ? '✅ صليت' : '✅ Prayed',
          showsUserInterface: false,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          NotificationActionType.snooze5.name,
          isArabic ? '⏰ 5 دقائق' : '⏰ 5 min',
          showsUserInterface: false,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          NotificationActionType.markMissed.name,
          isArabic ? '❌ فاتتني' : '❌ Missed',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
      // Store prayer info in payload
      tag: prayerName,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: soundMode != NotificationSoundMode.silent,
      ),
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: '$prayerName|${prayerTime.toIso8601String()}',
    );
  }

  /// Show smart reminder notification (30 min after prayer time)
  Future<void> showSmartReminder({
    required int id,
    required String prayerName,
    required String prayerNameEn,
    required DateTime prayerTime,
    String language = 'ar',
  }) async {
    final notificationsEnabled =
        _storageService.read<bool>(StorageKeys.notificationsEnabled) ?? true;
    if (!notificationsEnabled) return;

    final reminderEnabled =
        _storageService.read<bool>(StorageKeys.reminderNotification) ?? true;
    if (!reminderEnabled) return;

    final isArabic = language == 'ar';

    final title = isArabic
        ? 'هل صليت $prayerName؟ 🤲'
        : 'Did you pray $prayerNameEn? 🤲';

    final body = isArabic
        ? 'مرّت 30 دقيقة على الأذان'
        : '30 minutes since Adhan';

    final soundMode = _storageService.getNotificationSoundMode();

    final androidDetails = AndroidNotificationDetails(
      ApiConstants.reminderNotificationChannelId,
      isArabic ? 'تذكيرات الصلاة' : 'Prayer Reminders',
      channelDescription: isArabic
          ? 'تذكيرات بعد وقت الصلاة'
          : 'Reminders after prayer time',
      importance: Importance.high,
      priority: Priority.high,
      playSound: soundMode == NotificationSoundMode.adhan,
      enableVibration: soundMode != NotificationSoundMode.silent,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          NotificationActionType.confirmPrayed.name,
          isArabic ? '✅ نعم' : '✅ Yes',
          showsUserInterface: false,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          NotificationActionType.willPrayNow.name,
          isArabic ? '🕌 سأصلي الآن' : '🕌 Will pray now',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
      tag: '$prayerName-reminder',
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: soundMode != NotificationSoundMode.silent,
      ),
    );

    await _notificationsPlugin.show(
      id: id + 100, // Different ID for reminder
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: '$prayerName|reminder|${prayerTime.toIso8601String()}',
    );
  }

  /// Schedule smart reminder based on user pattern
  Future<void> scheduleSmartReminder({
    required int id,
    required String prayerName,
    required String prayerNameEn,
    required DateTime prayerTime,
    UserPrayerPattern? pattern,
    String language = 'ar',
  }) async {
    Duration delay = const Duration(minutes: 30); // Default

    if (pattern != null && pattern.confidence > 0.5) {
      delay = pattern.getOptimalReminderOffset();
    }

    final scheduledTime = prayerTime.add(delay);

    if (scheduledTime.isBefore(DateTime.now())) return;

    final isArabic = language == 'ar';

    final androidDetails = AndroidNotificationDetails(
      ApiConstants.reminderNotificationChannelId,
      isArabic ? 'تذكيرات ذكية' : 'Smart Reminders',
      importance: Importance.high,
      priority: Priority.high,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          NotificationActionType.confirmPrayed.name,
          isArabic ? '✅ نعم' : '✅ Yes',
          showsUserInterface: false,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          NotificationActionType.willPrayNow.name,
          isArabic ? '🕌 سأصلي الآن' : '🕌 Will pray now',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    await _notificationsPlugin.zonedSchedule(
      id: id + 200,
      title: isArabic ? 'هل صليت $prayerName؟' : 'Did you pray $prayerNameEn?',
      body: isArabic ? 'لا تنسَ صلاتك 💚' : "Don't forget your prayer 💚",
      scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails: NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: '$prayerName|smart_reminder|${prayerTime.toIso8601String()}',
    );
  }

  // ============================================================
  // FAMILY NOTIFICATIONS
  // ============================================================

  /// Show family encouragement notification
  Future<void> showFamilyEncouragement({
    required int id,
    required String memberName,
    required String prayerName,
    required String prayerNameEn,
    String language = 'ar',
  }) async {
    final notificationsEnabled =
        _storageService.read<bool>(StorageKeys.notificationsEnabled) ?? true;
    if (!notificationsEnabled) return;

    final familyEnabled =
        _storageService.read<bool>(StorageKeys.familyNotification) ?? true;
    if (!familyEnabled) return;

    final isArabic = language == 'ar';

    final title = isArabic
        ? '🎉 $memberName صلّى $prayerName!'
        : '🎉 $memberName prayed $prayerNameEn!';

    final body = isArabic
        ? 'لا تتأخر، صلِّ معهم'
        : "Don't be late, pray with them";

    final androidDetails = AndroidNotificationDetails(
      ApiConstants.socialNotificationChannelId,
      isArabic ? 'إشعارات العائلة' : 'Family Notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: androidDetails),
      payload: 'family_encouragement|$memberName|$prayerName',
    );
  }

  /// Show streak celebration notification
  Future<void> showStreakCelebration({
    required int id,
    required int streakDays,
    String language = 'ar',
  }) async {
    final isArabic = language == 'ar';

    String title;
    String body;

    if (streakDays == 7) {
      title = isArabic ? '🔥 أسبوع كامل!' : '🔥 Full Week!';
      body = isArabic
          ? 'ما شاء الله! أكملت أسبوعاً متواصلاً'
          : 'MashaAllah! You completed a full week';
    } else if (streakDays == 30) {
      title = isArabic ? '🏆 شهر كامل!' : '🏆 Full Month!';
      body = isArabic
          ? 'إنجاز عظيم! شهر من الصلاة المتواصلة'
          : 'Great achievement! A month of consistent prayer';
    } else {
      title = isArabic ? '🔥 $streakDays يوم!' : '🔥 $streakDays Days!';
      body = isArabic ? 'استمر على هذا الحال! 💪' : 'Keep it up! 💪';
    }

    final androidDetails = AndroidNotificationDetails(
      ApiConstants.socialNotificationChannelId,
      isArabic ? 'إشعارات الإنجازات' : 'Achievement Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: androidDetails),
      payload: 'streak_celebration|$streakDays',
    );
  }

  // ============================================================
  // MISSED PRAYERS NOTIFICATION
  // ============================================================

  /// Show missed prayers reminder (evening)
  Future<void> showMissedPrayersReminder({
    required int id,
    required int missedCount,
    required List<String> missedPrayers,
    String language = 'ar',
  }) async {
    final isArabic = language == 'ar';

    final title = isArabic
        ? 'لم تسجل $missedCount صلوات 💙'
        : 'You haven\'t logged $missedCount prayers 💙';

    final prayersText = missedPrayers.join(', ');
    final body = isArabic
        ? '$prayersText - سجّل الآن'
        : '$prayersText - Log now';

    final androidDetails = AndroidNotificationDetails(
      ApiConstants.reminderNotificationChannelId,
      isArabic ? 'تذكيرات التسجيل' : 'Logging Reminders',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'open_batch_log',
          'سجّل الآن',
          showsUserInterface: true,
        ),
      ],
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: androidDetails),
      payload: 'missed_prayers|$prayersText',
    );
  }

  // ============================================================
  // NOTIFICATION HANDLERS
  // ============================================================

  /// Handle notification response (when user taps or uses action)
  void _handleNotificationResponse(NotificationResponse response) {
    final actionId = response.actionId;
    final payload = response.payload;

    if (actionId != null && actionId.isNotEmpty) {
      final actionType = _parseActionType(actionId);
      if (actionType != null) {
        _actionStreamController.add(actionType);
        _handleAction(actionType, payload);
      }
    } else if (payload != null) {
      // User tapped the notification body
      _handleNotificationTap(payload);
    }
  }

  /// Handle background notification response
  @pragma('vm:entry-point')
  static void _handleBackgroundNotificationResponse(
    NotificationResponse response,
  ) {
    // Handle in background - limited capabilities
    // Store action to process when app opens
  }

  /// Handle specific action
  Future<void> _handleAction(
    NotificationActionType action,
    String? payload,
  ) async {
    switch (action) {
      case NotificationActionType.prayNow:
      case NotificationActionType.confirmPrayed:
        await _logPrayerFromNotification(payload);
        break;

      case NotificationActionType.snooze5:
        await _scheduleSnooze(payload, const Duration(minutes: 5));
        break;

      case NotificationActionType.snooze10:
        await _scheduleSnooze(payload, const Duration(minutes: 10));
        break;

      case NotificationActionType.snooze15:
        await _scheduleSnooze(payload, const Duration(minutes: 15));
        break;

      case NotificationActionType.markMissed:
        await _markPrayerMissed(payload);
        break;

      case NotificationActionType.willPrayNow:
        // Just acknowledge, user will pray
        break;

      case NotificationActionType.dismiss:
        // Just dismiss
        break;
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(String payload) {
    // Navigate to appropriate screen based on payload
    // This will be handled by the controller
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  Future<void> _logPrayerFromNotification(String? payload) async {
    if (payload == null) return;

    final parts = payload.split('|');
    if (parts.isEmpty) return;

    final prayerName = parts[0];
    // Store pending action to be processed by controller
    await _storageService.setPendingPrayerLog(prayerName, DateTime.now());
  }

  Future<void> _scheduleSnooze(String? payload, Duration delay) async {
    if (payload == null) return;

    final parts = payload.split('|');
    if (parts.isEmpty) return;

    final prayerName = parts[0];
    final prayerTime = parts.length > 1
        ? DateTime.tryParse(parts.last)
        : DateTime.now();

    // Schedule a new reminder
    await Future.delayed(delay);
    await showSmartReminder(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      prayerName: prayerName,
      prayerNameEn: prayerName, // Will be localized
      prayerTime: prayerTime ?? DateTime.now(),
      language: _storageService.getLanguage(),
    );
  }

  Future<void> _markPrayerMissed(String? payload) async {
    if (payload == null) return;

    final parts = payload.split('|');
    if (parts.isEmpty) return;

    final prayerName = parts[0];
    // Store pending missed prayer
    await _storageService.setPendingMissedPrayer(prayerName, DateTime.now());
  }

  NotificationActionType? _parseActionType(String actionId) {
    try {
      return NotificationActionType.values.firstWhere(
        (e) => e.name == actionId,
      );
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // CLEANUP
  // ============================================================

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

  @override
  void onClose() {
    _actionStreamController.close();
    super.onClose();
  }
}
