import 'package:cloud_firestore/cloud_firestore.dart';

/// Role of the family member
enum MemberRole {
  parent,
  child,
}

/// Member model representing a user in a family
class MemberModel {
  final String userId;
  final MemberRole role;
  final DateTime joinedAt;
  final String? name; // Cached name for display
  final String? photoUrl; // Cached photo for display

  const MemberModel({
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.name,
    this.photoUrl,
  });

  /// Create from Firestore map
  factory MemberModel.fromMap(Map<String, dynamic> map) {
    return MemberModel(
      userId: map['userId'] ?? '',
      role: _parseRole(map['role']),
      joinedAt: (map['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      name: map['name'],
      photoUrl: map['photoUrl'],
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'role': role.name,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'name': name,
      'photoUrl': photoUrl,
    };
  }

  static MemberRole _parseRole(String? role) {
    return role == 'parent' ? MemberRole.parent : MemberRole.child;
  }
}

/// Family model
class FamilyModel {
  final String id;
  final String name;
  final String inviteCode;
  final String adminId; // User ID of the creator/parent
  final List<MemberModel> members;
  final DateTime createdAt;

  const FamilyModel({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.adminId,
    required this.members,
    required this.createdAt,
  });

  /// Check if user is admin
  bool isAdmin(String userId) => userId == adminId;

  /// Get member by ID
  MemberModel? getMember(String userId) {
    try {
      return members.firstWhere((m) => m.userId == userId);
    } catch (_) {
      return null;
    }
  }

  /// Create from Firestore document
  factory FamilyModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return FamilyModel(
      id: doc.id,
      name: data['name'] ?? '',
      inviteCode: data['inviteCode'] ?? '',
      adminId: data['adminId'] ?? '',
      members: (data['members'] as List<dynamic>?)
              ?.map((m) => MemberModel.fromMap(m as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'inviteCode': inviteCode,
      'adminId': adminId,
      'members': members.map((m) => m.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
