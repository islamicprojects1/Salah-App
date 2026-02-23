import 'dart:convert';
import 'package:get/get.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/constants/storage_keys.dart';
import 'package:salah/core/error/app_logger.dart';
import 'package:salah/core/feedback/app_feedback.dart';
import 'package:salah/core/helpers/prayer_names.dart';
import 'package:salah/core/services/storage_service.dart';
import 'package:salah/core/di/injection_container.dart';
import 'package:salah/features/auth/data/services/auth_service.dart';
import 'package:salah/features/prayer/data/models/prayer_log_model.dart';
import 'package:salah/features/prayer/data/models/prayer_time_model.dart';
import 'package:salah/features/prayer/data/repositories/prayer_repository.dart';
import 'package:salah/features/prayer/data/services/firestore_service.dart';
import 'package:salah/features/prayer/data/services/live_context_service.dart';
import 'package:salah/features/prayer/data/services/notification_service.dart';
import 'package:salah/features/prayer/data/services/qada_detection_service.dart';
import 'package:salah/features/family/controller/family_controller.dart';

/// Handles all prayer logging operations:
/// - Current prayer logging
/// - Past prayer logging
/// - Batch logging of unlogged prayers
/// - Processing pending logs queued from notification actions
///
/// Extracted from [DashboardController] for single-responsibility.
class PrayerLogger {
  final AuthService _authService;
  final PrayerRepository _prayerRepo;
  final NotificationService _notificationService;
  final LiveContextService _liveContextService;
  final QadaDetectionService _qadaService;

  PrayerLogger({
    required AuthService authService,
    required PrayerRepository prayerRepo,
    required NotificationService notificationService,
    required LiveContextService liveContextService,
    required QadaDetectionService qadaService,
  })  : _authService = authService,
        _prayerRepo = prayerRepo,
        _notificationService = notificationService,
        _liveContextService = liveContextService,
        _qadaService = qadaService;

  /// Today's logs — delegates to [LiveContextService].
  RxList<PrayerLogModel> get todayLogs => _liveContextService.todayLogs;

  // ============================================================
  // LOG CURRENT PRAYER
  // ============================================================

  /// Log a current prayer.
  /// Returns the updated streak value, or null on failure.
  Future<int?> logPrayer(PrayerTimeModel prayer) async {
    final userId = _authService.userId;
    if (userId == null) return null;
    try {
      final isLogged = PrayerNames.isPrayerLogged(
        todayLogs,
        prayer.name,
        prayer.prayerType,
      );
      if (isLogged) {
        AppFeedback.showSnackbar('alert'.tr, 'already_logged_snackbar'.tr);
        return null;
      }
      final log = PrayerLogModel.create(
        oderId: userId,
        prayer: PrayerNames.fromDisplayName(prayer.name),
        adhanTime: prayer.dateTime,
      );
      final synced = await _prayerRepo.addPrayerLog(userId: userId, log: log);

      final prayerType = prayer.prayerType;
      final baseId = notificationIdForPrayer(prayerType);
      await _notificationService.cancelNotification(baseId);
      await _notificationService.cancelNotification(baseId + 100);
      _qadaService.resetSnoozeCount(prayerType);
      _qadaService.onPrayerLogged();
      _liveContextService.onPrayerLogged();
      _notifyFamily(prayerType);

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

      int? updatedStreak;
      if (todayLogs.length >= 5) {
        updatedStreak = await _prayerRepo.updateStreak(userId);
      }

      if (synced) {
        AppFeedback.showSuccess('success_done'.tr, 'prayer_accepted'.tr);
      } else {
        AppFeedback.showSuccess('success_done'.tr, 'saved_will_sync_later'.tr);
      }
      return updatedStreak;
    } catch (e) {
      AppFeedback.showError(
        'error'.tr,
        'error_log_prayer'.trParams({'error': e.toString()}),
      );
      return null;
    }
  }

  // ============================================================
  // LOG PAST PRAYER
  // ============================================================

  /// Log a past prayer (e.g. user forgot to tap notification).
  /// Returns the updated streak value, or null on failure.
  Future<int?> logPastPrayer(PrayerTimeModel prayer) async {
    final userId = _authService.userId;
    if (userId == null) return null;
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
        return null;
      }
      final log = PrayerLogModel.create(
        oderId: userId,
        prayer: PrayerNames.fromDisplayName(prayer.name),
        adhanTime: prayer.dateTime,
      );
      final synced = await _prayerRepo.addPrayerLog(userId: userId, log: log);

      final prayerType = prayer.prayerType;
      final baseId = notificationIdForPrayer(prayerType);
      await _notificationService.cancelNotification(baseId);
      await _notificationService.cancelNotification(baseId + 100);
      _qadaService.resetSnoozeCount(prayerType);
      _qadaService.onPrayerLogged();
      _liveContextService.onPrayerLogged();
      _notifyFamily(prayerType);

      int? updatedStreak;
      if (todayLogs.length >= 5) {
        updatedStreak = await _prayerRepo.updateStreak(userId);
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
      return updatedStreak;
    } catch (e) {
      AppFeedback.showError('error'.tr, 'prayer_log_failed'.tr);
      return null;
    }
  }

  // ============================================================
  // BATCH LOG ALL UNLOGGED
  // ============================================================

  /// Batch-log all unlogged past prayers in one tap.
  /// Returns the updated streak value, or null if nothing was logged.
  Future<int?> logAllUnloggedPrayers(List<PrayerTimeModel> todayPrayers) async {
    final userId = _authService.userId;
    if (userId == null) return null;
    final now = DateTime.now();

    final toLog = todayPrayers.where((prayer) {
      if (prayer.prayerType == PrayerName.sunrise) return false;
      if (prayer.dateTime.isAfter(now)) return false;
      return !PrayerNames.isPrayerLogged(
        todayLogs,
        prayer.name,
        prayer.prayerType,
      );
    }).toList();

    if (toLog.isEmpty) return null;

    int logged = 0;
    bool anyQueued = false;

    await Future.wait(
      toLog.map((prayer) async {
        try {
          final log = PrayerLogModel.create(
            oderId: userId,
            prayer: PrayerNames.fromDisplayName(prayer.name),
            adhanTime: prayer.dateTime,
          );
          final synced = await _prayerRepo.addPrayerLog(
            userId: userId,
            log: log,
          );
          if (!synced) anyQueued = true;
          logged++;
          _notifyFamily(prayer.prayerType);
        } catch (e) {
          AppLogger.debug('Batch log failed for ${prayer.name}', e);
        }
      }),
    );

    if (logged > 0) {
      _liveContextService.onPrayerLogged();
      int? updatedStreak;
      if (todayLogs.length >= 5) {
        updatedStreak = await _prayerRepo.updateStreak(userId);
      }
      final message = anyQueued
          ? 'saved_will_sync_later'.tr
          : '$logged ${'prayers_logged_count'.tr}';
      AppFeedback.showSuccess('prayer_logged_success'.tr, message);
      return updatedStreak;
    }
    return null;
  }

  // ============================================================
  // PENDING NOTIFICATION LOG
  // ============================================================

  /// Process a prayer log queued from a notification action when the
  /// app was not in the foreground.
  Future<void> processPendingPrayerLogFromNotification() async {
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
      if (baseId != null) {
        await _notificationService.cancelNotification(baseId);
        await _notificationService.cancelNotification(baseId + 100);
      }
      await storage.remove(StorageKeys.pendingPrayerLog);
      _liveContextService.onPrayerLogged();
      _notifyFamily(prayer);
      if (synced) {
        AppFeedback.showSuccess(
          'done'.tr,
          'prayer_logged_from_notif'.trParams({'prayer': displayName}),
        );
      } else {
        AppFeedback.showSuccess('done'.tr, 'saved_will_sync_later'.tr);
      }
    } catch (e) {
      AppLogger.error(
          'Process pending prayer log from notification failed', e);
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  /// Notify the family controller that a prayer was logged so it can
  /// update the member's per-prayer status and daily X/Y summary.
  /// Safe to call even when FamilyController is not registered.
  void _notifyFamily(PrayerName prayer) {
    if (Get.isRegistered<FamilyController>()) {
      Get.find<FamilyController>().onPrayerLogged(prayer).ignore();
    }
  }

  /// Map a [PrayerName] to its notification base ID.
  static int notificationIdForPrayer(PrayerName prayer) {
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
}
