/// API and Firebase constants
///
/// Single source of truth for all Firestore collection names,
/// storage paths, timeouts, and notification configuration.
class ApiConstants {
  const ApiConstants._();

  // ============================================================
  // FIRESTORE COLLECTIONS — CORE
  // ============================================================

  static const String usersCollection = 'users';
  static const String groupsCollection = 'groups';
  static const String prayerLogsCollection = 'prayer_logs';
  static const String notificationsCollection = 'notifications';
  static const String reactionsCollection = 'reactions';

  // ============================================================
  // FIRESTORE COLLECTIONS — GAMIFICATION
  // ============================================================

  static const String challengesCollection = 'challenges';
  static const String achievementsCollection = 'achievements';

  /// Subcollection of users
  static const String userChallengesCollection = 'user_challenges';

  /// Subcollection of users
  static const String userAchievementsCollection = 'user_achievements';

  // ============================================================
  // FIRESTORE COLLECTIONS — SOCIAL
  // ============================================================

  static const String feedItemsCollection = 'feed_items';
  static const String leaderboardCollection = 'leaderboard';

  // ============================================================
  // FIRESTORE COLLECTIONS — ADMIN
  // ============================================================

  static const String adminUsersCollection = 'admin_users';
  static const String appConfigCollection = 'app_config';
  static const String reportsCollection = 'reports';
  static const String analyticsCollection = 'analytics';

  // ============================================================
  // FIRESTORE COLLECTIONS — CONTENT
  // ============================================================

  static const String dailyTipsCollection = 'daily_tips';
  static const String duasCollection = 'duas';
  static const String quotesCollection = 'quotes';

  // ============================================================
  // FIRESTORE COLLECTIONS — OFFLINE SYNC
  // ============================================================

  /// Local-only pending sync operations
  static const String pendingSyncCollection = 'pending_sync';

  /// User prayer patterns for smart reminders
  static const String userPatternsCollection = 'user_patterns';

  // ============================================================
  // FIRESTORE SUBCOLLECTIONS
  // ============================================================

  static const String membersSubcollection = 'members';
  static const String dailyPrayersSubcollection = 'daily_prayers';
  static const String groupFeedSubcollection = 'group_feed';
  static const String participantsSubcollection = 'participants';

  // ============================================================
  // FIREBASE STORAGE PATHS
  // ============================================================

  static const String userProfileImagesPath = 'users/profile_images';
  static const String groupImagesPath = 'groups/images';

  // ============================================================
  // TIMEOUTS (seconds)
  // ============================================================

  static const int defaultTimeoutSeconds = 30;
  static const int locationTimeoutSeconds = 15;

  // ============================================================
  // PRAYER QUALITY THRESHOLDS (minutes after adhan)
  // ============================================================

  /// ≤ 15 min → early
  static const int earlyPrayerThresholdMinutes = 15;

  /// ≤ 30 min → on-time  |  > 30 min → late
  static const int onTimePrayerThresholdMinutes = 30;

  // ============================================================
  // NOTIFICATION — TIMING
  // ============================================================

  /// How many minutes after adhan before a "reminder" fires
  static const int prayerReminderDelayMinutes = 30;

  // ============================================================
  // NOTIFICATION — CHANNEL IDs
  // ============================================================

  static const String prayerNotificationChannelId = 'prayer_notifications';
  static const String socialNotificationChannelId = 'social_notifications';
  static const String reminderNotificationChannelId = 'reminder_notifications';

  /// Prefix for approaching-prayer channels (append minutes: 5, 10, 15, 20, 30)
  static const String prayerApproachChannelPrefix = 'prayer_approach_';

  /// Short takbeer at prayer time (not full adhan)
  static const String prayerTakbeerChannelId = 'prayer_takbeer';

  // ============================================================
  // NOTIFICATION — IDs
  // ============================================================

  /// Base notification ID for approaching-prayer alerts (1001–1005)
  static const int approachingNotificationIdBase = 1001;

  // ============================================================
  // HELPERS
  // ============================================================

  /// Returns the Firestore path for a user's subcollection.
  /// e.g. `ApiConstants.userSubPath('uid123', ApiConstants.userChallengesCollection)`
  static String userSubPath(String uid, String subcollection) =>
      '$usersCollection/$uid/$subcollection';

  /// Returns the Firestore path for a group's subcollection.
  static String groupSubPath(String groupId, String subcollection) =>
      '$groupsCollection/$groupId/$subcollection';

  /// Builds a full approach channel ID for the given [minutes] (5, 10, 15, 20, 30).
  static String approachChannelId(int minutes) =>
      '$prayerApproachChannelPrefix$minutes';
}
