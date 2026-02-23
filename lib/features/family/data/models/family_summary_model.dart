import 'package:cloud_firestore/cloud_firestore.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// FAMILY SUMMARY MODEL
// المسار: lib/features/family/data/models/family_summary_model.dart
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class FamilySummaryModel {
  final String date; // "2026-02-22"
  final int prayedCount; // X
  final int totalMembers; // Y
  final DateTime? updatedAt;

  const FamilySummaryModel({
    required this.date,
    required this.prayedCount,
    required this.totalMembers,
    this.updatedAt,
  });

  double get completionRatio =>
      totalMembers == 0 ? 0 : (prayedCount / totalMembers).clamp(0.0, 1.0);

  bool get isAllPrayed => totalMembers > 0 && prayedCount >= totalMembers;

  factory FamilySummaryModel.fromMap(Map<String, dynamic> map, String date) {
    DateTime? parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    return FamilySummaryModel(
      date: date,
      prayedCount: (map['prayedCount'] as num?)?.toInt() ?? 0,
      totalMembers: (map['totalMembers'] as num?)?.toInt() ?? 0,
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'prayedCount': prayedCount,
      'totalMembers': totalMembers,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'prayedCount': prayedCount,
      'totalMembers': totalMembers,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
