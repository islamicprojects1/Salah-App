import 'package:get/get.dart';
import 'package:salah/core/services/prayer_time_service.dart';
import 'package:salah/core/services/firestore_service.dart';
import 'package:salah/core/services/auth_service.dart';
import 'package:salah/data/models/prayer_log_model.dart';
import 'package:salah/data/models/prayer_time_model.dart';

/// Controller for managing missed/unlogged prayers
class MissedPrayersController extends GetxController {
  // ============================================================
  // DEPENDENCIES
  // ============================================================

  final PrayerTimeService _prayerTimeService = Get.find<PrayerTimeService>();
  final FirestoreService _firestoreService = Get.find<FirestoreService>();
  final AuthService _authService = Get.find<AuthService>();

  // ============================================================
  // STATE
  // ============================================================

  final missedPrayers = <PrayerTimeModel>[].obs;
  final prayerStatuses = <PrayerName, PrayerStatus>{}.obs;
  final prayerTimings = <PrayerName, PrayerTimingQuality>{}.obs;
  final isLoading = false.obs;
  final isSaving = false.obs;

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void onInit() {
    super.onInit();
    _loadMissedPrayers();
  }

  // ============================================================
  // METHODS
  // ============================================================

  /// Load prayers that haven't been logged today
  Future<void> _loadMissedPrayers() async {
    try {
      isLoading.value = true;

      // Get today's prayers
      final allPrayers = _prayerTimeService
          .getTodayPrayers()
          .where((p) => p.prayerType != PrayerName.sunrise)
          .toList();

      // Get today's logs
      final userId = _authService.currentUser.value?.uid ?? '';
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final logs = await _firestoreService.getPrayerLogs(
        userId: userId,
        startDate: startOfDay,
        endDate: endOfDay,
      );

      // Find unlogged prayers (prayers that have passed but not logged)
      final now = DateTime.now();
      final unlogged = <PrayerTimeModel>[];

      for (final prayer in allPrayers) {
        // Check if prayer time has passed
        if (prayer.dateTime.isBefore(now)) {
          // Check if not logged
          final hasLog = logs.any((log) => log.prayer == prayer.prayerType);
          if (!hasLog) {
            unlogged.add(prayer);
            // Default: user prayed but forgot to log (optimistic)
            final prayerType = prayer.prayerType;
            if (prayerType != null) {
              prayerStatuses[prayerType] = PrayerStatus.prayed;
              prayerTimings[prayerType] = PrayerTimingQuality.onTime;
            }
          }
        }
      }

      missedPrayers.value = unlogged;
    } catch (e) {
      print('Error loading missed prayers: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Set prayer status (prayed/missed)
  void setPrayerStatus(PrayerName prayer, PrayerStatus status) {
    prayerStatuses[prayer] = status;

    // If missed, set timing to missed
    if (status == PrayerStatus.missed) {
      prayerTimings[prayer] = PrayerTimingQuality.missed;
    } else {
      // Default to on time
      prayerTimings[prayer] = PrayerTimingQuality.onTime;
    }
  }

  /// Set prayer timing quality
  void setPrayerTiming(PrayerName prayer, PrayerTimingQuality timing) {
    prayerTimings[prayer] = timing;
  }

  /// Save all prayers
  Future<void> saveAll() async {
    try {
      isSaving.value = true;

      final userId = _authService.currentUser.value?.uid ?? '';

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

        if (status == PrayerStatus.missed) {
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
          note: status == PrayerStatus.missed
              ? 'Logged as missed'
              : 'Batch logged',
        );

        // Save to Firestore
        await _firestoreService.addPrayerLog(userId, log.toFirestore());
      }

      // Show success message
      Get.snackbar(
        'success'.tr,
        'prayers_saved'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );

      // Go back
      Get.back();
    } catch (e) {
      print('Error saving prayers: $e');
      Get.snackbar(
        'error'.tr,
        'error_saving_prayers'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
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

/// Prayer status enum
enum PrayerStatus { prayed, missed }
