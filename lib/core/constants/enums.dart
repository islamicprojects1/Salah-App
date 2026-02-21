import 'dart:ui';

/// Centralized enums for the Salah app.
///
/// Import this file instead of defining enums in multiple places.
/// Organised by feature domain for quick navigation.

// ============================================================
// PRAYER & TIMING
// ============================================================

/// The five daily prayers plus sunrise (Shuruq).
enum PrayerName {
  fajr,
  sunrise,
  dhuhr,
  asr,
  maghrib,
  isha;

  /// Human-readable Arabic transliteration.
  String get displayName => switch (this) {
    PrayerName.fajr => 'Fajr',
    PrayerName.sunrise => 'Sunrise',
    PrayerName.dhuhr => 'Dhuhr',
    PrayerName.asr => 'Asr',
    PrayerName.maghrib => 'Maghrib',
    PrayerName.isha => 'Isha',
  };

  /// Whether this prayer is a required salah (sunrise is not).
  bool get isFard => this != PrayerName.sunrise;
}

/// When the user logged a prayer relative to its time window.
enum PrayerTimingQuality {
  veryEarly,
  early,
  onTime,
  late,
  veryLate,
  missed,
  notYet;

  bool get isLogged =>
      this == veryEarly ||
      this == early ||
      this == onTime ||
      this == late ||
      this == veryLate;
}

/// Simple prayer status for cards and lists.
enum PrayerCardStatus { prayed, missed, notYet }

/// Live UI state for the current prayer slot.
enum LivePrayerStatus { notStarted, pending, prayedOnTime, prayedLate, missed }

// ============================================================
// USER & PROFILE
// ============================================================

enum Gender { male, female }

enum UserRole { solo, parent, child }

enum PrivacyMode { public, anonymous, private }

// ============================================================
// FAMILY & GROUPS
// ============================================================

enum MemberRole { parent, child }

enum GroupType { family, guided, friends }

enum ActivityType { prayerLog, streakAchievement, encouragement, joinedFamily }

enum PulseEventType {
  prayerLogged,
  encouragement,
  dailyComplete,
  familyCelebration,
}

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

  bool get isRtl => direction == TextDirection.rtl;

  static AppLanguage fromCode(String code) => AppLanguage.values.firstWhere(
    (lang) => lang.code == code,
    orElse: () => AppLanguage.arabic,
  );
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
  dismiss;

  /// Whether this action represents a snooze operation.
  bool get isSnooze => this == snooze5 || this == snooze10 || this == snooze15;

  /// Snooze duration in minutes. Returns null for non-snooze actions.
  int? get snoozeMinutes => switch (this) {
    NotificationActionType.snooze5 => 5,
    NotificationActionType.snooze10 => 10,
    NotificationActionType.snooze15 => 15,
    _ => null,
  };
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

enum ReactionType { like, celebrate, pray, encourage, love }

// ============================================================
// REPORTS
// ============================================================

enum ReportType { userReport, bugReport, featureRequest, contentReport, other }

enum ReportStatus { pending, inProgress, resolved, dismissed }

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

enum AchievementTier { bronze, silver, gold, platinum, diamond }

enum AchievementCategory { streak, prayers, early, social, family, special }

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
// ADMIN
// ============================================================

enum AdminRole { superAdmin, admin, moderator, support, analyst }

// ============================================================
// UI
// ============================================================

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

/// @deprecated — استخدم [PrayerTimingQuality] بدلاً منه.
/// محتفظ به للتوافق مع الكود القديم فقط — سيُحذف بعد الـ refactor.
@Deprecated('Use PrayerTimingQuality instead')
enum PrayerQuality { early, onTime, late, missed }
