import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/prayer_time_service.dart';

/// Prayer log model for tracking prayer completion
class PrayerLogModel {
  final String id;
  final String oderId;
  final PrayerName prayer;
  final DateTime prayedAt;
  final DateTime adhanTime;
  final PrayerQuality quality;
  final String? addedByLeaderId; // If leader added manually
  final String? note;

  PrayerLogModel({
    required this.id,
    required this.oderId,
    required this.prayer,
    required this.prayedAt,
    required this.adhanTime,
    required this.quality,
    this.addedByLeaderId,
    this.note,
  });

  /// Check if this was added by a leader
  bool get wasAddedByLeader => addedByLeaderId != null;

  /// Get time difference in minutes
  int get minutesAfterAdhan => prayedAt.difference(adhanTime).inMinutes;

  /// Create from Firestore document
  factory PrayerLogModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return PrayerLogModel(
      id: doc.id,
      oderId: data['oderId'] ?? '',
      prayer: _parsePrayerName(data['prayer'] ?? 'fajr'),
      prayedAt: (data['prayedAt'] as Timestamp).toDate(),
      adhanTime: (data['adhanTime'] as Timestamp).toDate(),
      quality: _parsePrayerQuality(data['quality'] ?? 'onTime'),
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

/// Daily prayers summary
class DailyPrayersSummary {
  final DateTime date;
  final Map<PrayerName, PrayerLogModel?> prayers;

  DailyPrayersSummary({
    required this.date,
    required this.prayers,
  });

  /// Get completed prayers count
  int get completedCount => prayers.values.where((p) => p != null).length;

  /// Get total prayers (excluding sunrise)
  int get totalPrayers => 5;

  /// Get completion percentage
  double get completionPercentage => completedCount / totalPrayers;

  /// Check if all prayers completed
  bool get isComplete => completedCount == totalPrayers;

  /// Get early prayers count
  int get earlyCount => prayers.values
      .where((p) => p != null && p.quality == PrayerQuality.early)
      .length;

  /// Create empty summary for a date
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
