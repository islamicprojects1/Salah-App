import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../constants/storage_keys.dart';

/// Service for handling local storage operations using GetStorage
/// 
/// This service provides a centralized way to read/write persistent data.
/// It uses GetStorage for fast, synchronous storage operations.
class StorageService extends GetxService {
  late final GetStorage _storage;
  
  /// Initialize the storage service
  /// Must be called before using any storage operations
  Future<StorageService> init() async {
    await GetStorage.init();
    _storage = GetStorage();
    return this;
  }
  
  // ==================== Generic Operations ====================
  
  /// Read a value from storage
  T? read<T>(String key) => _storage.read<T>(key);
  
  /// Write a value to storage
  Future<void> write(String key, dynamic value) async {
    await _storage.write(key, value);
  }
  
  /// Remove a value from storage
  Future<void> remove(String key) async {
    await _storage.remove(key);
  }
  
  /// Check if a key exists in storage
  bool hasData(String key) => _storage.hasData(key);
  
  /// Clear all storage data
  Future<void> clearAll() async {
    await _storage.erase();
  }
  
  // ==================== Language Operations ====================
  
  /// Get the stored language code, defaults to device locale or 'ar'
  String getLanguage() {
    return read<String>(StorageKeys.language) ?? 
           Get.deviceLocale?.languageCode ?? 
           'ar';
  }
  
  /// Save the selected language code
  Future<void> setLanguage(String languageCode) async {
    await write(StorageKeys.language, languageCode);
  }
  
  // ==================== Theme Operations ====================
  
  /// Get the stored theme mode, defaults to 'system'
  String getThemeMode() {
    return read<String>(StorageKeys.themeMode) ?? 'system';
  }
  
  /// Save the selected theme mode
  Future<void> setThemeMode(String mode) async {
    await write(StorageKeys.themeMode, mode);
  }
  
  // ==================== First Time Operations ====================
  
  /// Check if this is the user's first time opening the app
  bool isFirstTime() {
    return read<bool>(StorageKeys.isFirstTime) ?? true;
  }
  
  /// Mark that the user has opened the app before
  Future<void> setNotFirstTime() async {
    await write(StorageKeys.isFirstTime, false);
  }
  
  // ==================== Location Operations ====================
  
  /// Get stored latitude
  double? getLatitude() => read<double>(StorageKeys.latitude);
  
  /// Get stored longitude
  double? getLongitude() => read<double>(StorageKeys.longitude);
  
  /// Get stored city name
  String? getCityName() => read<String>(StorageKeys.cityName);
  
  /// Save location data
  Future<void> saveLocation({
    required double latitude,
    required double longitude,
    required String cityName,
  }) async {
    await write(StorageKeys.latitude, latitude);
    await write(StorageKeys.longitude, longitude);
    await write(StorageKeys.cityName, cityName);
  }
  
  // ==================== Notification Operations ====================
  
  /// Check if notifications are enabled
  bool areNotificationsEnabled() {
    return read<bool>(StorageKeys.notificationsEnabled) ?? true;
  }
  
  /// Set notifications enabled state
  Future<void> setNotificationsEnabled(bool enabled) async {
    await write(StorageKeys.notificationsEnabled, enabled);
  }
  
  /// Get notification preference for a specific prayer
  bool getPrayerNotification(String prayerKey) {
    return read<bool>(prayerKey) ?? true;
  }
  
  /// Set notification preference for a specific prayer
  Future<void> setPrayerNotification(String prayerKey, bool enabled) async {
    await write(prayerKey, enabled);
  }
}
