/// Storage keys used for persisting app settings with GetStorage
/// 
/// These constants ensure consistency when reading/writing to local storage
class StorageKeys {
  StorageKeys._();
  
  // ============================================================
  // APP SETTINGS
  // ============================================================
  
  /// Key for storing the selected language code (e.g., 'ar', 'en')
  static const String language = 'language';
  
  /// Key for storing the selected theme mode ('system', 'light', 'dark')
  static const String themeMode = 'theme_mode';
  
  /// Key for checking if this is the user's first time opening the app
  static const String isFirstTime = 'is_first_time';
  
  /// Key for checking if onboarding is completed
  static const String onboardingCompleted = 'onboarding_completed';

  // ============================================================
  // PRAYER TIMES
  // ============================================================
  
  /// Key for storing the last known prayer times fetch timestamp
  static const String lastPrayerTimesFetch = 'last_prayer_times_fetch';
  
  /// Key for storing cached prayer times
  static const String cachedPrayerTimes = 'cached_prayer_times';

  // ============================================================
  // LOCATION
  // ============================================================
  
  /// Key for storing user's location latitude
  static const String latitude = 'latitude';
  
  /// Key for storing user's location longitude
  static const String longitude = 'longitude';
  
  /// Key for storing user's city name
  static const String cityName = 'city_name';

  // ============================================================
  // NOTIFICATIONS
  // ============================================================
  
  /// Key for storing notification preferences
  static const String notificationsEnabled = 'notifications_enabled';

  /// Key for storing if all adhan notifications are enabled
  static const String adhanNotificationsEnabled = 'adhan_notifications_enabled';
  
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
  
  /// Key for reminder notification preference
  static const String reminderNotification = 'reminder_notification';
  
  /// Key for family notification preference
  static const String familyNotification = 'family_notification';
  
  /// Key for notification sound mode ('adhan', 'vibrate', 'silent')
  static const String notificationSoundMode = 'notification_sound_mode';

  /// Once we've shown the "enable notifications in app settings" hint, don't repeat
  static const String notificationPermissionHintShown = 'notification_permission_hint_shown';

  /// Last date (YYYY-MM-DD) we showed the qada hint so we show at most once per day
  static const String lastQadaHintDate = 'last_qada_hint_date';

  // ============================================================
  // PENDING ACTIONS (for notification quick actions)
  // ============================================================
  
  /// Key for storing pending prayer log from notification
  static const String pendingPrayerLog = 'pending_prayer_log';
  
  /// Key for storing pending missed prayer from notification
  static const String pendingMissedPrayer = 'pending_missed_prayer';
  
  /// Key for storing pending will pray action
  static const String pendingWillPray = 'pending_will_pray';

  // ============================================================
  // OFFLINE SYNC
  // ============================================================
  
  /// Key for storing offline sync queue
  static const String offlineSyncQueue = 'offline_sync_queue';
  
  /// Key for storing last sync timestamp
  static const String lastSyncTimestamp = 'last_sync_timestamp';
  
  /// Key for storing offline prayer logs
  static const String offlinePrayerLogs = 'offline_prayer_logs';

  // ============================================================
  // USER PATTERNS (for smart notifications)
  // ============================================================
  
  /// Key prefix for storing user prayer patterns
  static const String userPatternPrefix = 'user_pattern_';
  
  /// Key for storing last logged prayers
  static const String lastLoggedPrayers = 'last_logged_prayers';

  // ============================================================
  // USER DATA CACHE
  // ============================================================
  
  /// Key for storing cached user data
  static const String cachedUserData = 'cached_user_data';
  
  /// Key for storing cached family data
  static const String cachedFamilyData = 'cached_family_data';
  
  /// Key for storing user's current streak
  static const String currentStreak = 'current_streak';
  
  /// Key for storing today's logged prayers
  static const String todayLoggedPrayers = 'today_logged_prayers';
}

