import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salah/core/constants/enums.dart';

/// Group settings model
class GroupSettings {
  final bool showPhotos;
  final bool showNames;
  final bool allowReminders;
  final bool allowEncouragement;

  GroupSettings({
    this.showPhotos = true,
    this.showNames = true,
    this.allowReminders = true,
    this.allowEncouragement = true,
  });

  factory GroupSettings.fromMap(Map<String, dynamic>? data) {
    if (data == null) return GroupSettings();
    return GroupSettings(
      showPhotos: data['showPhotos'] ?? true,
      showNames: data['showNames'] ?? true,
      allowReminders: data['allowReminders'] ?? true,
      allowEncouragement: data['allowEncouragement'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'showPhotos': showPhotos,
      'showNames': showNames,
      'allowReminders': allowReminders,
      'allowEncouragement': allowEncouragement,
    };
  }

  GroupSettings copyWith({
    bool? showPhotos,
    bool? showNames,
    bool? allowReminders,
    bool? allowEncouragement,
  }) {
    return GroupSettings(
      showPhotos: showPhotos ?? this.showPhotos,
      showNames: showNames ?? this.showNames,
      allowReminders: allowReminders ?? this.allowReminders,
      allowEncouragement: allowEncouragement ?? this.allowEncouragement,
    );
  }
}

/// Group model for families and prayer groups
class GroupModel {
  final String id;
  final String name;
  final String? description;
  final GroupType type;
  final String creatorId;
  final String? leaderId; // For guided groups
  final List<String> memberIds;
  final List<String> adminIds; // For family groups (parents)
  final GroupSettings settings;
  final String? inviteCode;
  final DateTime createdAt;
  final DateTime? updatedAt;

  GroupModel({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.creatorId,
    this.leaderId,
    required this.memberIds,
    this.adminIds = const [],
    required this.settings,
    this.inviteCode,
    required this.createdAt,
    this.updatedAt,
  });

  /// Check if user is leader
  bool isLeader(String oderId) => leaderId == oderId;

  /// Check if user is admin (for family groups)
  bool isAdmin(String oderId) => adminIds.contains(oderId);

  /// Check if user is member
  bool isMember(String oderId) => memberIds.contains(oderId);

  /// Check if user can manage settings
  bool canManageSettings(String oderId) {
    switch (type) {
      case GroupType.family:
        return isAdmin(oderId);
      case GroupType.guided:
        return isLeader(oderId);
      case GroupType.friends:
        return false; // No one controls settings in friends group
    }
  }

  /// Check if user can add prayers for others
  bool canAddPrayerForOthers(String oderId) {
    return type == GroupType.guided && isLeader(oderId);
  }

  /// Get member count
  int get memberCount => memberIds.length;

  /// Create from Firestore document
  factory GroupModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return GroupModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      type: _parseGroupType(data['type'] ?? 'friends'),
      creatorId: data['creatorId'] ?? '',
      leaderId: data['leaderId'],
      memberIds: List<String>.from(data['memberIds'] ?? []),
      adminIds: List<String>.from(data['adminIds'] ?? []),
      settings: GroupSettings.fromMap(data['settings']),
      inviteCode: data['inviteCode'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'type': type.name,
      'creatorId': creatorId,
      'leaderId': leaderId,
      'memberIds': memberIds,
      'adminIds': adminIds,
      'settings': settings.toMap(),
      'inviteCode': inviteCode,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Parse group type from string
  static GroupType _parseGroupType(String type) {
    switch (type.toLowerCase()) {
      case 'family':
        return GroupType.family;
      case 'guided':
        return GroupType.guided;
      case 'friends':
      default:
        return GroupType.friends;
    }
  }

  /// Get group type name in Arabic
  String get typeNameArabic {
    switch (type) {
      case GroupType.family:
        return 'عائلتي';
      case GroupType.guided:
        return 'مجموعة بقائد';
      case GroupType.friends:
        return 'أصدقاء';
    }
  }

  /// Get group type name in English
  String get typeNameEnglish {
    switch (type) {
      case GroupType.family:
        return 'Family';
      case GroupType.guided:
        return 'Guided Group';
      case GroupType.friends:
        return 'Friends';
    }
  }

  /// Create a copy with updated fields
  GroupModel copyWith({
    String? name,
    String? description,
    String? leaderId,
    List<String>? memberIds,
    List<String>? adminIds,
    GroupSettings? settings,
    String? inviteCode,
    DateTime? updatedAt,
  }) {
    return GroupModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type,
      creatorId: creatorId,
      leaderId: leaderId ?? this.leaderId,
      memberIds: memberIds ?? this.memberIds,
      adminIds: adminIds ?? this.adminIds,
      settings: settings ?? this.settings,
      inviteCode: inviteCode ?? this.inviteCode,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
