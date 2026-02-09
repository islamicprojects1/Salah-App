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

  /// Create from Firestore map (handles both Timestamp and String for cache)
  factory MemberModel.fromMap(Map<String, dynamic> map) {
    DateTime joinedAt;
    if (map['joinedAt'] is Timestamp) {
      joinedAt = (map['joinedAt'] as Timestamp).toDate();
    } else if (map['joinedAt'] is String) {
      joinedAt = DateTime.parse(map['joinedAt']);
    } else {
      joinedAt = DateTime.now();
    }
    
    return MemberModel(
      userId: map['userId'] ?? '',
      role: _parseRole(map['role']),
      joinedAt: joinedAt,
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

  /// Convert to JSON-safe map for local cache (no Timestamp)
  Map<String, dynamic> toJsonCache() {
    return {
      'userId': userId,
      'role': role.name,
      'joinedAt': joinedAt.toIso8601String(),
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
    return FamilyModel.fromMap(doc.data()!, doc.id);
  }

  /// Create from map (for both Firestore and cache)
  factory FamilyModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime createdAt;
    if (data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      createdAt = DateTime.parse(data['createdAt']);
    } else {
      createdAt = DateTime.now();
    }
    
    return FamilyModel(
      id: id,
      name: data['name'] ?? '',
      inviteCode: data['inviteCode'] ?? '',
      adminId: data['adminId'] ?? '',
      members: (data['members'] as List<dynamic>?)
              ?.map((m) => MemberModel.fromMap(m as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: createdAt,
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

  /// Convert to JSON-safe map for local cache (no Timestamp)
  Map<String, dynamic> toJsonCache() {
    return {
      'id': id,
      'name': name,
      'inviteCode': inviteCode,
      'adminId': adminId,
      'members': members.map((m) => m.toJsonCache()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
