import 'package:adhan/adhan.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_disposable.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/helpers/prayer_names.dart';
import 'package:salah/core/services/database_helper.dart';
import 'package:salah/core/services/location_service.dart';
import 'package:salah/core/services/notification_service.dart';
import 'package:salah/core/services/storage_service.dart';
import 'package:salah/data/models/prayer_time_model.dart';

import 'package:salah/core/services/auth_service.dart';

/// Service for calculating prayer times using Adhan package
class PrayerTimeService extends GetxService {
  // ============================================================
  // DEPENDENCIES
  // ============================================================

  late final LocationService _locationService;
  late final StorageService _storageService;

  // ============================================================
  // OBSERVABLE STATE
  // ============================================================

  final prayerTimes = Rxn<PrayerTimes>();
  final qiblaDirection = 0.0.obs;
  final isLoading = false.obs;
  PrayerTimeModel? _tomorrowFajr;
  List<PrayerTimeModel>? _cachedTodayList;

  // User preferences
  final currentCalculationMethod = Rx<CalculationMethod>(
    CalculationMethod.muslim_world_league,
  );
  final currentMadhab = Rx<Madhab>(Madhab.shafi);

  // ============================================================
  // CALCULATION PARAMETERS
  // ============================================================

  /// Calculation parameters based on user preferences
  CalculationParameters get _calculationParams {
    final params = currentCalculationMethod.value.getParameters();
    params.madhab = currentMadhab.value;
    return params;
  }

  /// Update calculation method and recalculate
  Future<void> setCalculationMethod(CalculationMethod method) async {
    currentCalculationMethod.value = method;
    await _storageService.write('prayer_calculation_method', method.name);
    await calculatePrayerTimes();
  }

  /// Update madhab and recalculate
  Future<void> setMadhab(Madhab madhab) async {
    currentMadhab.value = madhab;
    await _storageService.write('prayer_madhab', madhab.name);
    await calculatePrayerTimes();
  }

  /// Load saved preferences
  void _loadPreferences() {
    final methodName = _storageService.read<String>(
      'prayer_calculation_method',
    );
    if (methodName != null) {
      currentCalculationMethod.value = _parseCalculationMethod(methodName);
    }

    final madhabName = _storageService.read<String>('prayer_madhab');
    if (madhabName != null) {
      currentMadhab.value = madhabName == 'hanafi'
          ? Madhab.hanafi
          : Madhab.shafi;
    }
  }

  CalculationMethod _parseCalculationMethod(String name) {
    switch (name) {
      case 'muslim_world_league':
        return CalculationMethod.muslim_world_league;
      case 'egyptian':
        return CalculationMethod.egyptian;
      case 'karachi':
        return CalculationMethod.karachi;
      case 'umm_al_qura':
        return CalculationMethod.umm_al_qura;
      case 'dubai':
        return CalculationMethod.dubai;
      case 'qatar':
        return CalculationMethod.qatar;
      case 'kuwait':
        return CalculationMethod.kuwait;
      case 'moon_sighting_committee':
        return CalculationMethod.moon_sighting_committee;
      case 'singapore':
        return CalculationMethod.singapore;
      case 'turkey':
        return CalculationMethod.turkey;
      case 'tehran':
        return CalculationMethod.tehran;
      case 'north_america':
        return CalculationMethod.north_america;
      default:
        return CalculationMethod.muslim_world_league;
    }
  }

  // ============================================================
  // INITIALIZATION
  bool _isInitialized = false;

  /// Initialize the service
  Future<PrayerTimeService> init() async {
    if (_isInitialized) return this;
    _isInitialized = true;
    // Initialize dependencies
    if (Get.isRegistered<LocationService>()) {
      _locationService = Get.find<LocationService>();
    } else {
      _locationService = Get.put(LocationService());
    }

    _storageService = Get.find<StorageService>();

    // Load user preferences
    _loadPreferences();

    await calculatePrayerTimes();
    return this;
  }

  // ============================================================
  // PRAYER TIMES CALCULATION
  // ============================================================

  /// Calculate prayer times for today; uses cache when available and same location.
  Future<void> calculatePrayerTimes() async {
    try {
      isLoading.value = true;
      _tomorrowFajr = null;
      _cachedTodayList = null;

      final position = _locationService.currentPosition.value;
      if (position == null) await _locationService.getCurrentLocation();

      final lat = _locationService.latitude;
      final lng = _locationService.longitude;
      if (lat == null || lng == null) return;

      final now = DateTime.now();
      final coordinates = Coordinates(lat, lng);

      if (Get.isRegistered<DatabaseHelper>()) {
        final db = Get.find<DatabaseHelper>();
        final cached = await db.getCachedPrayerTimes(now);
        if (cached != null &&
            _nullableDouble(cached['latitude']) == lat &&
            _nullableDouble(cached['longitude']) == lng) {
          final fromCache = _modelsFromCache(cached);
          if (fromCache.isNotEmpty) {
            _cachedTodayList = fromCache;
            if (now.isAfter(fromCache.last.dateTime)) {
              _tomorrowFajr = await _getFirstPrayerForDate(
                now.add(const Duration(days: 1)),
              );
            }
            return;
          }
        }
      }

      final dateComponents = DateComponents.from(now);
      prayerTimes.value = PrayerTimes(
        coordinates,
        dateComponents,
        _calculationParams,
      );
      if (Get.isRegistered<DatabaseHelper>()) {
        await _saveToCache(now, prayerTimes.value!, lat, lng);
      }
      final qibla = Qibla(coordinates);
      qiblaDirection.value = qibla.direction;
      if (now.isAfter(prayerTimes.value!.isha)) {
        _tomorrowFajr = await _getFirstPrayerForDate(
          now.add(const Duration(days: 1)),
        );
      }
    } catch (_) {
      // Prayer times calculation failed
    } finally {
      isLoading.value = false;
    }
  }

  double? _nullableDouble(dynamic v) =>
      v == null ? null : (v is double ? v : (v is int ? v.toDouble() : null));

  List<PrayerTimeModel> _modelsFromCache(Map<String, dynamic> c) {
    final list = <PrayerTimeModel>[];
    for (final p in [
      PrayerName.fajr,
      PrayerName.sunrise,
      PrayerName.dhuhr,
      PrayerName.asr,
      PrayerName.maghrib,
      PrayerName.isha,
    ]) {
      final s = c[p.name] as String?;
      if (s == null) continue;
      list.add(
        PrayerTimeModel(
          name: PrayerNames.displayName(p),
          dateTime: DateTime.parse(s),
          prayerType: p,
          isNotificationEnabled: p != PrayerName.sunrise,
        ),
      );
    }
    return list;
  }

  Future<void> _saveToCache(
    DateTime date,
    PrayerTimes times,
    double lat,
    double lng,
  ) async {
    if (!Get.isRegistered<DatabaseHelper>()) return;
    final db = Get.find<DatabaseHelper>();
    await db.cachePrayerTimes(
      date: date,
      prayerTimes: {
        'fajr': times.fajr.toIso8601String(),
        'sunrise': times.sunrise.toIso8601String(),
        'dhuhr': times.dhuhr.toIso8601String(),
        'asr': times.asr.toIso8601String(),
        'maghrib': times.maghrib.toIso8601String(),
        'isha': times.isha.toIso8601String(),
      },
      latitude: lat,
      longitude: lng,
    );
  }

  /// Returns first prayer (Fajr) for the given date; uses cache or computes.
  Future<PrayerTimeModel?> _getFirstPrayerForDate(DateTime date) async {
    final list = await getPrayersForDate(date);
    return list.isNotEmpty ? list.first : null;
  }

  /// Get prayer times for a date (cache-first, then compute and cache).
  Future<List<PrayerTimeModel>> getPrayersForDate(DateTime date) async {
    final lat = _locationService.latitude;
    final lng = _locationService.longitude;
    if (lat == null || lng == null) return [];

    if (Get.isRegistered<DatabaseHelper>()) {
      final db = Get.find<DatabaseHelper>();
      final cached = await db.getCachedPrayerTimes(date);
      if (cached != null) return _modelsFromCache(cached);
    }

    final coordinates = Coordinates(lat, lng);
    final dateComponents = DateComponents.from(date);
    final times = PrayerTimes(coordinates, dateComponents, _calculationParams);
    if (Get.isRegistered<DatabaseHelper>()) {
      await _saveToCache(date, times, lat, lng);
    }
    return _timesToModels(times);
  }

  List<PrayerTimeModel> _timesToModels(PrayerTimes times) {
    // Apply manual offsets
    Map<String, int> offsets = {};
    if (Get.isRegistered<StorageService>()) {
      final storedOffsets = _storageService.read<Map<String, dynamic>>('prayer_offsets');
      if (storedOffsets != null) {
        offsets = storedOffsets.map((key, value) => MapEntry(key, value as int));
      }
    }

    DateTime adjust(DateTime dt, String key) {
      final offset = offsets[key] ?? 0;
      return dt.add(Duration(minutes: offset));
    }

    return [
      PrayerTimeModel(
        name: PrayerNames.displayName(PrayerName.fajr),
        dateTime: adjust(times.fajr, 'fajr'),
        prayerType: PrayerName.fajr,
      ),
      PrayerTimeModel(
        name: PrayerNames.displayName(PrayerName.sunrise),
        dateTime: adjust(times.sunrise, 'sunrise'),
        prayerType: PrayerName.sunrise,
        isNotificationEnabled: false,
      ),
      PrayerTimeModel(
        name: PrayerNames.displayName(PrayerName.dhuhr),
        dateTime: adjust(times.dhuhr, 'dhuhr'),
        prayerType: PrayerName.dhuhr,
      ),
      PrayerTimeModel(
        name: PrayerNames.displayName(PrayerName.asr),
        dateTime: adjust(times.asr, 'asr'),
        prayerType: PrayerName.asr,
      ),
      PrayerTimeModel(
        name: PrayerNames.displayName(PrayerName.maghrib),
        dateTime: adjust(times.maghrib, 'maghrib'),
        prayerType: PrayerName.maghrib,
      ),
      PrayerTimeModel(
        name: PrayerNames.displayName(PrayerName.isha),
        dateTime: adjust(times.isha, 'isha'),
        prayerType: PrayerName.isha,
      ),
    ];
  }

  /// Get prayer times for today (from cache or last calculation); includes tomorrow's Fajr when after Isha.
  List<PrayerTimeModel> getTodayPrayers() {
    if (_cachedTodayList != null) {
      final list = List<PrayerTimeModel>.from(_cachedTodayList!);
      if (_tomorrowFajr != null) list.add(_tomorrowFajr!);
      return list;
    }
    final times = prayerTimes.value;
    if (times == null) return [];
    final list = _timesToModels(times);
    if (_tomorrowFajr != null) list.add(_tomorrowFajr!);
    return list;
  }

  /// Get specific prayer time
  DateTime? getPrayerTime(PrayerName prayer) {
    final times = prayerTimes.value;
    if (times == null) return null;

    switch (prayer) {
      case PrayerName.fajr:
        return times.fajr;
      case PrayerName.sunrise:
        return times.sunrise;
      case PrayerName.dhuhr:
        return times.dhuhr;
      case PrayerName.asr:
        return times.asr;
      case PrayerName.maghrib:
        return times.maghrib;
      case PrayerName.isha:
        return times.isha;
    }
  }

  /// Called when location/timezone changes — recalculates and reschedules.
  Future<void> onLocationChanged() async {
    // Invalidate caches
    _cachedTodayList = null;
    _tomorrowFajr = null;
    prayerTimes.value = null;

    // Recalculate
    await calculatePrayerTimes();

    // Reschedule notifications with new prayer times
    if (Get.isRegistered<NotificationService>()) {
      Get.find<NotificationService>().rescheduleAllForToday();
    }
  }

  /// Next prayer after [afterTime]; includes tomorrow's Fajr when after Isha.
  PrayerTimeModel? getNextPrayer([DateTime? afterTime]) {
    final prayers = getTodayPrayers()
        .where((p) => p.prayerType != PrayerName.sunrise)
        .toList();
    final now = afterTime ?? DateTime.now();
    try {
      return prayers.firstWhere((p) => p.dateTime.isAfter(now));
    } catch (_) {
      return null;
    }
  }

  /// Current prayer (the one whose time has passed but next hasn't started);
  Rx<PrayerTimeModel?> get currentPrayer {
    final now = DateTime.now();
    final today = getTodayPrayers();
    final prayers = today
        .where((p) => p.prayerType != PrayerName.sunrise)
        .toList();

    // Sort by time
    prayers.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    PrayerTimeModel? current;
    for (var i = 0; i < prayers.length; i++) {
      if (prayers[i].dateTime.isBefore(now)) {
        current = prayers[i];
      } else {
        break;
      }
    }
    return Rx<PrayerTimeModel?>(current);
  }

  /// Next prayer (the same as getNextPrayer but as a reactive property);
  Rx<PrayerTimeModel?> get nextPrayer {
    return Rx<PrayerTimeModel?>(getNextPrayer());
  }
}

// ============================================================
// PRAYER TIME RANGE
// ============================================================

/// Represents the time range for a prayer (from adhan to next prayer)
/// Used to calculate prayer timing quality
class PrayerTimeRange {
  final DateTime adhanTime;
  final DateTime nextPrayerTime;
  final PrayerName prayerName;

  const PrayerTimeRange({
    required this.adhanTime,
    required this.nextPrayerTime,
    required this.prayerName,
  });

  /// Total duration of the prayer time window (in minutes)
  int get totalMinutes => nextPrayerTime.difference(adhanTime).inMinutes;

  /// Calculate prayer timing quality based on when prayer was logged
  PrayerTimingQuality calculateQuality(DateTime prayedAt) {
    final elapsedMinutes = prayedAt.difference(adhanTime).inMinutes;

    // Prayer hasn't started yet
    if (elapsedMinutes < 0) {
      return PrayerTimingQuality.notYet;
    }

    // Missed (after next prayer time)
    if (elapsedMinutes > totalMinutes) {
      return PrayerTimingQuality.missed;
    }

    // Calculate percentage
    final percentage = (elapsedMinutes / totalMinutes) * 100;

    if (percentage <= 15) return PrayerTimingQuality.veryEarly; // 0-15%
    if (percentage <= 40) return PrayerTimingQuality.early; // 15-40%
    if (percentage <= 70) return PrayerTimingQuality.onTime; // 40-70%
    if (percentage <= 90) return PrayerTimingQuality.late; // 70-90%
    return PrayerTimingQuality.veryLate; // 90-100%
  }

  /// Get suggested prayer time for a given quality
  DateTime getSuggestedTime(PrayerTimingQuality quality) {
    switch (quality) {
      case PrayerTimingQuality.veryEarly:
        // 5 minutes after adhan
        return adhanTime.add(Duration(minutes: 5));
      case PrayerTimingQuality.early:
        // 25% of the way through
        return adhanTime.add(Duration(minutes: (totalMinutes * 0.25).round()));
      case PrayerTimingQuality.onTime:
        // 50% of the way through (middle)
        return adhanTime.add(Duration(minutes: (totalMinutes * 0.5).round()));
      case PrayerTimingQuality.late:
        // 80% of the way through
        return adhanTime.add(Duration(minutes: (totalMinutes * 0.8).round()));
      case PrayerTimingQuality.veryLate:
        // 95% of the way through
        return adhanTime.add(Duration(minutes: (totalMinutes * 0.95).round()));
      default:
        // Default to current time
        return DateTime.now();
    }
  }

  /// Create a PrayerTimeRange from prayer times
  static PrayerTimeRange? fromPrayerTimes({
    required PrayerTimes prayerTimes,
    required PrayerName prayer,
  }) {
    DateTime adhan;
    DateTime nextPrayer;

    switch (prayer) {
      case PrayerName.fajr:
        adhan = prayerTimes.fajr;
        nextPrayer = prayerTimes.sunrise;
        break;
      case PrayerName.dhuhr:
        adhan = prayerTimes.dhuhr;
        nextPrayer = prayerTimes.asr;
        break;
      case PrayerName.asr:
        adhan = prayerTimes.asr;
        nextPrayer = prayerTimes.maghrib;
        break;
      case PrayerName.maghrib:
        adhan = prayerTimes.maghrib;
        nextPrayer = prayerTimes.isha;
        break;
      case PrayerName.isha:
        adhan = prayerTimes.isha;
        // Isha ends at midnight (or Fajr next day, but for simplicity use midnight)
        final midnight = DateTime(adhan.year, adhan.month, adhan.day + 1);
        nextPrayer = midnight;
        break;
      case PrayerName.sunrise:
        // Sunrise is not a prayer time, return null
        return null;
    }

    return PrayerTimeRange(
      adhanTime: adhan,
      nextPrayerTime: nextPrayer,
      prayerName: prayer,
    );
  }
}
