/// Storage keys used for persisting app settings with GetStorage
/// 
/// These constants ensure consistency when reading/writing to local storage
class StorageKeys {
  StorageKeys._();
  
  /// Key for storing the selected language code (e.g., 'ar', 'en')
  static const String language = 'language';
  
  /// Key for storing the selected theme mode ('system', 'light', 'dark')
  static const String themeMode = 'theme_mode';
  
  /// Key for checking if this is the user's first time opening the app
  static const String isFirstTime = 'is_first_time';
  
  /// Key for storing the last known prayer times fetch timestamp
  static const String lastPrayerTimesFetch = 'last_prayer_times_fetch';
  
  /// Key for storing user's location latitude
  static const String latitude = 'latitude';
  
  /// Key for storing user's location longitude
  static const String longitude = 'longitude';
  
  /// Key for storing user's city name
  static const String cityName = 'city_name';
  
  /// Key for storing notification preferences
  static const String notificationsEnabled = 'notifications_enabled';
  
  /// Key for storing Fajr notification preference
  static const String fajrNotification = 'fajr_notification';
  
  /// Key for storing Dhuhr notification preference
  static const String dhuhrNotification = 'dhuhr_notification';
  
  /// Key for storing Asr notification preference
  static const String asrNotification = 'asr_notification';
  
  /// Key for storing Maghrib notification preference
  static const String maghribNotification = 'maghrib_notification';
  
  /// Key for storing Isha notification preference
  static const String ishaNotification = 'isha_notification';
  
  /// Key for checking if onboarding is completed
  static const String onboardingCompleted = 'onboarding_completed';
}
