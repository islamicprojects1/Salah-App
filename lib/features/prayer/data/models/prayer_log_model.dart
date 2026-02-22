import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salah/core/constants/enums.dart';

/// Prayer log model for tracking prayer completion
class PrayerLogModel {
  final String id;

  /// Owner/user id. Note: field name is "oderId" (legacy typo) in Firestore/DB for compatibility.
  final String oderId;
  final PrayerName prayer;
  final DateTime prayedAt;
  final DateTime adhanTime;
  final PrayerQuality quality; // Legacy quality (for backward compatibility)
  final PrayerTimingQuality? timingQuality; // New detailed timing quality
  final String? addedByLeaderId; // If leader added manually
  final String? note;

  PrayerLogModel({
    required this.id,
    required this.oderId,
    required this.prayer,
    required this.prayedAt,
    required this.adhanTime,
    required this.quality,
    this.timingQuality,
    this.addedByLeaderId,
    this.note,
  });

  /// Check if this was added by a leader
  bool get wasAddedByLeader => addedByLeaderId != null;

  /// Get time difference in minutes
  int get minutesAfterAdhan => prayedAt.difference(adhanTime).inMinutes;

  /// Create from Firestore document
  factory PrayerLogModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return PrayerLogModel(
      id: doc.id,
      oderId: data['oderId'] ?? '',
      prayer: _parsePrayerName(data['prayer'] ?? 'fajr'),
      prayedAt: (data['prayedAt'] as Timestamp).toDate(),
      adhanTime: (data['adhanTime'] as Timestamp).toDate(),
      quality: _parsePrayerQuality(data['quality'] ?? 'onTime'),
      timingQuality: data['timingQuality'] != null
          ? _parsePrayerTimingQuality(data['timingQuality'])
          : null,
      addedByLeaderId: data['addedByLeaderId'],
      note: data['note'],
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'oderId': oderId,
      'prayer': prayer.name,
      'prayedAt': Timestamp.fromDate(prayedAt),
      'adhanTime': Timestamp.fromDate(adhanTime),
      'quality': quality.name,
      'timingQuality': timingQuality?.name,
      'addedByLeaderId': addedByLeaderId,
      'note': note,
    };
  }

  /// Convert to Map for local database (SQLite)
  /// Uses ISO8601 strings for dates instead of Timestamps
  Map<String, dynamic> toMap() {
    return {
      'oderId': oderId,
      'prayer': prayer.name,
      'prayedAt': prayedAt.toIso8601String(),
      'adhanTime': adhanTime.toIso8601String(),
      'quality': quality.name,
      'timingQuality': timingQuality?.name,
      'addedByLeaderId': addedByLeaderId,
      'note': note,
    };
  }

  /// Parse prayer name from string
  static PrayerName _parsePrayerName(String name) {
    switch (name.toLowerCase()) {
      case 'fajr':
        return PrayerName.fajr;
      case 'sunrise':
        return PrayerName.sunrise;
      case 'dhuhr':
        return PrayerName.dhuhr;
      case 'asr':
        return PrayerName.asr;
      case 'maghrib':
        return PrayerName.maghrib;
      case 'isha':
        return PrayerName.isha;
      default:
        return PrayerName.fajr;
    }
  }

  /// Parse prayer quality from string
  static PrayerQuality _parsePrayerQuality(String quality) {
    switch (quality.toLowerCase()) {
      case 'early':
        return PrayerQuality.early;
      case 'ontime':
        return PrayerQuality.onTime;
      case 'late':
        return PrayerQuality.late;
      case 'missed':
        return PrayerQuality.missed;
      default:
        return PrayerQuality.onTime;
    }
  }

  /// Parse prayer timing quality from string
  static PrayerTimingQuality _parsePrayerTimingQuality(String quality) {
    switch (quality.toLowerCase()) {
      case 'veryearly':
        return PrayerTimingQuality.veryEarly;
      case 'early':
        return PrayerTimingQuality.early;
      case 'ontime':
        return PrayerTimingQuality.onTime;
      case 'late':
        return PrayerTimingQuality.late;
      case 'verylate':
        return PrayerTimingQuality.veryLate;
      case 'missed':
        return PrayerTimingQuality.missed;
      case 'notyet':
        return PrayerTimingQuality.notYet;
      default:
        return PrayerTimingQuality.onTime;
    }
  }

  /// Create a new prayer log
  factory PrayerLogModel.create({
    required String oderId,
    required PrayerName prayer,
    required DateTime adhanTime,
    String? addedByLeaderId,
    String? note,
  }) {
    final prayedAt = DateTime.now();

    // Calculate quality
    final minutesDiff = prayedAt.difference(adhanTime).inMinutes;
    PrayerQuality quality;
    if (minutesDiff <= 15) {
      quality = PrayerQuality.early;
    } else if (minutesDiff <= 30) {
      quality = PrayerQuality.onTime;
    } else {
      quality = PrayerQuality.late;
    }

    return PrayerLogModel(
      id: '', // Will be set by Firestore
      oderId: oderId,
      prayer: prayer,
      prayedAt: prayedAt,
      adhanTime: adhanTime,
      quality: quality,
      addedByLeaderId: addedByLeaderId,
      note: note,
    );
  }
}

/// Daily prayers summary — single source of truth for a day's prayer status.
///
/// Replaces the former `DaySummary` from live_context_models.dart.
class DailyPrayersSummary {
  final DateTime date;
  final Map<PrayerName, PrayerLogModel?> prayers;

  const DailyPrayersSummary({required this.date, required this.prayers});

  /// Completed prayers count.
  int get completedCount => prayers.values.where((p) => p != null).length;

  /// Total obligatory prayers (excluding sunrise).
  int get totalPrayers => 5;

  /// Completion as a ratio (0.0 – 1.0).
  double get completionRatio =>
      totalPrayers == 0 ? 0 : completedCount / totalPrayers;

  /// Completion as a percentage (0.0 – 1.0). Alias for [completionRatio].
  double get completionPercentage => completionRatio;

  /// Whether all obligatory prayers are completed.
  bool get isComplete => completedCount == totalPrayers;

  /// Number of prayers logged early.
  int get earlyCount => prayers.values
      .where((p) => p != null && p.quality == PrayerQuality.early)
      .length;

  /// Number of prayers logged early or on time.
  int get onTimeCount => prayers.values
      .where(
        (p) =>
            p != null &&
            (p.quality == PrayerQuality.early ||
                p.quality == PrayerQuality.onTime),
      )
      .length;

  /// Create empty summary for a date.
  factory DailyPrayersSummary.empty(DateTime date) {
    return DailyPrayersSummary(
      date: date,
      prayers: {
        PrayerName.fajr: null,
        PrayerName.dhuhr: null,
        PrayerName.asr: null,
        PrayerName.maghrib: null,
        PrayerName.isha: null,
      },
    );
  }
}
