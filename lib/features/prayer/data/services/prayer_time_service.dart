import 'package:get/get.dart';
import 'package:salah/core/constants/aladhan_constants.dart';
import 'package:salah/core/di/injection_container.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/helpers/prayer_names.dart';
import 'package:salah/core/services/connectivity_service.dart';
import 'package:salah/core/services/database_helper.dart';
import 'package:salah/core/services/location_service.dart';
import 'package:salah/core/services/storage_service.dart';
import 'package:salah/features/prayer/data/models/prayer_time_model.dart'
    show PrayerTimeModel;
import 'package:salah/features/prayer/data/services/aladhan_api_service.dart';
import 'package:salah/features/prayer/data/services/notification_service.dart';

/// Service for prayer times using Aladhan API.
/// Method is automatic per country (from LocationService.countryName).
class PrayerTimeService extends GetxService {
  // ============================================================
  // DEPENDENCIES
  // ============================================================

  late final LocationService _locationService;
  late final StorageService _storageService;
  late final AladhanApiService _aladhanApi;

  // ============================================================
  // OBSERVABLE STATE
  // ============================================================

  final qiblaDirection = 0.0.obs;
  final isLoading = false.obs;
  PrayerTimeModel? _tomorrowFajr;
  List<PrayerTimeModel>? _cachedTodayList;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  bool _isInitialized = false;

  Future<PrayerTimeService> init() async {
    if (_isInitialized) return this;
    _isInitialized = true;
    _locationService = sl<LocationService>();
    _storageService = sl<StorageService>();
    _aladhanApi = AladhanApiService();
    await calculatePrayerTimes();
    return this;
  }

  // ============================================================
  // PRAYER TIMES CALCULATION
  // ============================================================

  /// Calculate prayer times for today; uses cache when available, then Aladhan API.
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

      // 1. Try cache first
      if (sl.isRegistered<DatabaseHelper>()) {
        final db = sl<DatabaseHelper>();
        final cached = await db.getCachedPrayerTimes(now);
        if (cached != null &&
            _nullableDouble(cached['latitude']) == lat &&
            _nullableDouble(cached['longitude']) == lng) {
          final fromCache = _modelsFromCache(cached);
          if (fromCache.isNotEmpty) {
            _cachedTodayList = _applyOffsets(fromCache);
            _fetchQiblaIfOnline(lat, lng);
            if (now.isAfter(fromCache.last.dateTime)) {
              _tomorrowFajr = await _getFirstPrayerForDate(
                now.add(const Duration(days: 1)),
              );
            }
            return;
          }
        }
      }

      // 2. Fetch from Aladhan API when online
      final isOnline = sl<ConnectivityService>().isConnected.value;
      if (isOnline) {
        final method =
            getAladhanMethodForCountry(_locationService.countryName.value);
        final list = await _aladhanApi.fetchTimingsForDate(
          latitude: lat,
          longitude: lng,
          date: now,
          method: method,
        );
        if (list.isNotEmpty) {
          final adjusted = _applyOffsets(list);
          _cachedTodayList = adjusted;
          if (sl.isRegistered<DatabaseHelper>()) {
            await _saveToCache(now, adjusted, lat, lng);
          }
          _fetchQiblaIfOnline(lat, lng);
          if (now.isAfter(adjusted.last.dateTime)) {
            _tomorrowFajr =
                await _getFirstPrayerForDate(now.add(const Duration(days: 1)));
          }
          return;
        }
      }
    } catch (_) {
      // Prayer times calculation failed
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchQiblaIfOnline(double lat, double lng) async {
    if (!sl<ConnectivityService>().isConnected.value) return;
    final dir = await _aladhanApi.fetchQiblaDirection(lat, lng);
    if (dir != null) qiblaDirection.value = dir;
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
    list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return list;
  }

  List<PrayerTimeModel> _applyOffsets(List<PrayerTimeModel> list) {
    Map<String, int> offsets = {};
    final storedOffsets =
        _storageService.read<Map<String, dynamic>>('prayer_offsets');
    if (storedOffsets != null) {
      offsets =
          storedOffsets.map((key, value) => MapEntry(key, value as int));
    }
    if (offsets.isEmpty) return list;

    return list.map((p) {
      final key = p.prayerType.name;
      final offset = offsets[key] ?? 0;
      if (offset == 0) return p;
      return PrayerTimeModel(
        name: p.name,
        dateTime: p.dateTime.add(Duration(minutes: offset)),
        prayerType: p.prayerType,
        isNotificationEnabled: p.isNotificationEnabled,
      );
    }).toList();
  }

  Future<void> _saveToCache(
    DateTime date,
    List<PrayerTimeModel> list,
    double lat,
    double lng,
  ) async {
    if (!sl.isRegistered<DatabaseHelper>()) return;
    final db = sl<DatabaseHelper>();
    final map = <String, String>{};
    for (final p in list) {
      map[p.prayerType.name] = p.dateTime.toIso8601String();
    }
    await db.cachePrayerTimes(
      date: date,
      prayerTimes: map,
      latitude: lat,
      longitude: lng,
    );
  }

  Future<PrayerTimeModel?> _getFirstPrayerForDate(DateTime date) async {
    final list = await getPrayersForDate(date);
    return list.isNotEmpty ? list.first : null;
  }

  /// Get prayer times for a date (cache-first, then API).
  Future<List<PrayerTimeModel>> getPrayersForDate(DateTime date) async {
    final lat = _locationService.latitude;
    final lng = _locationService.longitude;
    if (lat == null || lng == null) return [];

    if (sl.isRegistered<DatabaseHelper>()) {
      final db = sl<DatabaseHelper>();
      final cached = await db.getCachedPrayerTimes(date);
      if (cached != null) return _applyOffsets(_modelsFromCache(cached));
    }

    final isOnline = sl<ConnectivityService>().isConnected.value;
    if (isOnline) {
      final method =
          getAladhanMethodForCountry(_locationService.countryName.value);
      final list = await _aladhanApi.fetchTimingsForDate(
        latitude: lat,
        longitude: lng,
        date: date,
        method: method,
      );
      if (list.isNotEmpty) {
        final adjusted = _applyOffsets(list);
        if (sl.isRegistered<DatabaseHelper>()) {
          await _saveToCache(date, adjusted, lat, lng);
        }
        return adjusted;
      }
    }

    return [];
  }

  /// Get prayer times for today (from cache or last fetch); includes tomorrow's Fajr when after Isha.
  List<PrayerTimeModel> getTodayPrayers() {
    if (_cachedTodayList != null) {
      final list = List<PrayerTimeModel>.from(_cachedTodayList!);
      if (_tomorrowFajr != null) list.add(_tomorrowFajr!);
      return list;
    }
    return [];
  }

  /// Get specific prayer time
  DateTime? getPrayerTime(PrayerName prayer) {
    final list = getTodayPrayers();
    try {
      return list.firstWhere((p) => p.prayerType == prayer).dateTime;
    } catch (_) {
      return null;
    }
  }

  /// Called when location/timezone changes — recalculates and reschedules.
  Future<void> onLocationChanged() async {
    _cachedTodayList = null;
    _tomorrowFajr = null;
    await calculatePrayerTimes();
    if (sl.isRegistered<NotificationService>()) {
      sl<NotificationService>().rescheduleAllForToday();
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

  /// Current prayer (the one whose time has passed but next hasn't started).
  Rx<PrayerTimeModel?> get currentPrayer {
    final now = DateTime.now();
    final today = getTodayPrayers();
    final prayers = today
        .where((p) => p.prayerType != PrayerName.sunrise)
        .toList();
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

  /// Next prayer
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

  /// Calculate prayer timing quality based on when prayer was logged.
  /// 0–20% = أول الوقت, 20–60% = في الوقت, 60–90% = آخرها, 90–100% = آخر الدقائق.
  PrayerTimingQuality calculateQuality(DateTime prayedAt) {
    final elapsedMinutes = prayedAt.difference(adhanTime).inMinutes;

    if (elapsedMinutes < 0) return PrayerTimingQuality.notYet;
    if (elapsedMinutes > totalMinutes) return PrayerTimingQuality.missed;

    final percentage = totalMinutes > 0
        ? (elapsedMinutes / totalMinutes) * 100
        : 0.0;

    if (percentage <= 20) return PrayerTimingQuality.veryEarly;
    if (percentage <= 60) return PrayerTimingQuality.onTime;
    if (percentage <= 90) return PrayerTimingQuality.late;
    return PrayerTimingQuality.veryLate;
  }

  /// Get suggested prayer time for a given quality
  DateTime getSuggestedTime(PrayerTimingQuality quality) {
    switch (quality) {
      case PrayerTimingQuality.veryEarly:
        return adhanTime.add(const Duration(minutes: 5));
      case PrayerTimingQuality.early:
        return adhanTime.add(
          Duration(minutes: (totalMinutes * 0.25).round()),
        );
      case PrayerTimingQuality.onTime:
        return adhanTime.add(
          Duration(minutes: (totalMinutes * 0.5).round()),
        );
      case PrayerTimingQuality.late:
        return adhanTime.add(
          Duration(minutes: (totalMinutes * 0.8).round()),
        );
      case PrayerTimingQuality.veryLate:
        return adhanTime.add(
          Duration(minutes: (totalMinutes * 0.95).round()),
        );
      default:
        return DateTime.now();
    }
  }

  /// Create a PrayerTimeRange from prayer models
  static PrayerTimeRange? fromPrayerModels({
    required List<PrayerTimeModel> prayers,
    required PrayerName prayer,
  }) {
    final idx = prayers.indexWhere((p) => p.prayerType == prayer);
    if (idx < 0 || idx + 1 >= prayers.length) return null;
    final current = prayers[idx];
    final next = prayers[idx + 1];
    return PrayerTimeRange(
      adhanTime: current.dateTime,
      nextPrayerTime: next.dateTime,
      prayerName: prayer,
    );
  }
}
