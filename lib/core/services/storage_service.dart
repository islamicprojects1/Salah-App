import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../constants/storage_keys.dart';

/// Sound mode for notifications
enum NotificationSoundMode {
  adhan,   // Full sound
  vibrate, // Vibration only
  silent,  // No sound or vibration
}

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
  
  /// Check if onboarding is completed
  bool isOnboardingCompleted() {
    return read<bool>(StorageKeys.onboardingCompleted) ?? false;
  }
  
  /// Mark onboarding as completed
  Future<void> setOnboardingCompleted() async {
    await write(StorageKeys.onboardingCompleted, true);
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

  /// Get the stored notification sound mode
  NotificationSoundMode getNotificationSoundMode() {
    final mode = read<String>(StorageKeys.notificationSoundMode);
    if (mode == null) return NotificationSoundMode.adhan; // Default
    return NotificationSoundMode.values.firstWhere(
      (e) => e.name == mode,
      orElse: () => NotificationSoundMode.adhan,
    );
  }

  /// Save the notification sound mode
  Future<void> setNotificationSoundMode(NotificationSoundMode mode) async {
    await write(StorageKeys.notificationSoundMode, mode.name);
  }

  // ==================== Pending Actions (from notifications) ====================
  
  /// Set pending prayer log from notification action
  Future<void> setPendingPrayerLog(String prayerName, DateTime time) async {
    final data = {
      'prayer': prayerName,
      'time': time.toIso8601String(),
    };
    await write(StorageKeys.pendingPrayerLog, jsonEncode(data));
  }
  
  /// Get pending prayer log
  Map<String, dynamic>? getPendingPrayerLog() {
    final data = read<String>(StorageKeys.pendingPrayerLog);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }
  
  /// Clear pending prayer log
  Future<void> clearPendingPrayerLog() async {
    await remove(StorageKeys.pendingPrayerLog);
  }
  
  /// Set pending missed prayer from notification action
  Future<void> setPendingMissedPrayer(String prayerName, DateTime time) async {
    final data = {
      'prayer': prayerName,
      'time': time.toIso8601String(),
    };
    await write(StorageKeys.pendingMissedPrayer, jsonEncode(data));
  }
  
  /// Get pending missed prayer
  Map<String, dynamic>? getPendingMissedPrayer() {
    final data = read<String>(StorageKeys.pendingMissedPrayer);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }
  
  /// Clear pending missed prayer
  Future<void> clearPendingMissedPrayer() async {
    await remove(StorageKeys.pendingMissedPrayer);
  }

  // ==================== Offline Sync Queue ====================
  
  /// Add item to offline sync queue
  Future<void> addToSyncQueue(Map<String, dynamic> item) async {
    final queue = getSyncQueue();
    queue.add({
      ...item,
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'createdAt': DateTime.now().toIso8601String(),
    });
    await write(StorageKeys.offlineSyncQueue, jsonEncode(queue));
  }
  
  /// Get offline sync queue
  List<Map<String, dynamic>> getSyncQueue() {
    final data = read<String>(StorageKeys.offlineSyncQueue);
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }
  
  /// Remove item from sync queue by id
  Future<void> removeFromSyncQueue(String id) async {
    final queue = getSyncQueue();
    queue.removeWhere((item) => item['id'] == id);
    await write(StorageKeys.offlineSyncQueue, jsonEncode(queue));
  }
  
  /// Clear sync queue
  Future<void> clearSyncQueue() async {
    await remove(StorageKeys.offlineSyncQueue);
  }
  
  /// Update last sync timestamp
  Future<void> updateLastSync() async {
    await write(StorageKeys.lastSyncTimestamp, DateTime.now().toIso8601String());
  }
  
  /// Get last sync timestamp
  DateTime? getLastSync() {
    final data = read<String>(StorageKeys.lastSyncTimestamp);
    if (data == null) return null;
    return DateTime.parse(data);
  }

  // ==================== User Data Cache ====================
  
  /// Cache user streak
  Future<void> cacheStreak(int streak) async {
    await write(StorageKeys.currentStreak, streak);
  }
  
  /// Get cached streak
  int getCachedStreak() {
    return read<int>(StorageKeys.currentStreak) ?? 0;
  }
  
  /// Cache today's logged prayers
  Future<void> cacheTodayPrayers(List<String> prayers) async {
    await write(StorageKeys.todayLoggedPrayers, jsonEncode(prayers));
  }
  
  /// Get cached today's prayers
  List<String> getCachedTodayPrayers() {
    final data = read<String>(StorageKeys.todayLoggedPrayers);
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list.map((e) => e.toString()).toList();
  }
}

