import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salah/core/constants/enums.dart';

/// Challenge model for Firestore
class ChallengeModel {
  final String id;
  final String title;
  final String titleEn;
  final String description;
  final String descriptionEn;
  final ChallengeType type;
  final String? targetPrayer;    // للتحديات الخاصة بصلاة معينة
  final int targetValue;
  final DateTime startDate;
  final DateTime endDate;
  final String badge;
  final int rewardPoints;
  final bool isGlobal;           // تحدي عالمي أم خاص
  final String? groupId;         // للتحديات الجماعية
  final String? createdBy;       // المنشئ
  final DateTime createdAt;
  final bool isActive;
  final int participantsCount;

  ChallengeModel({
    required this.id,
    required this.title,
    required this.titleEn,
    required this.description,
    required this.descriptionEn,
    required this.type,
    this.targetPrayer,
    required this.targetValue,
    required this.startDate,
    required this.endDate,
    required this.badge,
    this.rewardPoints = 100,
    this.isGlobal = true,
    this.groupId,
    this.createdBy,
    required this.createdAt,
    this.isActive = true,
    this.participantsCount = 0,
  });

  /// Create from Firestore document
  factory ChallengeModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ChallengeModel(
      id: doc.id,
      title: data['title'] ?? '',
      titleEn: data['titleEn'] ?? '',
      description: data['description'] ?? '',
      descriptionEn: data['descriptionEn'] ?? '',
      type: _parseType(data['type']),
      targetPrayer: data['targetPrayer'],
      targetValue: data['targetValue'] ?? 0,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      badge: data['badge'] ?? '🏆',
      rewardPoints: data['rewardPoints'] ?? 100,
      isGlobal: data['isGlobal'] ?? true,
      groupId: data['groupId'],
      createdBy: data['createdBy'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      participantsCount: data['participantsCount'] ?? 0,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'titleEn': titleEn,
      'description': description,
      'descriptionEn': descriptionEn,
      'type': type.name,
      'targetPrayer': targetPrayer,
      'targetValue': targetValue,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'badge': badge,
      'rewardPoints': rewardPoints,
      'isGlobal': isGlobal,
      'groupId': groupId,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'participantsCount': participantsCount,
    };
  }

  /// Get challenge status
  ChallengeStatus get status {
    final now = DateTime.now();
    if (now.isBefore(startDate)) return ChallengeStatus.upcoming;
    if (now.isAfter(endDate)) return ChallengeStatus.expired;
    return ChallengeStatus.active;
  }

  /// Get remaining days
  int get remainingDays {
    final now = DateTime.now();
    return endDate.difference(now).inDays;
  }

  /// Create a copy with updated fields
  ChallengeModel copyWith({
    String? title,
    String? titleEn,
    String? description,
    String? descriptionEn,
    ChallengeType? type,
    String? targetPrayer,
    int? targetValue,
    DateTime? startDate,
    DateTime? endDate,
    String? badge,
    int? rewardPoints,
    bool? isGlobal,
    String? groupId,
    bool? isActive,
    int? participantsCount,
  }) {
    return ChallengeModel(
      id: id,
      title: title ?? this.title,
      titleEn: titleEn ?? this.titleEn,
      description: description ?? this.description,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      type: type ?? this.type,
      targetPrayer: targetPrayer ?? this.targetPrayer,
      targetValue: targetValue ?? this.targetValue,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      badge: badge ?? this.badge,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      isGlobal: isGlobal ?? this.isGlobal,
      groupId: groupId ?? this.groupId,
      createdBy: createdBy,
      createdAt: createdAt,
      isActive: isActive ?? this.isActive,
      participantsCount: participantsCount ?? this.participantsCount,
    );
  }

  static ChallengeType _parseType(String? type) {
    switch (type) {
      case 'consecutivePrayer':
        return ChallengeType.consecutivePrayer;
      case 'consecutiveStreak':
        return ChallengeType.consecutiveStreak;
      case 'totalPrayers':
        return ChallengeType.totalPrayers;
      case 'fullCompletion':
        return ChallengeType.fullCompletion;
      case 'earlyPrayer':
        return ChallengeType.earlyPrayer;
      case 'familyGoal':
        return ChallengeType.familyGoal;
      case 'groupGoal':
        return ChallengeType.groupGoal;
      case 'nightPrayer':
        return ChallengeType.nightPrayer;
      default:
        return ChallengeType.custom;
    }
  }
}

/// User's progress in a challenge
class UserChallengeProgress {
  final String id;
  final String challengeId;
  final String userId;
  final int currentProgress;
  final int targetValue;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime joinedAt;
  final int rewardPointsEarned;

  UserChallengeProgress({
    required this.id,
    required this.challengeId,
    required this.userId,
    required this.currentProgress,
    required this.targetValue,
    this.isCompleted = false,
    this.completedAt,
    required this.joinedAt,
    this.rewardPointsEarned = 0,
  });

  /// Progress percentage
  double get progressPercentage => (currentProgress / targetValue).clamp(0.0, 1.0);

  /// Create from Firestore document
  factory UserChallengeProgress.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserChallengeProgress(
      id: doc.id,
      challengeId: data['challengeId'] ?? '',
      userId: data['userId'] ?? '',
      currentProgress: data['currentProgress'] ?? 0,
      targetValue: data['targetValue'] ?? 0,
      isCompleted: data['isCompleted'] ?? false,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      joinedAt: (data['joinedAt'] as Timestamp).toDate(),
      rewardPointsEarned: data['rewardPointsEarned'] ?? 0,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'challengeId': challengeId,
      'userId': userId,
      'currentProgress': currentProgress,
      'targetValue': targetValue,
      'isCompleted': isCompleted,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'rewardPointsEarned': rewardPointsEarned,
    };
  }
}
