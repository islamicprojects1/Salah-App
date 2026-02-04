import 'package:get/get.dart';
import 'package:adhan/adhan.dart';
import 'package:salah/core/services/location_service.dart';
import 'package:salah/data/models/prayer_time_model.dart';
import 'package:salah/data/models/prayer_log_model.dart';

/// Service for calculating prayer times using Adhan package
  // ============================================================
  // ENUMS
  // ============================================================

  /// Prayer timing quality based on when prayer was logged
  /// relative to the prayer time window
enum PrayerTimingQuality {
  veryEarly,   // 🟩 Dark Green - Beginning of time (0-15%)
  early,       // 🟢 Light Green - Early in time (15-40%)
  onTime,      // 🟡 Yellow - Middle of time (40-70%)
  late,        // 🟠 Orange - Late in time (70-90%)
  veryLate,    // 🔴 Light Red - Very late (90-100%)
  missed,      // ⚫ Dark Red - After time ended
  notYet,      // ⚪ White/Gray - Time hasn't come yet
}

/// Legacy enum for backward compatibility
/// Will be gradually replaced with PrayerTimingQuality
enum PrayerQuality { 
  early,    // Within 15 minutes of adhan (green)
  onTime,   // Within 30 minutes of adhan (yellow/gold)
  late,     // After 30 minutes (orange)
  missed,   // Not prayed before next prayer
}

/// Prayer names
enum PrayerName {
  fajr,
  sunrise,
  dhuhr,
  asr,
  maghrib,
  isha,
}

class PrayerTimeService extends GetxService {
  // ============================================================
  // DEPENDENCIES
  // ============================================================
  
  late final LocationService _locationService;

  // ============================================================
  // OBSERVABLE STATE
  // ============================================================
  
  final prayerTimes = Rxn<PrayerTimes>();
  final qiblaDirection = 0.0.obs;
  final isLoading = false.obs;

  // ============================================================
  // CALCULATION PARAMETERS
  // ============================================================
  
  /// Default calculation method (Muslim World League)
  CalculationParameters get _calculationParams {
    final params = CalculationMethod.muslim_world_league.getParameters();
    params.madhab = Madhab.shafi; // Can be changed based on user preference
    return params;
  }

  // ============================================================
  // INITIALIZATION
  // ============================================================
  
  /// Initialize the service
  Future<PrayerTimeService> init() async {
    // Avoid double initialization or finding self if not registered yet in early stages
    // typically put dependencies in Get.put/lazyPut
    if (Get.isRegistered<LocationService>()) {
       _locationService = Get.find<LocationService>();
    } else {
       // Ideally LocationService should be initialized before PrayerTimeService
       // For safety:
       _locationService = Get.put(LocationService());
    }
    
    await calculatePrayerTimes();
    return this;
  }

  // ============================================================
  // PRAYER TIMES CALCULATION
  // ============================================================
  
  /// Calculate prayer times for today
  Future<void> calculatePrayerTimes() async {
    try {
      isLoading.value = true;
      
      // Get location
      final position = _locationService.currentPosition.value;
      if (position == null) {
        await _locationService.getCurrentLocation();
      }
      
      final lat = _locationService.latitude;
      final lng = _locationService.longitude;
      
      if (lat == null || lng == null) {
        return;
      }
      
      // Create coordinates
      final coordinates = Coordinates(lat, lng);
      
      // Calculate prayer times
      final now = DateTime.now();
      final dateComponents = DateComponents.from(now);
      
      prayerTimes.value = PrayerTimes(
        coordinates,
        dateComponents,
        _calculationParams,
      );
      
      // Calculate Qibla direction
      final qibla = Qibla(coordinates);
      qiblaDirection.value = qibla.direction;
      
    } catch (e) {
      print('Error calculating prayer times: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Get prayer times for today as a List of PrayerTimeModel
  List<PrayerTimeModel> getTodayPrayers() {
    final times = prayerTimes.value;
    if (times == null) {
        // Return mock/empty if loading to avoid null errors in UI
        return []; 
    }

    return [
      PrayerTimeModel(name: 'الفجر', dateTime: times.fajr, prayerType: PrayerName.fajr),
      PrayerTimeModel(name: 'الشروق', dateTime: times.sunrise, prayerType: PrayerName.sunrise, isNotificationEnabled: false),
      PrayerTimeModel(name: 'الظهر', dateTime: times.dhuhr, prayerType: PrayerName.dhuhr),
      PrayerTimeModel(name: 'العصر', dateTime: times.asr, prayerType: PrayerName.asr),
      PrayerTimeModel(name: 'المغرب', dateTime: times.maghrib, prayerType: PrayerName.maghrib),
      PrayerTimeModel(name: 'العشاء', dateTime: times.isha, prayerType: PrayerName.isha),
    ];
  }
  
  /// Get the next prayer time after the given time
  PrayerTimeModel? getNextPrayer([DateTime? afterTime]) {
    final prayers = getTodayPrayers()
        .where((p) => p.prayerType != PrayerName.sunrise)
        .toList();
    final now = afterTime ?? DateTime.now();
    
    try {
      return prayers.firstWhere((p) => p.dateTime.isAfter(now));
    } catch (_) {
      // If no prayer found today, return first prayer of tomorrow
      // For now, return null
      return null;
    }
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
    
    if (percentage <= 15) return PrayerTimingQuality.veryEarly;  // 0-15%
    if (percentage <= 40) return PrayerTimingQuality.early;      // 15-40%
    if (percentage <= 70) return PrayerTimingQuality.onTime;     // 40-70%
    if (percentage <= 90) return PrayerTimingQuality.late;       // 70-90%
    return PrayerTimingQuality.veryLate;                         // 90-100%
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
        final midnight = DateTime(
          adhan.year,
          adhan.month,
          adhan.day + 1,
        );
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

