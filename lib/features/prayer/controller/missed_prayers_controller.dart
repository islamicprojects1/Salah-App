import 'package:get/get.dart';
import 'package:salah/core/di/injection_container.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/feedback/app_feedback.dart';
import 'package:salah/features/auth/data/services/auth_service.dart';
import 'package:salah/features/prayer/data/models/prayer_log_model.dart';
import 'package:salah/features/prayer/data/models/prayer_time_model.dart';
import 'package:salah/features/prayer/data/repositories/prayer_repository.dart';
import 'package:salah/features/prayer/data/services/prayer_time_service.dart';
import 'package:salah/features/prayer/data/services/qada_detection_service.dart';
import 'package:salah/core/widgets/app_dialogs.dart';

/// Controller for managing missed/unlogged prayers (by day + one-tap "I prayed all").
class MissedPrayersController extends GetxController {
  // ============================================================
  // DEPENDENCIES
  // ============================================================

  final PrayerTimeService _prayerTimeService = sl<PrayerTimeService>();
  final AuthService _authService = sl<AuthService>();
  final PrayerRepository _prayerRepo = sl<PrayerRepository>();

  // ============================================================
  // STATE
  // ============================================================

  /// By-day groups (last 7 days).
  final unloggedByDay = <QadaDayGroup>[].obs;
  final statusByKey = <String, PrayerCardStatus>{}.obs;
  final timingByKey = <String, PrayerTimingQuality>{}.obs;

  final missedPrayers = <PrayerTimeModel>[].obs;
  final prayerStatuses = <PrayerName, PrayerCardStatus>{}.obs;
  final prayerTimings = <PrayerName, PrayerTimingQuality>{}.obs;
  final isLoading = false.obs;
  final isSaving = false.obs;
  final isLoggingDay = false.obs;

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void onInit() {
    super.onInit();
    loadMissedPrayers();
  }

  // ============================================================
  // METHODS
  // ============================================================

  /// Load unlogged prayers grouped by day (last 7 days).
  Future<void> loadMissedPrayers() async {
    if (!sl.isRegistered<QadaDetectionService>()) {
      _loadLegacyTodayOnly();
      return;
    }
    try {
      isLoading.value = true;
      final qada = sl<QadaDetectionService>();
      final groups = await qada.getUnloggedByDay(lastDays: 7);
      unloggedByDay.assignAll(groups);
      statusByKey.clear();
      timingByKey.clear();
      for (final g in groups) {
        for (final p in g.prayers) {
          statusByKey[p.key] = PrayerCardStatus.prayed;
          timingByKey[p.key] = PrayerTimingQuality.onTime;
        }
      }
      _syncLegacyFromFirstGroup();
    } catch (_) {
      AppFeedback.showError('error'.tr, 'missed_prayers_load_failed'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadLegacyTodayOnly() async {
    try {
      isLoading.value = true;
      final allPrayers = _prayerTimeService
          .getTodayPrayers()
          .where((p) => p.prayerType != PrayerName.sunrise)
          .toList();
      final userId = _authService.currentUser.value?.uid ?? '';
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final logs = await _prayerRepo.getPrayerLogsInRange(
        userId: userId,
        startDate: startOfDay,
        endDate: endOfDay,
      );
      final now = DateTime.now();
      final unlogged = <PrayerTimeModel>[];
      for (final prayer in allPrayers) {
        if (prayer.dateTime.isBefore(now) &&
            !logs.any((log) => log.prayer == prayer.prayerType)) {
          unlogged.add(prayer);
          final pt = prayer.prayerType;
          if (pt != null) {
            prayerStatuses[pt] = PrayerCardStatus.prayed;
            prayerTimings[pt] = PrayerTimingQuality.onTime;
          }
        }
      }
      missedPrayers.value = unlogged;
    } catch (_) {
      AppFeedback.showError('error'.tr, 'missed_prayers_load_failed'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  void _syncLegacyFromFirstGroup() {
    if (unloggedByDay.isEmpty) {
      missedPrayers.clear();
      return;
    }
    final first = unloggedByDay.first;
    missedPrayers.assignAll(
      first.prayers.map((p) => PrayerTimeModel(
            name: p.displayName,
            prayerType: p.prayer,
            dateTime: p.adhanTime,
          )),
    );
    prayerStatuses.clear();
    prayerTimings.clear();
    for (final p in first.prayers) {
      prayerStatuses[p.prayer] = statusByKey[p.key] ?? PrayerCardStatus.prayed;
      prayerTimings[p.prayer] = timingByKey[p.key] ?? PrayerTimingQuality.onTime;
    }
  }

  void setPrayerStatusByKey(String key, PrayerCardStatus status) {
    statusByKey[key] = status;
    timingByKey[key] = status == PrayerCardStatus.missed
        ? PrayerTimingQuality.missed
        : PrayerTimingQuality.onTime;
  }

  void setPrayerTimingByKey(String key, PrayerTimingQuality timing) {
    timingByKey[key] = timing;
  }

  void setPrayerStatus(PrayerName prayer, PrayerCardStatus status) {
    prayerStatuses[prayer] = status;
    if (status == PrayerCardStatus.missed) {
      prayerTimings[prayer] = PrayerTimingQuality.missed;
    } else {
      prayerTimings[prayer] = PrayerTimingQuality.onTime;
    }
  }

  void setPrayerTiming(PrayerName prayer, PrayerTimingQuality timing) {
    prayerTimings[prayer] = timing;
  }

  /// One-tap: log all prayers for a day as prayed on time.
  Future<void> logAllForDay(QadaDayGroup group) async {
    final confirm = await AppDialogs.confirm(
      title: 'qada_log_all'.tr,
      message: 'qada_confirm_log_all_day'.trParams({
        'day': group.label,
        'count': '${group.count}',
      }),
      confirmText: 'qada_log_all'.tr,
      cancelText: 'cancel'.tr,
    );
    if (!confirm) return;
    final userId = _authService.currentUser.value?.uid ?? '';
    if (userId.isEmpty) return;
    try {
      isLoggingDay.value = true;
      bool anyQueued = false;
      for (final info in group.prayers) {
        final log = PrayerLogModel(
          id: '',
          oderId: userId,
          prayer: info.prayer,
          prayedAt: info.adhanTime,
          adhanTime: info.adhanTime,
          quality: PrayerQuality.onTime,
          timingQuality: PrayerTimingQuality.onTime,
          note: 'Batch logged (qada)',
        );
        final synced = await _prayerRepo.addPrayerLog(userId: userId, log: log);
        if (!synced) anyQueued = true;
      }
      final msg = anyQueued ? 'saved_will_sync_later'.tr : 'qada_logged_day_toast'.tr;
      AppFeedback.showSuccess('done'.tr, msg);
      await loadMissedPrayers();
    } catch (_) {
      AppFeedback.showError('error'.tr, 'prayer_log_failed'.tr);
    } finally {
      isLoggingDay.value = false;
    }
  }

  /// Save all prayers (all days when using by-day data, or legacy today-only).
  Future<void> saveAll() async {
    try {
      isSaving.value = true;
      final userId = _authService.currentUser.value?.uid ?? '';
      bool anyQueued = false;

      if (unloggedByDay.isNotEmpty) {
        for (final group in unloggedByDay) {
          for (final info in group.prayers) {
            final status = statusByKey[info.key];
            final timing = timingByKey[info.key];
            if (status == null) continue;
            final prayedAt = status == PrayerCardStatus.missed
                ? info.adhanTime.add(const Duration(minutes: 61))
                : info.adhanTime;
            final log = PrayerLogModel(
              id: '',
              oderId: userId,
              prayer: info.prayer,
              prayedAt: prayedAt,
              adhanTime: info.adhanTime,
              quality: _convertToLegacyQuality(timing ?? PrayerTimingQuality.onTime),
              timingQuality: timing ?? PrayerTimingQuality.onTime,
              note: status == PrayerCardStatus.missed ? 'Logged as missed' : 'Batch logged',
            );
            final synced = await _prayerRepo.addPrayerLog(userId: userId, log: log);
            if (!synced) anyQueued = true;
          }
        }
        final message = anyQueued ? 'saved_will_sync_later'.tr : 'prayers_saved'.tr;
        AppFeedback.showSuccess('success'.tr, message);
        await loadMissedPrayers();
        Get.back();
        return;
      }

      for (final prayer in missedPrayers) {
        final prayerType = prayer.prayerType;
        if (prayerType == null) continue;

        final status = prayerStatuses[prayerType];
        final timing = prayerTimings[prayerType];

        if (status == null) continue;

        // Get prayer time range for quality calculation
        final prayerTimes = _prayerTimeService.prayerTimes.value;
        if (prayerTimes == null) continue;

        final range = PrayerTimeRange.fromPrayerTimes(
          prayerTimes: prayerTimes,
          prayer: prayerType,
        );

        if (range == null) continue;

        DateTime prayedAt;

        if (status == PrayerCardStatus.missed) {
          // If missed, use adhan time (will be marked as missed in quality)
          prayedAt = prayer.dateTime.add(
            Duration(minutes: range.totalMinutes + 1),
          );
        } else {
          // If prayed, get suggested time based on selected quality
          prayedAt = range.getSuggestedTime(
            timing ?? PrayerTimingQuality.onTime,
          );
        }

        // Create prayer log
        final log = PrayerLogModel(
          id: '',
          oderId: userId,
          prayer: prayerType,
          prayedAt: prayedAt,
          adhanTime: prayer.dateTime,
          quality: _convertToLegacyQuality(
            timing ?? PrayerTimingQuality.onTime,
          ),
          timingQuality: timing,
          note: status == PrayerCardStatus.missed
              ? 'Logged as missed'
              : 'Batch logged',
        );

        // Save using Repository (handles offline)
        final synced = await _prayerRepo.addPrayerLog(userId: userId, log: log);
        if (!synced) anyQueued = true;
      }

      final message = anyQueued ? 'saved_will_sync_later'.tr : 'prayers_saved'.tr;
      AppFeedback.showSuccess('success'.tr, message);
      Get.back();
    } catch (_) {
      AppFeedback.showError('error'.tr, 'error_saving_prayers'.tr);
    } finally {
      isSaving.value = false;
    }
  }

  /// Convert new timing quality to legacy quality (for backward compatibility)
  PrayerQuality _convertToLegacyQuality(PrayerTimingQuality timing) {
    switch (timing) {
      case PrayerTimingQuality.veryEarly:
      case PrayerTimingQuality.early:
        return PrayerQuality.early;
      case PrayerTimingQuality.onTime:
        return PrayerQuality.onTime;
      case PrayerTimingQuality.late:
      case PrayerTimingQuality.veryLate:
        return PrayerQuality.late;
      case PrayerTimingQuality.missed:
      case PrayerTimingQuality.notYet:
        return PrayerQuality.missed;
    }
  }

  /// Skip for now
  void skip() {
    Get.back();
  }
}
