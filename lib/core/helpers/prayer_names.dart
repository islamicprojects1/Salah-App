import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/features/prayer/data/models/prayer_log_model.dart';

/// Single source of truth for prayer name ↔ enum mapping and "is logged" logic.
/// Use everywhere instead of duplicated switches and string literals.
class PrayerNames {
  PrayerNames._();

  static const Map<PrayerName, String> _arNames = {
    PrayerName.fajr: 'الفجر',
    PrayerName.sunrise: 'الشروق',
    PrayerName.dhuhr: 'الظهر',
    PrayerName.asr: 'العصر',
    PrayerName.maghrib: 'المغرب',
    PrayerName.isha: 'العشاء',
  };

  /// Display name for a prayer (Localized).
  static String displayName(PrayerName prayer) {
    return prayer.name.tr;
  }

  /// Parse display name (Arabic or enum name) to [PrayerName].
  static PrayerName fromDisplayName(String name) {
    final trimmed = name.trim().toLowerCase();
    for (final e in _arNames.entries) {
      if (e.value == name.trim() || e.value.toLowerCase() == trimmed) {
        return e.key;
      }
    }
    for (final p in PrayerName.values) {
      if (p.name == trimmed) return p;
    }
    return PrayerName.fajr;
  }

  /// Convert an English key string (e.g. 'fajr', 'dhuhr') to [PrayerName] enum.
  /// Single source of truth – replaces duplicate `_prayerKeyToName` methods.
  static PrayerName fromKey(String key) {
    switch (key.toLowerCase()) {
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
