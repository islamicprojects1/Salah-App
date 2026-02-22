/// Storage keys for GetStorage local persistence.
///
/// Single source of truth — always read/write through these constants
/// to avoid typos and key collisions across the codebase.
class StorageKeys {
  const StorageKeys._();

  // ============================================================
  // APP SETTINGS
  // ============================================================

  /// Selected language code ('ar' | 'en')
  static const String language = 'language';

  /// Selected theme mode ('system' | 'light' | 'dark')
  static const String themeMode = 'theme_mode';

  /// Preferred calculation method ID (0 means automatic)
  static const String calculationMethod = 'calculation_method';

  /// True on first app launch
  static const String isFirstTime = 'is_first_time';

  /// True once onboarding is finished
  static const String onboardingCompleted = 'onboarding_completed';

  // ============================================================
  // PRAYER TIMES CACHE
  // ============================================================

  /// Unix timestamp (ms) of the last successful prayer-times fetch
  static const String lastPrayerTimesFetch = 'last_prayer_times_fetch';

  /// JSON-encoded cached prayer times
  static const String cachedPrayerTimes = 'cached_prayer_times';

  // ============================================================
  // LOCATION
  // ============================================================

  static const String latitude = 'latitude';
  static const String longitude = 'longitude';
  static const String cityName = 'city_name';

  // ============================================================
  // NOTIFICATIONS — MASTER TOGGLES
  // ============================================================

  /// Master switch for all notifications
  static const String notificationsEnabled = 'notifications_enabled';

  /// Toggle for all adhan-type notifications
  static const String adhanNotificationsEnabled = 'adhan_notifications_enabled';

  // ============================================================
  // NOTIFICATIONS — PER PRAYER
  // ============================================================

  static const String fajrNotification = 'fajr_notification';
  static const String dhuhrNotification = 'dhuhr_notification';
  static const String asrNotification = 'asr_notification';
  static const String maghribNotification = 'maghrib_notification';
  static const String ishaNotification = 'isha_notification';

  // ============================================================
  // NOTIFICATIONS — BEHAVIOUR
  // ============================================================

  /// Post-adhan reminder notification toggle
  static const String reminderNotification = 'reminder_notification';

  /// Family/social activity notifications toggle
  static const String familyNotification = 'family_notification';

  /// Sound mode ('adhan' | 'vibrate' | 'silent')
  static const String notificationSoundMode = 'notification_sound_mode';

  /// Minutes before prayer for approaching alert (5 | 10 | 15 | 20 | 30)
  static const String approachingAlertMinutes = 'approaching_alert_minutes';

  /// Minutes before Fajr for approaching alert (default 20, Fajr-specific)
  static const String approachingFajrMinutes = 'approaching_fajr_minutes';

  /// Whether the approaching alert is active
  static const String approachingAlertEnabled = 'approaching_alert_enabled';

  /// Short takbeer at prayer time (not full adhan)
  static const String takbeerAtPrayerEnabled = 'takbeer_at_prayer_enabled';

  /// True once we have shown the "open app settings" notification hint
  static const String notificationPermissionHintShown =
      'notification_permission_hint_shown';

  /// Last date (yyyy-MM-dd) the qada hint was displayed (max once per day)
  static const String lastQadaHintDate = 'last_qada_hint_date';

  // ============================================================
  // PENDING QUICK-ACTIONS (from notification taps)
  // ============================================================

  /// JSON-encoded pending prayer log triggered by a notification action
  static const String pendingPrayerLog = 'pending_prayer_log';

  /// JSON-encoded pending missed prayer from a notification action
  static const String pendingMissedPrayer = 'pending_missed_prayer';

  /// JSON-encoded "will pray now" action from a notification
  static const String pendingWillPray = 'pending_will_pray';

  // ============================================================
  // OFFLINE SYNC
  // ============================================================

  /// JSON-encoded list of queued sync operations
  static const String offlineSyncQueue = 'offline_sync_queue';

  /// Unix timestamp (ms) of the last successful sync
  static const String lastSyncTimestamp = 'last_sync_timestamp';

  /// JSON-encoded list of prayer logs recorded while offline
  static const String offlinePrayerLogs = 'offline_prayer_logs';

  // ============================================================
  // USER PATTERNS (smart reminder ML data)
  // ============================================================

  /// Prefix — append prayer name: e.g. 'user_pattern_fajr'
  static const String userPatternPrefix = 'user_pattern_';

  /// JSON-encoded list of the most recently logged prayers
  static const String lastLoggedPrayers = 'last_logged_prayers';

  // ============================================================
  // USER DATA CACHE
  // ============================================================

  /// JSON-encoded cached UserModel
  static const String cachedUserData = 'cached_user_data';

  /// JSON-encoded cached family/group data
  static const String cachedFamilyData = 'cached_family_data';

  /// Current prayer streak count
  static const String currentStreak = 'current_streak';

  /// JSON-encoded list of today's logged prayer names
  static const String todayLoggedPrayers = 'today_logged_prayers';

  // ============================================================
  // HELPERS
  // ============================================================

  /// Builds the user-pattern key for a specific prayer name.
  /// e.g. `StorageKeys.userPatternKey('fajr')` → `'user_pattern_fajr'`
  static String userPatternKey(String prayerName) =>
      '$userPatternPrefix$prayerName';

  /// All per-prayer notification keys, indexed by prayer name (lowercase).
  static const Map<String, String> prayerNotificationKeys = {
    'fajr': fajrNotification,
    'dhuhr': dhuhrNotification,
    'asr': asrNotification,
    'maghrib': maghribNotification,
    'isha': ishaNotification,
  };
}
