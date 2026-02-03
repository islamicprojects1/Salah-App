import 'package:get/get.dart';
import 'package:adhan/adhan.dart';
import 'location_service.dart';

/// Prayer names enum
enum PrayerName { fajr, sunrise, dhuhr, asr, maghrib, isha }

/// Prayer quality based on timing
enum PrayerQuality { 
  early,    // Within 15 minutes of adhan (green)
  onTime,   // Within 30 minutes of adhan (yellow/gold)
  late,     // After 30 minutes (orange)
  missed,   // Not prayed before next prayer
}

/// Service for calculating prayer times using Adhan package
class PrayerTimeService extends GetxService {
  // ============================================================
  // DEPENDENCIES
  // ============================================================
  
  late final LocationService _locationService;

  // ============================================================
  // OBSERVABLE STATE
  // ============================================================
  
  final prayerTimes = Rxn<PrayerTimes>();
  final currentPrayer = Rxn<PrayerName>();
  final nextPrayer = Rxn<PrayerName>();
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
    _locationService = Get.find<LocationService>();
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
      
      // Update current and next prayer
      _updateCurrentAndNextPrayer();
    } catch (e) {
      // Handle error
    } finally {
      isLoading.value = false;
    }
  }

  /// Update current and next prayer
  void _updateCurrentAndNextPrayer() {
    final times = prayerTimes.value;
    if (times == null) return;
    
    final now = DateTime.now();
    
    // Determine current prayer
    if (now.isAfter(times.isha)) {
      currentPrayer.value = PrayerName.isha;
      nextPrayer.value = PrayerName.fajr; // Tomorrow's Fajr
    } else if (now.isAfter(times.maghrib)) {
      currentPrayer.value = PrayerName.maghrib;
      nextPrayer.value = PrayerName.isha;
    } else if (now.isAfter(times.asr)) {
      currentPrayer.value = PrayerName.asr;
      nextPrayer.value = PrayerName.maghrib;
    } else if (now.isAfter(times.dhuhr)) {
      currentPrayer.value = PrayerName.dhuhr;
      nextPrayer.value = PrayerName.asr;
    } else if (now.isAfter(times.sunrise)) {
      currentPrayer.value = PrayerName.sunrise;
      nextPrayer.value = PrayerName.dhuhr;
    } else if (now.isAfter(times.fajr)) {
      currentPrayer.value = PrayerName.fajr;
      nextPrayer.value = PrayerName.sunrise;
    } else {
      currentPrayer.value = null; // Before Fajr
      nextPrayer.value = PrayerName.fajr;
    }
  }

  // ============================================================
  // GETTERS
  // ============================================================
  
  /// Get Fajr time
  DateTime? get fajrTime => prayerTimes.value?.fajr;
  
  /// Get Sunrise time
  DateTime? get sunriseTime => prayerTimes.value?.sunrise;
  
  /// Get Dhuhr time
  DateTime? get dhuhrTime => prayerTimes.value?.dhuhr;
  
  /// Get Asr time
  DateTime? get asrTime => prayerTimes.value?.asr;
  
  /// Get Maghrib time
  DateTime? get maghribTime => prayerTimes.value?.maghrib;
  
  /// Get Isha time
  DateTime? get ishaTime => prayerTimes.value?.isha;

  /// Get time for specific prayer
  DateTime? getPrayerTime(PrayerName prayer) {
    switch (prayer) {
      case PrayerName.fajr:
        return fajrTime;
      case PrayerName.sunrise:
        return sunriseTime;
      case PrayerName.dhuhr:
        return dhuhrTime;
      case PrayerName.asr:
        return asrTime;
      case PrayerName.maghrib:
        return maghribTime;
      case PrayerName.isha:
        return ishaTime;
    }
  }

  /// Get next prayer time
  DateTime? get nextPrayerTime {
    final next = nextPrayer.value;
    if (next == null) return null;
    return getPrayerTime(next);
  }

  /// Get time remaining until next prayer
  Duration? get timeUntilNextPrayer {
    final nextTime = nextPrayerTime;
    if (nextTime == null) return null;
    
    final now = DateTime.now();
    if (nextTime.isBefore(now)) {
      // Next prayer is tomorrow (Fajr)
      return null;
    }
    
    return nextTime.difference(now);
  }

  // ============================================================
  // PRAYER QUALITY
  // ============================================================
  
  /// Calculate prayer quality based on when it was prayed
  PrayerQuality calculatePrayerQuality({
    required DateTime prayedAt,
    required DateTime adhanTime,
  }) {
    final difference = prayedAt.difference(adhanTime).inMinutes;
    
    if (difference < 0) {
      // Prayed before adhan (shouldn't happen but handle it)
      return PrayerQuality.early;
    } else if (difference <= 15) {
      return PrayerQuality.early;
    } else if (difference <= 30) {
      return PrayerQuality.onTime;
    } else {
      return PrayerQuality.late;
    }
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================
  
  /// Get prayer name in Arabic
  String getPrayerNameArabic(PrayerName prayer) {
    switch (prayer) {
      case PrayerName.fajr:
        return 'الفجر';
      case PrayerName.sunrise:
        return 'الشروق';
      case PrayerName.dhuhr:
        return 'الظهر';
      case PrayerName.asr:
        return 'العصر';
      case PrayerName.maghrib:
        return 'المغرب';
      case PrayerName.isha:
        return 'العشاء';
    }
  }

  /// Get prayer name in English
  String getPrayerNameEnglish(PrayerName prayer) {
    switch (prayer) {
      case PrayerName.fajr:
        return 'Fajr';
      case PrayerName.sunrise:
        return 'Sunrise';
      case PrayerName.dhuhr:
        return 'Dhuhr';
      case PrayerName.asr:
        return 'Asr';
      case PrayerName.maghrib:
        return 'Maghrib';
      case PrayerName.isha:
        return 'Isha';
    }
  }

  /// Get all prayer times as a map
  Map<PrayerName, DateTime?> getAllPrayerTimes() {
    return {
      PrayerName.fajr: fajrTime,
      PrayerName.sunrise: sunriseTime,
      PrayerName.dhuhr: dhuhrTime,
      PrayerName.asr: asrTime,
      PrayerName.maghrib: maghribTime,
      PrayerName.isha: ishaTime,
    };
  }
}
