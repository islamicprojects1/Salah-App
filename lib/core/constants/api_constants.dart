/// API and Firebase constants
class ApiConstants {
  ApiConstants._();

  // ============================================================
  // FIRESTORE COLLECTIONS
  // ============================================================
  
  /// Users collection
  static const String usersCollection = 'users';
  
  /// Groups collection
  static const String groupsCollection = 'groups';
  
  /// Prayer logs collection
  static const String prayerLogsCollection = 'prayer_logs';
  
  /// Notifications collection
  static const String notificationsCollection = 'notifications';
  
  /// Reactions collection (for social interactions)
  static const String reactionsCollection = 'reactions';

  // ============================================================
  // FIRESTORE SUBCOLLECTIONS
  // ============================================================
  
  /// Group members subcollection
  static const String membersSubcollection = 'members';
  
  /// User's daily prayers subcollection
  static const String dailyPrayersSubcollection = 'daily_prayers';

  // ============================================================
  // STORAGE PATHS
  // ============================================================
  
  /// User profile images path
  static const String userProfileImagesPath = 'users/profile_images';
  
  /// Group images path
  static const String groupImagesPath = 'groups/images';

  // ============================================================
  // TIMEOUTS
  // ============================================================
  
  /// Default timeout for network requests (in seconds)
  static const int defaultTimeout = 30;
  
  /// Location timeout (in seconds)
  static const int locationTimeout = 15;

  // ============================================================
  // PRAYER QUALITY THRESHOLDS (in minutes)
  // ============================================================
  
  /// Early prayer threshold (within 15 minutes of adhan)
  static const int earlyPrayerThreshold = 15;
  
  /// On-time prayer threshold (within 30 minutes of adhan)
  static const int onTimePrayerThreshold = 30;
  
  // After 30 minutes = late

  // ============================================================
  // NOTIFICATION SETTINGS
  // ============================================================
  
  /// Reminder notification delay after adhan (in minutes)
  static const int prayerReminderDelayMinutes = 30;
  
  /// Channel IDs
  static const String prayerNotificationChannelId = 'prayer_notifications';
  static const String socialNotificationChannelId = 'social_notifications';
  static const String reminderNotificationChannelId = 'reminder_notifications';
}
