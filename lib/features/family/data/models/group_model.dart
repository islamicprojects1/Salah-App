import 'package:cloud_firestore/cloud_firestore.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// GROUP MODEL
// المسار: lib/features/family/data/models/group_model.dart
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

enum GroupType { family, guided, friends }

extension GroupTypeX on GroupType {
  String get value {
    switch (this) {
      case GroupType.family:
        return 'family';
      case GroupType.guided:
        return 'guided';
      case GroupType.friends:
        return 'friends';
    }
  }

  static GroupType fromString(String? v) {
    switch (v) {
      case 'guided':
        return GroupType.guided;
      case 'friends':
        return GroupType.friends;
      default:
        return GroupType.family;
    }
  }
}

class GroupModel {
  final String groupId;
  final String name;
  final GroupType type;
  final String inviteCode;
  final DateTime createdAt;
  final String createdBy;
  final String adminId;
  final DateTime? lastAdminActivity;
  final List<String> blockedUserIds;
  final List<String> memberIds;
  final int memberCount;

  const GroupModel({
    required this.groupId,
    required this.name,
    required this.type,
    required this.inviteCode,
    required this.createdAt,
    required this.createdBy,
    required this.adminId,
    this.lastAdminActivity,
    this.blockedUserIds = const [],
    this.memberIds = const [],
    this.memberCount = 0,
  });

  factory GroupModel.fromMap(Map<String, dynamic> map, String id) {
    return GroupModel(
      groupId: id,
      name: map['name'] as String? ?? '',
      type: GroupTypeX.fromString(map['type'] as String?),
      inviteCode: map['inviteCode'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: map['createdBy'] as String? ?? '',
      adminId: map['adminId'] as String? ?? '',
      lastAdminActivity: (map['lastAdminActivity'] as Timestamp?)?.toDate(),
      blockedUserIds: List<String>.from(map['blockedUserIds'] ?? []),
      memberIds: List<String>.from(map['memberIds'] ?? []),
      memberCount: (map['memberCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type.value,
      'inviteCode': inviteCode,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'adminId': adminId,
      'lastAdminActivity': lastAdminActivity != null
          ? Timestamp.fromDate(lastAdminActivity!)
          : FieldValue.serverTimestamp(),
      'blockedUserIds': blockedUserIds,
      'memberIds': memberIds,
      'memberCount': memberCount,
    };
  }

  GroupModel copyWith({
    String? name,
    GroupType? type,
    String? inviteCode,
    String? adminId,
    DateTime? lastAdminActivity,
    List<String>? blockedUserIds,
    List<String>? memberIds,
    int? memberCount,
  }) {
    return GroupModel(
      groupId: groupId,
      name: name ?? this.name,
      type: type ?? this.type,
      inviteCode: inviteCode ?? this.inviteCode,
      createdAt: createdAt,
      createdBy: createdBy,
      adminId: adminId ?? this.adminId,
      lastAdminActivity: lastAdminActivity ?? this.lastAdminActivity,
      blockedUserIds: blockedUserIds ?? this.blockedUserIds,
      memberIds: memberIds ?? this.memberIds,
      memberCount: memberCount ?? this.memberCount,
    );
  }
}
