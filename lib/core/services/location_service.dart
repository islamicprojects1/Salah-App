import 'dart:convert';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

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

  bool _isInitialized = false;

  // ============================================================
  // INITIALIZATION
  // ============================================================
  
  /// Initialize the service
  Future<LocationService> init() async {
    if (_isInitialized) return this;
    _isInitialized = true;
    await getCurrentLocation();
    return this;
  }

  // ============================================================
  // GETTERS
  // ============================================================
  
  /// Get current latitude
  double? get latitude => currentPosition.value?.latitude;
  
  /// Get current longitude
  double? get longitude => currentPosition.value?.longitude;
  
  /// Check if location is available
  bool get hasLocation => currentPosition.value != null;

  /// Display string for UI: real city when GPS worked, or clear fallback message.
  String get currentCity => cityName.value.isNotEmpty ? cityName.value : 'not_specified'.tr;
  /// When using default (Mecca), show this so user knows it's not their actual location.
  String get locationDisplayLabel => isUsingDefaultLocation.value
      ? 'makkah_fallback_label'.tr
      : (cityName.value.isNotEmpty
          ? (countryName.value.isNotEmpty ? '${cityName.value}, ${countryName.value}' : cityName.value)
          : 'not_specified'.tr);

  // ============================================================
  // LOCATION METHODS
  // ============================================================
  
  /// Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        errorMessage.value = 'location_services_disabled';
        return _getDefaultLocation();
      }
      
      // Check permission
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          errorMessage.value = 'location_permission_denied';
          return _getDefaultLocation();
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        errorMessage.value = 'location_permission_permanently_denied';
        return _getDefaultLocation();
      }
      
      // Get position
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
      
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Default location (Mecca) if GPS fails — used only for prayer times, not as "user's city".
  Position _getDefaultLocation() {
    final defaultPos = Position(
      latitude: 21.4225,
      longitude: 39.8262,
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
          
          cityName.value = address['city'] ?? 
                           address['town'] ?? 
                           address['village'] ?? 
                           address['state'] ?? // "Amman" is often state too
                           address['county'] ?? // Fallback
                           '';
          
          countryName.value = address['country'] ?? '';
        }
      }
    } catch (e) {
      // Silently fail - city name is not critical
      // Reverse geocoding failed silently
    }
  }
}
