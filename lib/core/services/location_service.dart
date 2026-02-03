import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';

/// Service for managing location
class LocationService extends GetxService {
  // ============================================================
  // OBSERVABLE STATE
  // ============================================================
  
  final currentPosition = Rxn<Position>();
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
}
