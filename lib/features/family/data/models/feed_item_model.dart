import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salah/core/constants/enums.dart';

/// Feed item model for social timeline
class FeedItemModel {
  final String id;
  final FeedItemType type;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String? groupId;
  final Map<String, dynamic> data;  // نوع مختلف حسب النوع
  final DateTime createdAt;
  final Map<ReactionType, int> reactionCounts;
  final List<String> reactedUserIds;
  final bool isPublic;

  FeedItemModel({
    required this.id,
    required this.type,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    this.groupId,
    required this.data,
    required this.createdAt,
    this.reactionCounts = const {},
    this.reactedUserIds = const [],
    this.isPublic = true,
  });

  /// Total reactions count
  int get totalReactions => reactionCounts.values.fold(0, (a, b) => a + b);

  /// Create from Firestore document
  factory FeedItemModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return FeedItemModel(
      id: doc.id,
      type: _parseType(data['type']),
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhotoUrl: data['userPhotoUrl'],
      groupId: data['groupId'],
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      reactionCounts: _parseReactionCounts(data['reactionCounts']),
      reactedUserIds: List<String>.from(data['reactedUserIds'] ?? []),
      isPublic: data['isPublic'] ?? true,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'type': type.name,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'groupId': groupId,
      'data': data,
      'createdAt': Timestamp.fromDate(createdAt),
      'reactionCounts': reactionCounts.map((k, v) => MapEntry(k.name, v)),
      'reactedUserIds': reactedUserIds,
      'isPublic': isPublic,
    };
  }

  /// Get display text based on type
  String getDisplayText(String language) {
    final isArabic = language == 'ar';
    
    switch (type) {
      case FeedItemType.prayerLogged:
        final prayer = data['prayer'] ?? '';
        return isArabic 
            ? 'سجّل صلاة $prayer'
            : 'Logged $prayer prayer';
            
      case FeedItemType.streakMilestone:
        final days = data['days'] ?? 0;
        return isArabic 
            ? 'أكمل $days يوم متتالي! 🔥'
            : 'Completed $days day streak! 🔥';
            
      case FeedItemType.challengeCompleted:
        final challenge = data['challengeTitle'] ?? '';
        return isArabic 
            ? 'أتم تحدي "$challenge" 🏆'
            : 'Completed "$challenge" challenge 🏆';
            
      case FeedItemType.achievementUnlocked:
        final achievement = data['achievementTitle'] ?? '';
        final tier = data['tier'] ?? '';
        return isArabic 
            ? 'حصل على وسام "$achievement" ($tier)'
            : 'Unlocked "$achievement" badge ($tier)';
            
      case FeedItemType.familyJoined:
        final family = data['familyName'] ?? '';
        return isArabic 
            ? 'انضم لعائلة "$family"'
            : 'Joined "$family" family';
            
      case FeedItemType.groupJoined:
        final group = data['groupName'] ?? '';
        return isArabic 
            ? 'انضم لمجموعة "$group"'
            : 'Joined "$group" group';
            
      case FeedItemType.encouragement:
        final sender = data['senderName'] ?? '';
        return isArabic 
            ? 'تلقى تشجيعاً من $sender'
            : 'Received encouragement from $sender';
            
      case FeedItemType.milestone:
        final milestone = data['milestone'] ?? '';
        return isArabic 
            ? milestone
            : data['milestoneEn'] ?? milestone;
    }
  }

  static FeedItemType _parseType(String? type) {
    switch (type) {
      case 'prayerLogged':
        return FeedItemType.prayerLogged;
      case 'streakMilestone':
        return FeedItemType.streakMilestone;
      case 'challengeCompleted':
        return FeedItemType.challengeCompleted;
      case 'achievementUnlocked':
        return FeedItemType.achievementUnlocked;
      case 'familyJoined':
        return FeedItemType.familyJoined;
      case 'groupJoined':
        return FeedItemType.groupJoined;
      case 'encouragement':
        return FeedItemType.encouragement;
      default:
        return FeedItemType.milestone;
    }
  }

  static Map<ReactionType, int> _parseReactionCounts(Map<String, dynamic>? data) {
    if (data == null) return {};
    
    final result = <ReactionType, int>{};
    data.forEach((key, value) {
      final type = _parseReactionType(key);
      if (type != null && value is int) {
        result[type] = value;
      }
    });
    return result;
  }

  static ReactionType? _parseReactionType(String? type) {
    switch (type) {
      case 'like':
        return ReactionType.like;
      case 'celebrate':
        return ReactionType.celebrate;
      case 'pray':
        return ReactionType.pray;
      case 'encourage':
        return ReactionType.encourage;
      case 'love':
        return ReactionType.love;
      default:
        return null;
    }
  }
}

/// Reaction model
class ReactionModel {
  final String id;
  final String feedItemId;
  final String userId;
  final String userName;
  final ReactionType type;
  final DateTime createdAt;

  ReactionModel({
    required this.id,
    required this.feedItemId,
    required this.userId,
    required this.userName,
    required this.type,
    required this.createdAt,
  });

  /// Create from Firestore document
  factory ReactionModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ReactionModel(
      id: doc.id,
      feedItemId: data['feedItemId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      type: FeedItemModel._parseReactionType(data['type']) ?? ReactionType.like,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'feedItemId': feedItemId,
      'userId': userId,
      'userName': userName,
      'type': type.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
