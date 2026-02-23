import 'dart:convert';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:salah/core/constants/aladhan_constants.dart';
import 'package:salah/core/di/injection_container.dart';
import 'package:salah/core/services/storage_service.dart';
import 'package:salah/features/prayer/data/services/prayer_time_service.dart';

/// Service for managing location
class LocationService extends GetxService {
  // ============================================================
  // OBSERVABLE STATE
  // ============================================================

  final currentPosition = Rxn<Position>();
  final cityName = ''.obs;
  final countryName = ''.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  /// True when GPS failed and we're using Mecca as fallback (don't show "Makkah" as user's city).
  final isUsingDefaultLocation = false.obs;

  /// True when permission is denied and "Don't ask again" was selected.
  final isPermanentlyDenied = false.obs;

  bool _isInitialized = false;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  /// Initialize the service.
  ///
  /// Uses last-known position immediately (fast) so the app doesn't freeze
  /// waiting for GPS on the splash screen. Then refreshes in the background.
  /// If user skipped location in onboarding, does NOT auto-request again.
  Future<LocationService> init() async {
    if (_isInitialized) return this;
    _isInitialized = true;

    final skippedLocation = sl<StorageService>().locationSkippedInOnboarding;
    // Don't auto-request during onboarding — let the onboarding flow handle first-ask.
    // This prevents the system dialog appearing behind the splash/onboarding screens.
    final onboardingDone = sl<StorageService>().isOnboardingCompleted();

    // 1. Try last-known position instantly (no network, no GPS wait)
    final lastKnown = await getLastKnownLocation();
    if (lastKnown != null) {
      isUsingDefaultLocation.value = false;
      _reverseGeocode(lastKnown.latitude, lastKnown.longitude);
    } else {
      _getDefaultLocation();
    }

    // 2. Refresh with accurate GPS in background — only if onboarding completed
    //    and user didn't permanently skip location.
    if (!onboardingDone) return this; // let onboarding handle the first permission ask
    final permission = await Geolocator.checkPermission();
    final shouldRequest = !skippedLocation ||
        permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
    if (shouldRequest) {
      getCurrentLocation().ignore();
    }

    return this;
  }

  // ============================================================
  // GETTERS
  // ============================================================

  /// Get current latitude
  double? get latitude => currentPosition.value?.latitude;

  /// Get current longitude
  double? get longitude => currentPosition.value?.longitude;

  /// Check if location is available (has coordinates, including Mecca fallback)
  bool get hasLocation => currentPosition.value != null;

  /// Check if user granted location permission (actual permission, not coords)
  Future<bool> get isLocationPermissionGranted async {
    final p = await Geolocator.checkPermission();
    return p == LocationPermission.whileInUse ||
        p == LocationPermission.always;
  }

  /// Display string for UI: real city when GPS worked, or clear fallback message.
  String get currentCity =>
      cityName.value.isNotEmpty ? cityName.value : 'not_specified'.tr;

  /// When using default (Mecca), show this so user knows it's not their actual location.
  String get locationDisplayLabel => isUsingDefaultLocation.value
      ? 'makkah_fallback_label'.tr
      : (cityName.value.isNotEmpty
            ? (countryName.value.isNotEmpty
                  ? '${cityName.value}, ${countryName.value}'
                  : cityName.value)
            : 'not_specified'.tr);

  // ============================================================
  // LOCATION METHODS
  // ============================================================

  /// Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // 1. Request permission FIRST so the dialog always shows (even if GPS is off)
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          errorMessage.value = 'location_permission_denied';
          return _getDefaultLocation();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        isPermanentlyDenied.value = true;
        errorMessage.value = 'location_permission_permanently_denied';
        return _getDefaultLocation();
      }

      isPermanentlyDenied.value = false;

      // 2. Then check if location services (GPS) are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        errorMessage.value = 'location_services_disabled';
        return _getDefaultLocation();
      }

      // 3. Get position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      currentPosition.value = position;
      isUsingDefaultLocation.value = false;
      await _reverseGeocode(position.latitude, position.longitude);
      return position;
    } catch (e) {
      errorMessage.value = e.toString();
      return _getDefaultLocation();
    } finally {
      isLoading.value = false;
    }
  }

  /// Manually update location (for manual city selection)
  Future<void> updateManualLocation({
    required double latitude,
    required double longitude,
    required String city,
    required String country,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final position = Position(
        latitude: latitude,
        longitude: longitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );

      currentPosition.value = position;
      cityName.value = city;
      countryName.value = country;
      isUsingDefaultLocation.value = false;

      // Trigger prayer time recalculation + notification reschedule
      if (Get.isRegistered<PrayerTimeService>()) {
        Get.find<PrayerTimeService>().onLocationChanged();
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Default location (Mecca) if GPS fails — used only for prayer times, not as "user's city".
  Position _getDefaultLocation() {
    final defaultPos = Position(
      latitude: kMeccaLatitude,
      longitude: kMeccaLongitude,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
    currentPosition.value = defaultPos;
    cityName.value = '';
    countryName.value = '';
    isUsingDefaultLocation.value = true;
    return defaultPos;
  }

  /// Get last known location (faster, but might be outdated)
  Future<Position?> getLastKnownLocation() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        currentPosition.value = position;
      }
      return position;
    } catch (e) {
      return null;
    }
  }

  /// Stream location updates
  Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100, // Update every 100 meters
      ),
    );
  }

  /// Calculate distance between two points (in meters)
  double calculateDistance({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Calculate bearing between two points (in degrees)
  double calculateBearing({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.bearingBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  /// Open location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Open app settings
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // ============================================================
  // REVERSE GEOCODING
  // ============================================================

  static String _countryFromCode(String? code) {
    if (code == null || code.isEmpty) return '';
    switch (code.toUpperCase()) {
      case 'JO': return 'Jordan';
      case 'SA': return 'Saudi Arabia';
      case 'EG': return 'Egypt';
      case 'AE': return 'United Arab Emirates';
      case 'KW': return 'Kuwait';
      case 'QA': return 'Qatar';
      case 'BH': return 'Bahrain';
      case 'OM': return 'Oman';
      case 'PK': return 'Pakistan';
      case 'TR': return 'Turkey';
      case 'MY': return 'Malaysia';
      case 'SG': return 'Singapore';
      case 'ID': return 'Indonesia';
      case 'MA': return 'Morocco';
      case 'TN': return 'Tunisia';
      case 'DZ': return 'Algeria';
      case 'IR': return 'Iran';
      case 'US': return 'United States';
      case 'CA': return 'Canada';
      case 'GB': case 'UK': return 'United Kingdom';
      case 'FR': return 'France';
      case 'DE': return 'Germany';
      case 'PT': return 'Portugal';
      case 'RU': return 'Russia';
      default: return code;
    }
  }

  /// Get city name from coordinates using OpenStreetMap Nominatim API
  Future<void> _reverseGeocode(double lat, double lng) async {
    try {
      // Use user's current language preference
      final language = Get.locale?.languageCode ?? 'ar';

      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&accept-language=$language',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'SalahApp/1.0'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] as Map<String, dynamic>?;

        if (address != null) {
          // Try to get city name in order of preference
          // Prioritize 'city' > 'town' > 'village' > 'state'
          // Avoid 'county' or 'suburb' which often return districts (e.g. Marka)

          cityName.value =
              address['city'] ??
              address['town'] ??
              address['village'] ??
              address['state'] ?? // "Amman" is often state too
              address['county'] ?? // Fallback
              '';

          countryName.value =
              address['country'] as String? ??
              _countryFromCode(address['country_code'] as String?);
        }
      }
    } catch (e) {
      // Silently fail - city name is not critical
      // Reverse geocoding failed silently
    }
  }
}
