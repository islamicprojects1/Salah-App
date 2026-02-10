import 'dart:convert';

import 'package:salah/core/constants/enums.dart';

/// Single item in the sync queue (SQLite).
class SyncQueueItem {
  final int id;
  final SyncItemType type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final int retryCount;
  final DateTime? lastAttempt;

  SyncQueueItem({
    required this.id,
    required this.type,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
    this.lastAttempt,
  });

  factory SyncQueueItem.fromSqlite(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map['id'] as int,
      type: SyncItemType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => SyncItemType.prayerLog,
      ),
      data: jsonDecode(map['data'] as String) as Map<String, dynamic>,
      createdAt: DateTime.parse(map['created_at'] as String),
      retryCount: map['retry_count'] as int? ?? 0,
      lastAttempt: map['last_attempt'] != null
          ? DateTime.parse(map['last_attempt'] as String)
          : null,
    );
  }
}

/// Result of a sync run for feedback.
class SyncResult {
  final bool success;
  final int synced;
  final int failed;
  final String? message;

  SyncResult({
    required this.success,
    required this.synced,
    required this.failed,
    this.message,
  });
}
