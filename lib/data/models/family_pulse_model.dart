import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/helpers/prayer_names.dart';

/// A single event in the family pulse (who prayed, who encouraged, etc.)
class FamilyPulseEvent {
  final String id;
  final PulseEventType type;
  final String userId;
  final String userName;
  final String? prayerName;
  final DateTime timestamp;

  FamilyPulseEvent({
    required this.id,
    required this.type,
    required this.userId,
    required this.userName,
    this.prayerName,
    required this.timestamp,
  });

  factory FamilyPulseEvent.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return FamilyPulseEvent(
      id: doc.id,
      type: _parseType(data['type'] as String?),
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      prayerName: data['prayer'] as String?,
      timestamp: data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  static PulseEventType _parseType(String? t) {
    switch (t) {
      case 'encouragement':
        return PulseEventType.encouragement;
      case 'daily_complete':
        return PulseEventType.dailyComplete;
      default:
        return PulseEventType.prayerLogged;
    }
  }

  /// Short text for list (e.g. "أحمد صلى العصر")
  String get displayText {
    switch (type) {
      case PulseEventType.prayerLogged:
        if (prayerName == null) return '$userName سجّل صلاة';
        final pName = _prayerKeyToDisplayName(prayerName!);
        return '$userName صلى $pName';
      case PulseEventType.encouragement:
        return '$userName شجّع على الصلاة';
      case PulseEventType.dailyComplete:
        return '$userName أكمل صلوات اليوم 🎉';
    }
  }

  static String _prayerKeyToDisplayName(String key) {
    final k = key.toLowerCase();
    if (k == 'fajr') return PrayerNames.displayName(PrayerName.fajr);
    if (k == 'dhuhr') return PrayerNames.displayName(PrayerName.dhuhr);
    if (k == 'asr') return PrayerNames.displayName(PrayerName.asr);
    if (k == 'maghrib') return PrayerNames.displayName(PrayerName.maghrib);
    if (k == 'isha') return PrayerNames.displayName(PrayerName.isha);
    return key;
  }
}
