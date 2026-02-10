import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salah/core/constants/enums.dart';
import 'user_privacy_settings.dart';

/// Calculation method for prayer times (Firestore/camelCase)
enum CalculationMethod {
  muslimWorldLeague,
  egyptian,
  karachi,
  ummAlQura,
  dubai,
  qatar,
  kuwait,
  moonsightingCommittee,
  singapore,
  turkey,
  tehran,
  northAmerica,
}

/// Madhab for Asr calculation (Firestore)
enum Madhab { shafi, hanafi }

/// User model for Firestore
class UserModel {
  final String id;
  final String name;
  final DateTime birthDate;
  final Gender gender;
  final String? email;
  final String? photoUrl;
  final String? fcmToken;
  final String language; // 'ar' or 'en'
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Group references
  final String? familyId;
  final List<String> groupIds;
  
  // Role
  final UserRole role;
  final bool isParent; // Can manage children
  
  // Streak tracking
  final int currentStreak;
  final int longestStreak;
  final int totalPrayers;
  final DateTime? lastPrayerAt;
  
  // Notification settings
  final Map<String, bool> prayerNotifications; // {fajr: true, dhuhr: true, ...}
  final bool reminderEnabled; // 30 min reminder
  final bool familyNotificationsEnabled;
  
  // Prayer calculation preferences
  final CalculationMethod calculationMethod;
  final Madhab madhab;
  
  // Location cache
  final double? lastLatitude;
  final double? lastLongitude;
  final String? lastCity;
  
  // Privacy settings
  final UserPrivacySettings privacySettings;

  UserModel({
    required this.id,
    required this.name,
    required this.birthDate,
    required this.gender,
    this.email,
    this.photoUrl,
    this.fcmToken,
    this.language = 'ar',
    required this.createdAt,
    this.updatedAt,
    this.familyId,
    this.groupIds = const [],
    this.role = UserRole.solo,
    this.isParent = false,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalPrayers = 0,
    this.lastPrayerAt,
    this.prayerNotifications = const {
      'fajr': true,
      'dhuhr': true,
      'asr': true,
      'maghrib': true,
      'isha': true,
    },
    this.reminderEnabled = true,
    this.familyNotificationsEnabled = true,
    this.calculationMethod = CalculationMethod.muslimWorldLeague,
    this.madhab = Madhab.shafi,
    this.lastLatitude,
    this.lastLongitude,
    this.lastCity,
    UserPrivacySettings? privacySettings,
  }) : privacySettings = privacySettings ?? UserPrivacySettings.defaultPublic();

  /// Calculate age from birth date
  int get age {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// Check if user is accountable for prayer (typically 7+ years for practice, 10+ for accountability)
  bool get isAccountable => age >= 10;

  /// Create from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  /// Create from Map
  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      name: data['name'] ?? '',
      birthDate: data['birthDate'] is Timestamp 
          ? (data['birthDate'] as Timestamp).toDate()
          : (data['birthDate'] is String 
              ? DateTime.parse(data['birthDate']) 
              : DateTime(2000)),
      gender: data['gender'] == 'male' ? Gender.male : Gender.female,
      email: data['email'],
      photoUrl: data['photoUrl'],
      fcmToken: data['fcmToken'],
      language: data['language'] ?? 'ar',
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate()
          : (data['createdAt'] is String 
              ? DateTime.parse(data['createdAt']) 
              : DateTime.now()),
      updatedAt: data['updatedAt'] is Timestamp 
          ? (data['updatedAt'] as Timestamp).toDate()
          : (data['updatedAt'] is String 
              ? DateTime.parse(data['updatedAt']) 
              : null),
      familyId: data['familyId'],
      groupIds: List<String>.from(data['groupIds'] ?? []),
      role: _parseRole(data['role']),
      isParent: data['isParent'] ?? false,
      currentStreak: data['currentStreak'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
      totalPrayers: data['totalPrayers'] ?? 0,
      lastPrayerAt: data['lastPrayerAt'] is Timestamp 
          ? (data['lastPrayerAt'] as Timestamp).toDate()
          : (data['lastPrayerAt'] is String 
              ? DateTime.parse(data['lastPrayerAt']) 
              : null),
      prayerNotifications: Map<String, bool>.from(data['prayerNotifications'] ?? {
        'fajr': true, 'dhuhr': true, 'asr': true, 'maghrib': true, 'isha': true,
      }),
      reminderEnabled: data['reminderEnabled'] ?? true,
      familyNotificationsEnabled: data['familyNotificationsEnabled'] ?? true,
      calculationMethod: _parseCalculationMethod(data['calculationMethod']),
      madhab: data['madhab'] == 'hanafi' ? Madhab.hanafi : Madhab.shafi,
      lastLatitude: data['lastLatitude']?.toDouble(),
      lastLongitude: data['lastLongitude']?.toDouble(),
      lastCity: data['lastCity'],
      privacySettings: data['privacySettings'] != null
          ? UserPrivacySettings.fromMap(Map<String, dynamic>.from(data['privacySettings']))
          : UserPrivacySettings.defaultPublic(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'birthDate': Timestamp.fromDate(birthDate),
      'gender': gender == Gender.male ? 'male' : 'female',
      'email': email,
      'photoUrl': photoUrl,
      'fcmToken': fcmToken,
      'language': language,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'familyId': familyId,
      'groupIds': groupIds,
      'role': role.name,
      'isParent': isParent,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalPrayers': totalPrayers,
      'lastPrayerAt': lastPrayerAt != null ? Timestamp.fromDate(lastPrayerAt!) : null,
      'prayerNotifications': prayerNotifications,
      'reminderEnabled': reminderEnabled,
      'familyNotificationsEnabled': familyNotificationsEnabled,
      'calculationMethod': calculationMethod.name,
      'madhab': madhab.name,
      'lastLatitude': lastLatitude,
      'lastLongitude': lastLongitude,
      'lastCity': lastCity,
      'privacySettings': privacySettings.toMap(),
    };
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    String? name,
    DateTime? birthDate,
    Gender? gender,
    String? email,
    String? photoUrl,
    String? fcmToken,
    String? language,
    DateTime? updatedAt,
    String? familyId,
    List<String>? groupIds,
    UserRole? role,
    bool? isParent,
    int? currentStreak,
    int? longestStreak,
    int? totalPrayers,
    DateTime? lastPrayerAt,
    Map<String, bool>? prayerNotifications,
    bool? reminderEnabled,
    bool? familyNotificationsEnabled,
    CalculationMethod? calculationMethod,
    Madhab? madhab,
    double? lastLatitude,
    double? lastLongitude,
    String? lastCity,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      language: language ?? this.language,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      familyId: familyId ?? this.familyId,
      groupIds: groupIds ?? this.groupIds,
      role: role ?? this.role,
      isParent: isParent ?? this.isParent,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalPrayers: totalPrayers ?? this.totalPrayers,
      lastPrayerAt: lastPrayerAt ?? this.lastPrayerAt,
      prayerNotifications: prayerNotifications ?? this.prayerNotifications,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      familyNotificationsEnabled: familyNotificationsEnabled ?? this.familyNotificationsEnabled,
      calculationMethod: calculationMethod ?? this.calculationMethod,
      madhab: madhab ?? this.madhab,
      lastLatitude: lastLatitude ?? this.lastLatitude,
      lastLongitude: lastLongitude ?? this.lastLongitude,
      lastCity: lastCity ?? this.lastCity,
    );
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  static UserRole _parseRole(String? role) {
    switch (role) {
      case 'parent':
        return UserRole.parent;
      case 'child':
        return UserRole.child;
      default:
        return UserRole.solo;
    }
  }

  static CalculationMethod _parseCalculationMethod(String? method) {
    switch (method) {
      case 'egyptian':
        return CalculationMethod.egyptian;
      case 'karachi':
        return CalculationMethod.karachi;
      case 'ummAlQura':
        return CalculationMethod.ummAlQura;
      case 'dubai':
        return CalculationMethod.dubai;
      case 'qatar':
        return CalculationMethod.qatar;
      case 'kuwait':
        return CalculationMethod.kuwait;
      case 'moonsightingCommittee':
        return CalculationMethod.moonsightingCommittee;
      case 'singapore':
        return CalculationMethod.singapore;
      case 'turkey':
        return CalculationMethod.turkey;
      case 'tehran':
        return CalculationMethod.tehran;
      case 'northAmerica':
        return CalculationMethod.northAmerica;
      default:
        return CalculationMethod.muslimWorldLeague;
    }
  }
}

