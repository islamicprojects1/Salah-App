/// Privacy mode for user profile visibility
enum PrivacyMode {
  public,      // Everyone can see profile
  anonymous,   // Only stats without name/photo
  private,     // Only family can see
}

/// User privacy settings model
class UserPrivacySettings {
  final PrivacyMode mode;
  final bool showName;
  final bool showPhoto;
  final bool showStreak;
  final bool showInLeaderboard;
  final bool showPrayerTimes;
  final bool onlyFamily;

  const UserPrivacySettings({
    this.mode = PrivacyMode.public,
    this.showName = true,
    this.showPhoto = true,
    this.showStreak = true,
    this.showInLeaderboard = true,
    this.showPrayerTimes = true,
    this.onlyFamily = false,
  });

  /// Create from Firestore map
  factory UserPrivacySettings.fromMap(Map<String, dynamic> map) {
    return UserPrivacySettings(
      mode: _parsePrivacyMode(map['mode'] ?? 'public'),
      showName: map['showName'] ?? true,
      showPhoto: map['showPhoto'] ?? true,
      showStreak: map['showStreak'] ?? true,
      showInLeaderboard: map['showInLeaderboard'] ?? true,
      showPrayerTimes: map['showPrayerTimes'] ?? true,
      onlyFamily: map['onlyFamily'] ?? false,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'mode': mode.name,
      'showName': showName,
      'showPhoto': showPhoto,
      'showStreak': showStreak,
      'showInLeaderboard': showInLeaderboard,
      'showPrayerTimes': showPrayerTimes,
      'onlyFamily': onlyFamily,
    };
  }

  /// Parse privacy mode from string
  static PrivacyMode _parsePrivacyMode(String mode) {
    switch (mode.toLowerCase()) {
      case 'public':
        return PrivacyMode.public;
      case 'anonymous':
        return PrivacyMode.anonymous;
      case 'private':
        return PrivacyMode.private;
      default:
        return PrivacyMode.public;
    }
  }

  /// Create default public settings
  factory UserPrivacySettings.defaultPublic() {
    return const UserPrivacySettings(
      mode: PrivacyMode.public,
      showName: true,
      showPhoto: true,
      showStreak: true,
      showInLeaderboard: true,
      showPrayerTimes: true,
      onlyFamily: false,
    );
  }

  /// Create anonymous settings
  factory UserPrivacySettings.anonymous() {
    return const UserPrivacySettings(
      mode: PrivacyMode.anonymous,
      showName: false,
      showPhoto: false,
      showStreak: true,
      showInLeaderboard: true,
      showPrayerTimes: false,
      onlyFamily: false,
    );
  }

  /// Create private (family only) settings
  factory UserPrivacySettings.private() {
    return const UserPrivacySettings(
      mode: PrivacyMode.private,
      showName: true,
      showPhoto: true,
      showStreak: true,
      showInLeaderboard: false,
      showPrayerTimes: true,
      onlyFamily: true,
    );
  }

  /// Copy with method for updating settings
  UserPrivacySettings copyWith({
    PrivacyMode? mode,
    bool? showName,
    bool? showPhoto,
    bool? showStreak,
    bool? showInLeaderboard,
    bool? showPrayerTimes,
    bool? onlyFamily,
  }) {
    return UserPrivacySettings(
      mode: mode ?? this.mode,
      showName: showName ?? this.showName,
      showPhoto: showPhoto ?? this.showPhoto,
      showStreak: showStreak ?? this.showStreak,
      showInLeaderboard: showInLeaderboard ?? this.showInLeaderboard,
      showPrayerTimes: showPrayerTimes ?? this.showPrayerTimes,
      onlyFamily: onlyFamily ?? this.onlyFamily,
    );
  }
}
