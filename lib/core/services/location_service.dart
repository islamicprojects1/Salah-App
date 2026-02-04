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

  // ============================================================
  // INITIALIZATION
  // ============================================================
  
  /// Initialize the service
  Future<LocationService> init() async {
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

  /// Get current city name (reactive)
  String get currentCity => cityName.value.isNotEmpty ? cityName.value : 'غير محدد';

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
        return null;
      }
      
      // Check permission
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          errorMessage.value = 'location_permission_denied';
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        errorMessage.value = 'location_permission_permanently_denied';
        return null;
      }
      
      // Get position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      
      currentPosition.value = position;
      
      // Get city name from coordinates
      await _reverseGeocode(position.latitude, position.longitude);
      
      return position;
    } catch (e) {
      errorMessage.value = e.toString();
      return null;
    } finally {
      isLoading.value = false;
    }
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
          cityName.value = address['city'] ?? 
                           address['town'] ?? 
                           address['village'] ?? 
                           address['county'] ?? 
                           address['state'] ?? 
                           '';
          
          countryName.value = address['country'] ?? '';
        }
      }
    } catch (e) {
      // Silently fail - city name is not critical
      print('Reverse geocoding failed: $e');
    }
  }
}
