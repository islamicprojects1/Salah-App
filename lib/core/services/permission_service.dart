import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for managing app permissions
class PermissionService extends GetxService {
  // ============================================================
  // OBSERVABLE STATE
  // ============================================================
  
  final locationPermissionStatus = PermissionStatus.denied.obs;
  final notificationPermissionStatus = PermissionStatus.denied.obs;

  // ============================================================
  // INITIALIZATION
  // ============================================================
  
  /// Initialize the service
  Future<PermissionService> init() async {
    await checkAllPermissions();
    return this;
  }

  /// Check all permissions status
  Future<void> checkAllPermissions() async {
    locationPermissionStatus.value = await Permission.location.status;
    notificationPermissionStatus.value = await Permission.notification.status;
  }

  // ============================================================
  // LOCATION PERMISSION
  // ============================================================
  
  /// Check if location permission is granted
  bool get isLocationGranted => 
      locationPermissionStatus.value.isGranted;
  
  /// Check if location permission is permanently denied
  bool get isLocationPermanentlyDenied => 
      locationPermissionStatus.value.isPermanentlyDenied;

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    // Check current status
    final status = await Permission.location.status;
    
    if (status.isGranted) {
      locationPermissionStatus.value = status;
      return true;
    }
    
    if (status.isPermanentlyDenied) {
      // Open app settings
      await openAppSettings();
      return false;
    }
    
    // Request permission
    final result = await Permission.location.request();
    locationPermissionStatus.value = result;
    
    return result.isGranted;
  }

  /// Request precise location permission (for Qibla accuracy)
  Future<bool> requestPreciseLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    locationPermissionStatus.value = status;
    return status.isGranted;
  }

  // ============================================================
  // NOTIFICATION PERMISSION
  // ============================================================
  
  /// Check if notification permission is granted
  bool get isNotificationGranted => 
      notificationPermissionStatus.value.isGranted;
  
  /// Check if notification permission is permanently denied
  bool get isNotificationPermanentlyDenied => 
      notificationPermissionStatus.value.isPermanentlyDenied;

  /// Request notification permission
  Future<bool> requestNotificationPermission() async {
    // Check current status
    final status = await Permission.notification.status;
    
    if (status.isGranted) {
      notificationPermissionStatus.value = status;
      return true;
    }
    
    if (status.isPermanentlyDenied) {
      // Open app settings
      await openAppSettings();
      return false;
    }
    
    // Request permission
    final result = await Permission.notification.request();
    notificationPermissionStatus.value = result;
    
    return result.isGranted;
  }

  // ============================================================
  // ALARM PERMISSION (for exact alarm scheduling)
  // ============================================================
  
  /// Request schedule exact alarm permission (Android 12+)
  Future<bool> requestExactAlarmPermission() async {
    final status = await Permission.scheduleExactAlarm.status;
    
    if (status.isGranted) {
      return true;
    }
    
    final result = await Permission.scheduleExactAlarm.request();
    return result.isGranted;
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================
  
  /// Open app settings
  Future<void> openSettings() async {
    await openAppSettings();
  }

  /// Check if all required permissions are granted
  bool get areAllPermissionsGranted => 
      isLocationGranted && isNotificationGranted;

  /// Request all required permissions
  Future<bool> requestAllPermissions() async {
    final locationGranted = await requestLocationPermission();
    final notificationGranted = await requestNotificationPermission();
    await requestExactAlarmPermission();
    
    return locationGranted && notificationGranted;
  }
}
