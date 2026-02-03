import 'package:get/get.dart';
import 'package:adhan/adhan.dart';
import 'package:salah/core/services/location_service.dart';
import 'package:salah/data/models/prayer_time_model.dart';
import 'package:salah/data/models/prayer_log_model.dart';

/// Service for calculating prayer times using Adhan package
  // ============================================================
  // ENUMS
  // ============================================================

  /// Prayer quality based on timing
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
}
