import 'package:cloud_firestore/cloud_firestore.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MEMBER MODEL
// المسار: lib/features/family/data/models/member_model.dart
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class MemberModel {
  final String userId;
  final String role; // 'admin' | 'member'
  final String displayName;
  final DateTime joinedAt;
  final bool isShadow;
  final String? shadowContactHint;
  final bool isActive;
  // Per-member prayer status for today (reset daily)
  final String? todayPrayersDate; // "YYYY-MM-DD"
  final List<String> todayPrayers; // ['fajr', 'dhuhr', ...]

  const MemberModel({
    required this.userId,
    required this.role,
    required this.displayName,
    required this.joinedAt,
    this.isShadow = false,
    this.shadowContactHint,
    this.isActive = true,
    this.todayPrayersDate,
    this.todayPrayers = const [],
  });

  bool get isAdmin => role == 'admin';

  factory MemberModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return MemberModel(
      userId: id,
      role: map['role'] as String? ?? 'member',
      displayName: map['displayName'] as String? ?? '',
      joinedAt: parseDate(map['joinedAt']),
      isShadow: map['isShadow'] as bool? ?? false,
      shadowContactHint: map['shadowContactHint'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      todayPrayersDate: map['todayPrayersDate'] as String?,
      todayPrayers: (map['todayPrayers'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'displayName': displayName,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'isShadow': isShadow,
      if (shadowContactHint != null) 'shadowContactHint': shadowContactHint,
      'isActive': isActive,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'displayName': displayName,
      'joinedAt': joinedAt.toIso8601String(),
      'isShadow': isShadow,
      if (shadowContactHint != null) 'shadowContactHint': shadowContactHint,
      'isActive': isActive,
    };
  }

  MemberModel copyWith({
    String? role,
    String? displayName,
    bool? isShadow,
    String? shadowContactHint,
    bool? isActive,
    String? todayPrayersDate,
    List<String>? todayPrayers,
  }) {
    return MemberModel(
      userId: userId,
      role: role ?? this.role,
      displayName: displayName ?? this.displayName,
      joinedAt: joinedAt,
      isShadow: isShadow ?? this.isShadow,
      shadowContactHint: shadowContactHint ?? this.shadowContactHint,
      isActive: isActive ?? this.isActive,
      todayPrayersDate: todayPrayersDate ?? this.todayPrayersDate,
      todayPrayers: todayPrayers ?? this.todayPrayers,
    );
  }

  /// Returns today's prayers if `todayPrayersDate` matches [today],
  /// otherwise returns empty (date has changed = stale data).
  List<String> getTodayPrayers(String today) {
    if (todayPrayersDate != today) return const [];
    return todayPrayers;
  }
}
