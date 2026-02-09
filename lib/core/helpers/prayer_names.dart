import 'package:salah/core/services/prayer_time_service.dart';
import 'package:salah/data/models/prayer_log_model.dart';

/// Single source of truth for prayer name ↔ enum mapping and "is logged" logic.
/// Use everywhere instead of duplicated switches and string literals.
class PrayerNames {
  PrayerNames._();

  /// Arabic display names (default locale for the app).
  static const Map<PrayerName, String> _arNames = {
    PrayerName.fajr: 'الفجر',
    PrayerName.sunrise: 'الشروق',
    PrayerName.dhuhr: 'الظهر',
    PrayerName.asr: 'العصر',
    PrayerName.maghrib: 'المغرب',
    PrayerName.isha: 'العشاء',
  };

  /// Display name for a prayer (Arabic).
  static String displayName(PrayerName prayer) {
    return _arNames[prayer] ?? prayer.name;
  }

  /// Parse display name (Arabic or enum name) to [PrayerName].
  static PrayerName fromDisplayName(String name) {
    final trimmed = name.trim().toLowerCase();
    for (final e in _arNames.entries) {
      if (e.value == name.trim() || e.value.toLowerCase() == trimmed) return e.key;
    }
    for (final p in PrayerName.values) {
      if (p.name == trimmed) return p;
    }
    return PrayerName.fajr;
  }

  /// Whether the given prayer is already in the logs (by name or enum, including sunrise).
  static bool isPrayerLogged(
    List<PrayerLogModel> logs,
    String prayerDisplayName,
    PrayerName? prayerType,
  ) {
    final nameLower = prayerDisplayName.trim().toLowerCase();
    return logs.any((l) {
      if (prayerType != null && l.prayer == prayerType) return true;
      return displayName(l.prayer).trim().toLowerCase() == nameLower ||
          l.prayer.name.toLowerCase() == nameLower;
    });
  }
}
