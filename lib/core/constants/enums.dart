import 'dart:ui';

/// Centralized enums for the Qurb app.
/// Import this file instead of defining enums in multiple places.

// ============================================================
// PRAYER & TIMING
// ============================================================

/// Prayer names (5 daily + sunrise)
enum PrayerName { fajr, sunrise, dhuhr, asr, maghrib, isha }

/// Prayer timing quality (when user logged relative to time window)
enum PrayerTimingQuality {
  veryEarly,
  early,
  onTime,
  late,
  veryLate,
  missed,
  notYet,
}

/// Legacy prayer quality (backward compatibility)
enum PrayerQuality {
  early,
  onTime,
  late,
  missed,
}

/// Live context: current prayer state for UI
enum LivePrayerStatus {
  notStarted,
  pending,
  prayedOnTime,
  prayedLate,
  missed,
}

/// Card/display: simple prayer status (e.g. member card, missed prayers list)
enum PrayerCardStatus { prayed, missed, notYet }

// ============================================================
// USER & PROFILE
// ============================================================

enum Gender { male, female }

enum UserRole { solo, parent, child }

// CalculationMethod and Madhab: app uses adhan package in PrayerTimeService (snake_case);
// UserModel defines its own for Firestore (camelCase). Not centralized here to avoid conflict.

enum PrivacyMode {
  public,
  anonymous,
  private,
}

// ============================================================
// FAMILY & GROUPS
// ============================================================

enum MemberRole { parent, child }

enum PulseEventType { prayerLogged, encouragement, dailyComplete }

enum ActivityType {
  prayerLog,
  streakAchievement,
  encouragement,
  joinedFamily,
}

enum GroupType { family, guided, friends }

// ============================================================
// APP SETTINGS
// ============================================================

enum AppThemeMode { system, light, dark }

enum AppLanguage {
  arabic('ar', 'العربية', TextDirection.rtl),
  english('en', 'English', TextDirection.ltr);

  final String code;
  final String name;
  final TextDirection direction;

  const AppLanguage(this.code, this.name, this.direction);

  Locale get locale => Locale(code);

  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => AppLanguage.arabic,
    );
  }
}

enum NotificationSoundMode { adhan, vibrate, silent }

// ============================================================
// NOTIFICATIONS & FEED
// ============================================================

enum NotificationActionType {
  prayNow,
  snooze5,
  snooze10,
  snooze15,
  markMissed,
  confirmPrayed,
  willPrayNow,
  dismiss,
}

enum ReportType {
  userReport,
  bugReport,
  featureRequest,
  contentReport,
  other,
}

enum ReportStatus {
  pending,
  inProgress,
  resolved,
  dismissed,
}

enum FeedItemType {
  prayerLogged,
  streakMilestone,
  challengeCompleted,
  achievementUnlocked,
  familyJoined,
  groupJoined,
  encouragement,
  milestone,
}

enum ReactionType {
  like,
  celebrate,
  pray,
  encourage,
  love,
}

// ============================================================
// SYNC & OFFLINE
// ============================================================

enum SyncItemType {
  prayerLog,
  userUpdate,
  reaction,
  groupUpdate,
  achievementUpdate,
}

enum SyncStatus { idle, loading, success, error }

// ============================================================
// ACHIEVEMENTS & CHALLENGES
// ============================================================

enum AchievementTier {
  bronze,
  silver,
  gold,
  platinum,
  diamond,
}

enum AchievementCategory {
  streak,
  prayers,
  early,
  social,
  family,
  special,
}

enum ChallengeType {
  consecutivePrayer,
  consecutiveStreak,
  totalPrayers,
  fullCompletion,
  earlyPrayer,
  familyGoal,
  groupGoal,
  nightPrayer,
  custom,
}

enum ChallengeStatus { upcoming, active, completed, expired }

// ============================================================
// ADMIN & UI
// ============================================================

enum AdminRole {
  superAdmin,
  admin,
  moderator,
  support,
  analyst,
}

enum OnboardingStep {
  welcome,
  features,
  family,
  permissions,
  profileSetup,
  complete,
}

enum AppButtonType { primary, outlined, text }

enum SnackbarType { success, error, warning, info }
