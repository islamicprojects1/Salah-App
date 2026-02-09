/// API and Firebase constants
class ApiConstants {
  ApiConstants._();

  // ============================================================
  // FIRESTORE COLLECTIONS - CORE
  // ============================================================
  
  /// Users collection
  static const String usersCollection = 'users';
  
  /// Groups collection (families, friends, mosques, etc.)
  static const String groupsCollection = 'groups';
  
  /// Prayer logs collection
  static const String prayerLogsCollection = 'prayer_logs';
  
  /// Notifications collection
  static const String notificationsCollection = 'notifications';
  
  /// Reactions collection (for social interactions)
  static const String reactionsCollection = 'reactions';

  // ============================================================
  // FIRESTORE COLLECTIONS - GAMIFICATION
  // ============================================================
  
  /// Challenges collection
  static const String challengesCollection = 'challenges';
  
  /// Achievements collection
  static const String achievementsCollection = 'achievements';
  
  /// User challenges progress (subcollection of users)
  static const String userChallengesCollection = 'user_challenges';
  
  /// User achievements (subcollection of users)
  static const String userAchievementsCollection = 'user_achievements';

  // ============================================================
  // FIRESTORE COLLECTIONS - SOCIAL
  // ============================================================
  
  /// Feed items collection (social timeline)
  static const String feedItemsCollection = 'feed_items';
  
  /// Leaderboard cached data
  static const String leaderboardCollection = 'leaderboard';

  // ============================================================
  // FIRESTORE COLLECTIONS - ADMIN
  // ============================================================
  
  /// Admin users collection
  static const String adminUsersCollection = 'admin_users';
  
  /// App configuration collection
  static const String appConfigCollection = 'app_config';
  
  /// Reports and issues collection
  static const String reportsCollection = 'reports';
  
  /// Analytics events collection
  static const String analyticsCollection = 'analytics';

  // ============================================================
  // FIRESTORE COLLECTIONS - CONTENT
  // ============================================================
  
  /// Daily tips collection
  static const String dailyTipsCollection = 'daily_tips';
  
  /// Duas collection
  static const String duasCollection = 'duas';
  
  /// Islamic quotes collection
  static const String quotesCollection = 'quotes';

  // ============================================================
  // FIRESTORE COLLECTIONS - OFFLINE SYNC
  // ============================================================
  
  /// Pending sync operations (local)
  static const String pendingSyncCollection = 'pending_sync';
  
  /// User prayer patterns (for smart reminders)
  static const String userPatternsCollection = 'user_patterns';

  // ============================================================
  // FIRESTORE SUBCOLLECTIONS
  // ============================================================
  
  /// Group members subcollection
  static const String membersSubcollection = 'members';
  
  /// User's daily prayers subcollection
  static const String dailyPrayersSubcollection = 'daily_prayers';
  
  /// Group feed subcollection
  static const String groupFeedSubcollection = 'group_feed';
  
  /// Challenge participants subcollection
  static const String participantsSubcollection = 'participants';

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
