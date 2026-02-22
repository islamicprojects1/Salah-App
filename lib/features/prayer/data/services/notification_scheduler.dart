import 'package:get/get.dart';
import 'package:salah/core/constants/api_constants.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/constants/storage_keys.dart';
import 'package:salah/core/error/app_logger.dart';
import 'package:salah/core/feedback/app_feedback.dart';
import 'package:salah/core/services/storage_service.dart';
import 'package:salah/core/di/injection_container.dart';
import 'package:salah/features/auth/data/services/auth_service.dart';
import 'package:salah/features/prayer/data/models/prayer_time_model.dart';
import 'package:salah/features/prayer/data/repositories/prayer_repository.dart';
import 'package:salah/features/prayer/data/services/notification_service.dart';
import 'package:salah/features/prayer/data/services/prayer_logger.dart';

/// Handles scheduling and cancelling prayer notifications for today's prayers.
///
/// Reads user preferences (adhan enabled per prayer, reminder toggle) from
/// [StorageService] and delegates actual notification display to
/// [NotificationService].
///
/// Extracted from [DashboardController] for single-responsibility.
class NotificationScheduler {
  final NotificationService _notificationService;
  final PrayerRepository _prayerRepo;
  final AuthService _authService;

  NotificationScheduler({
    required NotificationService notificationService,
    required PrayerRepository prayerRepo,
    required AuthService authService,
  })  : _notificationService = notificationService,
        _prayerRepo = prayerRepo,
        _authService = authService;

  /// Schedule notifications for all upcoming prayers in [todayPrayers].
  ///
  /// Cancels all existing notifications first, then re-schedules based on
  /// user preferences and already-logged prayers.
  Future<void> scheduleNotifications(List<PrayerTimeModel> todayPrayers) async {
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
        if (prayer.prayerType == PrayerName.sunrise) continue;
        if (!prayer.dateTime.isAfter(now)) continue;

        final alreadyLogged = await _prayerRepo.hasLoggedPrayerToday(
          userId,
          prayer.prayerType,
        );
        if (alreadyLogged) continue;

        final prayerType = prayer.prayerType;
        final baseId = PrayerLogger.notificationIdForPrayer(prayerType);
        final prayerKey = prayerType.name;

        if (_isAdhanEnabledForPrayer(storage, prayerType)) {
          await _notificationService.schedulePrayerNotificationWithActions(
            id: baseId,
            prayerName: prayer.name,
            prayerKey: prayerKey,
            prayerTime: prayer.dateTime,
          );
        }
        if (_isReminderEnabledForPrayer(storage, prayerType)) {
          await _notificationService.schedulePrayerReminderWithActions(
            id: baseId + 100,
            prayerName: prayer.name,
            prayerKey: prayerKey,
            prayerTime: prayer.dateTime,
          );
        }
      }

      // Schedule daily review notification after Isha
      final ishaPrayer = todayPrayers
          .where((p) => p.prayerType == PrayerName.isha)
          .firstOrNull;
      if (ishaPrayer != null) {
        final reviewTime = ishaPrayer.dateTime.add(
          Duration(minutes: ApiConstants.prayerReminderDelayMinutes),
        );
        if (reviewTime.isAfter(now)) {
          await _notificationService.scheduleNotification(
            id: 999,
            title: 'daily_review_title'.tr,
            body: 'daily_review_notification'.tr,
            scheduledTime: reviewTime,
            payload: 'daily_review',
          );
        }
      }
    } catch (e) {
      AppLogger.error('Notification schedule failed', e);
      AppFeedback.showError('error'.tr, 'notification_schedule_error'.tr);
    }
  }

  /// Whether adhan notification is enabled for a specific prayer.
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

  /// Whether reminder notification is enabled for a specific prayer.
  bool _isReminderEnabledForPrayer(StorageService storage, PrayerName prayer) {
    return storage.read<bool>(StorageKeys.reminderNotification) ?? true;
  }
}
