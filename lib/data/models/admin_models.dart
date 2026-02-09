import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin role enum
enum AdminRole {
  superAdmin,    // كل الصلاحيات
  admin,         // كل شيء ما عدا حذف admins
  moderator,     // Reports + Users
  support,       // قراءة فقط + Reports
  analyst,       // Analytics فقط
}

/// Admin user model
class AdminUserModel {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final AdminRole role;
  final List<String> permissions;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;
  final String? createdBy;

  AdminUserModel({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.role,
    this.permissions = const [],
    required this.createdAt,
    this.lastLoginAt,
    this.isActive = true,
    this.createdBy,
  });

  /// Get role display name
  String get roleDisplayName {
    switch (role) {
      case AdminRole.superAdmin:
        return 'Super Admin';
      case AdminRole.admin:
        return 'Admin';
      case AdminRole.moderator:
        return 'Moderator';
      case AdminRole.support:
        return 'Support';
      case AdminRole.analyst:
        return 'Analyst';
    }
  }

  /// Check if user has permission
  bool hasPermission(String permission) {
    if (role == AdminRole.superAdmin) return true;
    return permissions.contains(permission);
  }

  /// Create from Firestore document
  factory AdminUserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AdminUserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
      role: _parseRole(data['role']),
      permissions: List<String>.from(data['permissions'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLoginAt: data['lastLoginAt'] != null
          ? (data['lastLoginAt'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] ?? true,
      createdBy: data['createdBy'],
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'role': role.name,
      'permissions': permissions,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'isActive': isActive,
      'createdBy': createdBy,
    };
  }

  static AdminRole _parseRole(String? role) {
    switch (role) {
      case 'superAdmin':
        return AdminRole.superAdmin;
      case 'admin':
        return AdminRole.admin;
      case 'moderator':
        return AdminRole.moderator;
      case 'support':
        return AdminRole.support;
      case 'analyst':
        return AdminRole.analyst;
      default:
        return AdminRole.support;
    }
  }
}

/// Admin permissions constants
class AdminPermissions {
  static const String viewUsers = 'view_users';
  static const String editUsers = 'edit_users';
  static const String deleteUsers = 'delete_users';
  static const String suspendUsers = 'suspend_users';
  
  static const String viewFamilies = 'view_families';
  static const String editFamilies = 'edit_families';
  
  static const String sendNotifications = 'send_notifications';
  static const String scheduledNotifications = 'scheduled_notifications';
  
  static const String viewChallenges = 'view_challenges';
  static const String createChallenges = 'create_challenges';
  static const String deleteChallenges = 'delete_challenges';
  
  static const String viewAnalytics = 'view_analytics';
  static const String exportAnalytics = 'export_analytics';
  
  static const String viewReports = 'view_reports';
  static const String resolveReports = 'resolve_reports';
  
  static const String editContent = 'edit_content';
  static const String editAppConfig = 'edit_app_config';
  static const String manageAdmins = 'manage_admins';

  /// Get all permissions for a role
  static List<String> getPermissionsForRole(AdminRole role) {
    switch (role) {
      case AdminRole.superAdmin:
        return [
          viewUsers, editUsers, deleteUsers, suspendUsers,
          viewFamilies, editFamilies,
          sendNotifications, scheduledNotifications,
          viewChallenges, createChallenges, deleteChallenges,
          viewAnalytics, exportAnalytics,
          viewReports, resolveReports,
          editContent, editAppConfig, manageAdmins,
        ];
      case AdminRole.admin:
        return [
          viewUsers, editUsers, suspendUsers,
          viewFamilies, editFamilies,
          sendNotifications, scheduledNotifications,
          viewChallenges, createChallenges,
          viewAnalytics, exportAnalytics,
          viewReports, resolveReports,
          editContent, editAppConfig,
        ];
      case AdminRole.moderator:
        return [
          viewUsers, suspendUsers,
          viewFamilies,
          viewChallenges,
          viewReports, resolveReports,
        ];
      case AdminRole.support:
        return [
          viewUsers,
          viewFamilies,
          viewReports,
        ];
      case AdminRole.analyst:
        return [
          viewAnalytics, exportAnalytics,
        ];
    }
  }
}

/// App configuration model
class AppConfigModel {
  final bool maintenanceMode;
  final String maintenanceMessage;
  final String maintenanceMessageEn;
  final String minAppVersion;
  final String latestAppVersion;
  final String updateUrl;
  final Map<String, bool> featureFlags;
  final String defaultCalculationMethod;
  final String defaultMadhab;
  final bool globalNotificationsEnabled;
  final Map<String, bool> notificationTypes;
  final DateTime lastUpdated;
  final String? updatedBy;

  AppConfigModel({
    this.maintenanceMode = false,
    this.maintenanceMessage = 'التطبيق تحت الصيانة',
    this.maintenanceMessageEn = 'App is under maintenance',
    this.minAppVersion = '1.0.0',
    this.latestAppVersion = '1.0.0',
    this.updateUrl = '',
    this.featureFlags = const {},
    this.defaultCalculationMethod = 'muslimWorldLeague',
    this.defaultMadhab = 'shafi',
    this.globalNotificationsEnabled = true,
    this.notificationTypes = const {},
    required this.lastUpdated,
    this.updatedBy,
  });

  /// Check if feature is enabled
  bool isFeatureEnabled(String feature) => featureFlags[feature] ?? false;

  /// Create from Firestore document
  factory AppConfigModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AppConfigModel(
      maintenanceMode: data['maintenanceMode'] ?? false,
      maintenanceMessage: data['maintenanceMessage'] ?? 'التطبيق تحت الصيانة',
      maintenanceMessageEn: data['maintenanceMessageEn'] ?? 'App is under maintenance',
      minAppVersion: data['minAppVersion'] ?? '1.0.0',
      latestAppVersion: data['latestAppVersion'] ?? '1.0.0',
      updateUrl: data['updateUrl'] ?? '',
      featureFlags: Map<String, bool>.from(data['featureFlags'] ?? {}),
      defaultCalculationMethod: data['defaultCalculationMethod'] ?? 'muslimWorldLeague',
      defaultMadhab: data['defaultMadhab'] ?? 'shafi',
      globalNotificationsEnabled: data['globalNotificationsEnabled'] ?? true,
      notificationTypes: Map<String, bool>.from(data['notificationTypes'] ?? {}),
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
      updatedBy: data['updatedBy'],
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'maintenanceMode': maintenanceMode,
      'maintenanceMessage': maintenanceMessage,
      'maintenanceMessageEn': maintenanceMessageEn,
      'minAppVersion': minAppVersion,
      'latestAppVersion': latestAppVersion,
      'updateUrl': updateUrl,
      'featureFlags': featureFlags,
      'defaultCalculationMethod': defaultCalculationMethod,
      'defaultMadhab': defaultMadhab,
      'globalNotificationsEnabled': globalNotificationsEnabled,
      'notificationTypes': notificationTypes,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'updatedBy': updatedBy,
    };
  }
}

/// Feature flags constants
class FeatureFlags {
  static const String challengesEnabled = 'challenges_enabled';
  static const String leaderboardEnabled = 'leaderboard_enabled';
  static const String socialFeedEnabled = 'social_feed_enabled';
  static const String groupsEnabled = 'groups_enabled';
  static const String achievementsEnabled = 'achievements_enabled';
  static const String offlineModeEnabled = 'offline_mode_enabled';
  static const String tasbeehEnabled = 'tasbeeh_enabled';
  static const String duaLibraryEnabled = 'dua_library_enabled';
  static const String quranEnabled = 'quran_enabled';
  static const String widgetEnabled = 'widget_enabled';

  /// Default feature flags
  static Map<String, bool> get defaults => {
    challengesEnabled: true,
    leaderboardEnabled: true,
    socialFeedEnabled: true,
    groupsEnabled: false, // Coming soon
    achievementsEnabled: true,
    offlineModeEnabled: true,
    tasbeehEnabled: false,
    duaLibraryEnabled: false,
    quranEnabled: false,
    widgetEnabled: false,
  };
}
