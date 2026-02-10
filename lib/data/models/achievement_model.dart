import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salah/core/constants/enums.dart';

/// Achievement model for Firestore
class AchievementModel {
  final String id;
  final String title;
  final String titleEn;
  final String description;
  final String descriptionEn;
  final String emoji;
  final AchievementCategory category;
  final Map<AchievementTier, int> tierThresholds; // مثال: {bronze: 7, silver: 21, gold: 40}
  final DateTime createdAt;
  final bool isActive;

  AchievementModel({
    required this.id,
    required this.title,
    required this.titleEn,
    required this.description,
    required this.descriptionEn,
    required this.emoji,
    required this.category,
    required this.tierThresholds,
    required this.createdAt,
    this.isActive = true,
  });

  /// Create from Firestore document
  factory AchievementModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AchievementModel(
      id: doc.id,
      title: data['title'] ?? '',
      titleEn: data['titleEn'] ?? '',
      description: data['description'] ?? '',
      descriptionEn: data['descriptionEn'] ?? '',
      emoji: data['emoji'] ?? '🏆',
      category: getCategory(data['category']),
      tierThresholds: _parseTierThresholds(data['tierThresholds']),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'titleEn': titleEn,
      'description': description,
      'descriptionEn': descriptionEn,
      'emoji': emoji,
      'category': category.name,
      'tierThresholds': tierThresholds.map((k, v) => MapEntry(k.name, v)),
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }

  /// Get threshold for a specific tier
  int? getThreshold(AchievementTier tier) => tierThresholds[tier];

  /// Get tier emoji
  static String getTierEmoji(AchievementTier tier) {
    switch (tier) {
      case AchievementTier.bronze:
        return '🥉';
      case AchievementTier.silver:
        return '🥈';
      case AchievementTier.gold:
        return '🥇';
      case AchievementTier.platinum:
        return '💎';
      case AchievementTier.diamond:
        return '💠';
    }
  }

  static AchievementCategory getCategory(String? category) {
    switch (category) {
      case 'streak':
        return AchievementCategory.streak;
      case 'prayers':
        return AchievementCategory.prayers;
      case 'early':
        return AchievementCategory.early;
      case 'social':
        return AchievementCategory.social;
      case 'family':
        return AchievementCategory.family;
      default:
        return AchievementCategory.special;
    }
  }

  static Map<AchievementTier, int> _parseTierThresholds(Map<String, dynamic>? data) {
    if (data == null) return {};
    
    final result = <AchievementTier, int>{};
    data.forEach((key, value) {
      final tier = _parseTier(key);
      if (tier != null && value is int) {
        result[tier] = value;
      }
    });
    return result;
  }

  static AchievementTier? _parseTier(String? tier) {
    switch (tier) {
      case 'bronze':
        return AchievementTier.bronze;
      case 'silver':
        return AchievementTier.silver;
      case 'gold':
        return AchievementTier.gold;
      case 'platinum':
        return AchievementTier.platinum;
      case 'diamond':
        return AchievementTier.diamond;
      default:
        return null;
    }
  }
}

/// User's achievement progress
class UserAchievement {
  final String id;
  final String achievementId;
  final String userId;
  final AchievementTier currentTier;
  final int currentProgress;
  final DateTime? unlockedAt;
  final DateTime? lastUpdated;

  UserAchievement({
    required this.id,
    required this.achievementId,
    required this.userId,
    required this.currentTier,
    required this.currentProgress,
    this.unlockedAt,
    this.lastUpdated,
  });

  /// Check if achievement is unlocked
  bool get isUnlocked => unlockedAt != null;

  /// Create from Firestore document
  factory UserAchievement.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserAchievement(
      id: doc.id,
      achievementId: data['achievementId'] ?? '',
      userId: data['userId'] ?? '',
      currentTier: AchievementModel._parseTier(data['currentTier']) ?? AchievementTier.bronze,
      currentProgress: data['currentProgress'] ?? 0,
      unlockedAt: data['unlockedAt'] != null
          ? (data['unlockedAt'] as Timestamp).toDate()
          : null,
      lastUpdated: data['lastUpdated'] != null
          ? (data['lastUpdated'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'achievementId': achievementId,
      'userId': userId,
      'currentTier': currentTier.name,
      'currentProgress': currentProgress,
      'unlockedAt': unlockedAt != null ? Timestamp.fromDate(unlockedAt!) : null,
      'lastUpdated': lastUpdated != null ? Timestamp.fromDate(lastUpdated!) : null,
    };
  }
}

/// Default achievements list
class DefaultAchievements {
  static List<Map<String, dynamic>> get all => [
    // Streak achievements
    {
      'id': 'streak_master',
      'title': 'ماستر السلسلة',
      'titleEn': 'Streak Master',
      'description': 'حافظ على سلسلة صلواتك',
      'descriptionEn': 'Maintain your prayer streak',
      'emoji': '🔥',
      'category': 'streak',
      'tierThresholds': {'bronze': 7, 'silver': 21, 'gold': 40, 'platinum': 100, 'diamond': 365},
    },
    // Fajr achievements
    {
      'id': 'early_riser',
      'title': 'صائد الفجر',
      'titleEn': 'Early Riser',
      'description': 'صلِّ الفجر في وقتها',
      'descriptionEn': 'Pray Fajr on time',
      'emoji': '☀️',
      'category': 'early',
      'tierThresholds': {'bronze': 7, 'silver': 21, 'gold': 40, 'platinum': 100},
    },
    // Prayer count
    {
      'id': 'prayer_counter',
      'title': 'مصلّي نشط',
      'titleEn': 'Active Worshipper',
      'description': 'أكمل عدداً من الصلوات',
      'descriptionEn': 'Complete prayers',
      'emoji': '🕌',
      'category': 'prayers',
      'tierThresholds': {'bronze': 100, 'silver': 500, 'gold': 1000, 'platinum': 5000},
    },
    // Family
    {
      'id': 'family_builder',
      'title': 'باني العائلة',
      'titleEn': 'Family Builder',
      'description': 'أضف أفراداً للعائلة',
      'descriptionEn': 'Add family members',
      'emoji': '👨‍👩‍👧‍👦',
      'category': 'family',
      'tierThresholds': {'bronze': 3, 'silver': 5, 'gold': 10, 'platinum': 20},
    },
    // Social
    {
      'id': 'encourager',
      'title': 'المشجع',
      'titleEn': 'The Encourager',
      'description': 'شجّع الآخرين',
      'descriptionEn': 'Encourage others',
      'emoji': '💪',
      'category': 'social',
      'tierThresholds': {'bronze': 10, 'silver': 50, 'gold': 100, 'platinum': 500},
    },
  ];
}
