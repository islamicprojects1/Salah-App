import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:salah/core/services/auth_service.dart';
import 'package:salah/core/services/prayer_time_service.dart';
import 'package:salah/core/services/storage_service.dart';
import 'package:salah/data/models/prayer_log_model.dart';
import 'package:salah/data/models/prayer_time_model.dart';
import 'package:salah/data/repositories/prayer_repository.dart';

/// Smart Logging Service
/// يدير تسجيل الصلوات بذكاء مع دعم الـ batch logging والـ offline mode
class SmartLoggingService extends GetxService {
  // ============================================================
  // DEPENDENCIES
  // ============================================================

  late final AuthService _authService;
  late final PrayerTimeService _prayerTimeService;
  late final StorageService _storageService;
  late final PrayerRepository _prayerRepo;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  Future<SmartLoggingService> init() async {
    _authService = Get.find<AuthService>();
    _prayerTimeService = Get.find<PrayerTimeService>();
    _storageService = Get.find<StorageService>();
    _prayerRepo = Get.find<PrayerRepository>();
    return this;
  }

  // ============================================================
  // QUICK LOG (ONE TAP)
  // ============================================================

  /// Quick log prayer with automatic time estimation
  Future<bool> quickLogPrayer({
    required PrayerName prayer,
    PrayerTimingQuality? timing,
  }) async {
    try {
      final userId = _authService.currentUser.value?.uid;
      if (userId == null) return false;

      // Get prayer time
      final prayerTime = _prayerTimeService.getPrayerTime(prayer);
      if (prayerTime == null) return false;

      // Auto-determine timing if not provided
      final actualTiming = timing ?? _autoDetectTiming(prayer, prayerTime);

      // Calculate prayed time based on timing
      final prayedAt = _calculatePrayedAt(prayer, prayerTime, actualTiming);

      // Create log
      final log = PrayerLogModel(
        id: '',
        oderId: userId,
        prayer: prayer,
        prayedAt: prayedAt,
        adhanTime: prayerTime,
        quality: _convertToLegacyQuality(actualTiming),
        timingQuality: actualTiming,
        note: 'Quick logged',
      );

      // Save using repository
      await _savePrayerLog(userId, log);

      // Update local cache
      await _updateLocalCache(prayer);

      return true;
    } catch (e) {
      print('SmartLoggingService: Error quick logging prayer: $e');
      return false;
    }
  }

  // ============================================================
  // BATCH LOGGING
  // ============================================================

  /// Batch log multiple prayers at once
  Future<BatchLogResult> batchLogPrayers({
    required List<PrayerLogRequest> requests,
  }) async {
    final results = <PrayerName, bool>{};
    int successCount = 0;
    int failCount = 0;

    for (final request in requests) {
      final success = await _logSinglePrayer(request);
      results[request.prayer] = success;
      if (success) {
        successCount++;
      } else {
        failCount++;
      }
    }

    return BatchLogResult(
      results: results,
      successCount: successCount,
      failCount: failCount,
    );
  }

  Future<bool> _logSinglePrayer(PrayerLogRequest request) async {
    try {
      final userId = _authService.currentUser.value?.uid;
      if (userId == null) return false;

      final log = PrayerLogModel(
        id: '',
        oderId: userId,
        prayer: request.prayer,
        prayedAt: request.prayedAt,
        adhanTime: request.adhanTime,
        quality: _convertToLegacyQuality(request.timing),
        timingQuality: request.timing,
        note: request.note ?? 'Batch logged',
      );

      await _savePrayerLog(userId, log);
      return true;
    } catch (e) {
      print('SmartLoggingService: Error logging ${request.prayer}: $e');
      return false;
    }
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  /// Save prayer log using repository
  Future<void> _savePrayerLog(String userId, PrayerLogModel log) async {
    await _prayerRepo.addPrayerLog(userId: userId, log: log);
  }

  // ============================================================
  // SMART DETECTION
  // ============================================================

  /// Auto-detect prayer timing based on current time
  PrayerTimingQuality _autoDetectTiming(PrayerName prayer, DateTime adhanTime) {
    final now = DateTime.now();
    final minutesSinceAdhan = now.difference(adhanTime).inMinutes;

    // Get next prayer time for range calculation
    final prayerTimes = _prayerTimeService.prayerTimes.value;
    if (prayerTimes == null) return PrayerTimingQuality.onTime;

    final range = PrayerTimeRange.fromPrayerTimes(
      prayerTimes: prayerTimes,
      prayer: prayer,
    );
    if (range == null) return PrayerTimingQuality.onTime;

    final totalMinutes = range.totalMinutes;

    // Calculate timing based on when they're logging
    if (minutesSinceAdhan <= 10) {
      return PrayerTimingQuality.veryEarly;
    } else if (minutesSinceAdhan <= totalMinutes * 0.3) {
      return PrayerTimingQuality.early;
    } else if (minutesSinceAdhan <= totalMinutes * 0.6) {
      return PrayerTimingQuality.onTime;
    } else if (minutesSinceAdhan <= totalMinutes * 0.9) {
      return PrayerTimingQuality.late;
    } else if (minutesSinceAdhan <= totalMinutes) {
      return PrayerTimingQuality.veryLate;
    } else {
      return PrayerTimingQuality.missed;
    }
  }

  /// Calculate actual prayed time based on timing quality
  DateTime _calculatePrayedAt(
    PrayerName prayer,
    DateTime adhanTime,
    PrayerTimingQuality timing,
  ) {
    final prayerTimes = _prayerTimeService.prayerTimes.value;
    if (prayerTimes == null) return DateTime.now();

    final range = PrayerTimeRange.fromPrayerTimes(
      prayerTimes: prayerTimes,
      prayer: prayer,
    );

    if (range == null) return DateTime.now();

    return range.getSuggestedTime(timing);
  }

  // ============================================================
  // UNLOGGED PRAYERS
  // ============================================================

  /// Get list of unlogged prayers for today
  Future<List<UnloggedPrayer>> getUnloggedPrayers() async {
    try {
      final userId = _authService.currentUser.value?.uid;
      if (userId == null) return [];

      // Get today's prayers that have passed
      final now = DateTime.now();
      final allPrayers = _prayerTimeService
          .getTodayPrayers()
          .where((p) => p.prayerType != PrayerName.sunrise)
          .where((p) => p.dateTime.isBefore(now))
          .toList();

      if (allPrayers.isEmpty) return [];

      // Get today's logs
      final today = DateTime(now.year, now.month, now.day);

      // Use repository to get logs (offline compatible)
      final logs = await _prayerRepo.getPrayerLogsInRange(
        userId: userId,
        startDate: today,
        endDate: today.add(const Duration(days: 1)),
      );

      // Find unlogged
      final unlogged = <UnloggedPrayer>[];
      for (final prayer in allPrayers) {
        final prayerType = prayer.prayerType;
        if (prayerType == null) continue;

        final hasLog = logs.any((log) => log.prayer == prayerType);
        if (!hasLog) {
          unlogged.add(
            UnloggedPrayer(
              prayerType: prayerType,
              adhanTime: prayer.dateTime,
              name: prayer.name,
              minutesSinceAdhan: now.difference(prayer.dateTime).inMinutes,
            ),
          );
        }
      }

      return unlogged;
    } catch (e) {
      print('SmartLoggingService: Error getting unlogged prayers: $e');
      return [];
    }
  }

  /// Check if there are unlogged prayers
  Future<bool> hasUnloggedPrayers() async {
    final unlogged = await getUnloggedPrayers();
    return unlogged.isNotEmpty;
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  Future<void> _updateLocalCache(PrayerName prayer) async {
    final cachedPrayers = _storageService.getCachedTodayPrayers();
    if (!cachedPrayers.contains(prayer.name)) {
      cachedPrayers.add(prayer.name);
      await _storageService.cacheTodayPrayers(cachedPrayers);
    }
  }

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
}

// ============================================================
// DATA CLASSES
// ============================================================

/// Request for logging a single prayer
class PrayerLogRequest {
  final PrayerName prayer;
  final DateTime adhanTime;
  final DateTime prayedAt;
  final PrayerTimingQuality timing;
  final String? note;

  PrayerLogRequest({
    required this.prayer,
    required this.adhanTime,
    required this.prayedAt,
    required this.timing,
    this.note,
  });
}

/// Result of batch logging
class BatchLogResult {
  final Map<PrayerName, bool> results;
  final int successCount;
  final int failCount;

  BatchLogResult({
    required this.results,
    required this.successCount,
    required this.failCount,
  });

  bool get allSuccess => failCount == 0;
}

/// Unlogged prayer info
class UnloggedPrayer {
  final PrayerName prayerType;
  final DateTime adhanTime;
  final String name;
  final int minutesSinceAdhan;

  UnloggedPrayer({
    required this.prayerType,
    required this.adhanTime,
    required this.name,
    required this.minutesSinceAdhan,
  });

  bool get isUrgent => minutesSinceAdhan > 120; // More than 2 hours
}
