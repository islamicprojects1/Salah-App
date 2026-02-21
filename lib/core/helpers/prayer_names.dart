import 'package:get/get.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/features/prayer/data/models/prayer_log_model.dart';

/// Single source of truth for [PrayerName] ↔ string mapping and log-lookup logic.
///
/// Prefer [PrayerName.displayName] (added in enums.dart) for simple name display.
/// Use this class for parsing, Arabic name lookups, and log checks.
class PrayerNames {
  const PrayerNames._();

  // ============================================================
  // ARABIC NAMES
  // ============================================================

  static const Map<PrayerName, String> _arNames = {
    PrayerName.fajr: 'الفجر',
    PrayerName.sunrise: 'الشروق',
    PrayerName.dhuhr: 'الظهر',
    PrayerName.asr: 'العصر',
    PrayerName.maghrib: 'المغرب',
    PrayerName.isha: 'العشاء',
  };

  // Reverse lookup: Arabic name → PrayerName
  static final Map<String, PrayerName> _arNamesReverse = {
    for (final e in _arNames.entries) e.value: e.key,
  };

  // ============================================================
  // DISPLAY NAME
  // ============================================================

  /// Localised display name via GetX translation key.
  static String displayName(PrayerName prayer) => prayer.name.tr;

  /// Arabic name regardless of locale.
  static String arabicName(PrayerName prayer) => _arNames[prayer]!;

  // ============================================================
  // PARSING
  // ============================================================

  /// Parses an English key string (`'fajr'`, `'dhuhr'`, …) to [PrayerName].
  ///
  /// Case-insensitive. Falls back to [PrayerName.fajr] for unknown keys.
  static PrayerName fromKey(String key) => switch (key.toLowerCase()) {
    'fajr' => PrayerName.fajr,
    'sunrise' => PrayerName.sunrise,
    'dhuhr' => PrayerName.dhuhr,
    'asr' => PrayerName.asr,
    'maghrib' => PrayerName.maghrib,
    'isha' => PrayerName.isha,
    _ => PrayerName.fajr,
  };

  /// Parses an Arabic name or English enum name to [PrayerName].
  ///
  /// Tries Arabic match first, then falls back to enum name match.
  /// Falls back to [PrayerName.fajr] for unknown values.
  static PrayerName fromDisplayName(String name) {
    final trimmed = name.trim();
    // Try Arabic lookup first
    final fromAr = _arNamesReverse[trimmed];
    if (fromAr != null) return fromAr;
    // Try English enum name
    return fromKey(trimmed);
  }

  // ============================================================
  // LOG LOOKUP
  // ============================================================

  /// Returns true if [prayer] has already been logged in [logs].
  ///
  /// Matches by [PrayerName] enum value when [prayerType] is provided,
  /// otherwise falls back to display-name string comparison.
  static bool isLogged(List<PrayerLogModel> logs, PrayerName prayer) =>
      logs.any((l) => l.prayer == prayer);

  /// Overload for callers that have a display name string but no enum value.
  static bool isLoggedByName(
    List<PrayerLogModel> logs,
    String prayerDisplayName, {
    PrayerName? prayerType,
  }) {
    if (prayerType != null) return isLogged(logs, prayerType);
    final nameLower = prayerDisplayName.trim().toLowerCase();
    return logs.any(
      (l) =>
          displayName(l.prayer).trim().toLowerCase() == nameLower ||
          l.prayer.name.toLowerCase() == nameLower,
    );
  }

  // ============================================================
  // DEPRECATED ALIASES
  // ============================================================

  @Deprecated('Use PrayerNames.fromKey()')
  static PrayerName fromKey2(String key) => fromKey(key);

  @Deprecated('Use PrayerNames.isLoggedByName()')
  static bool isPrayerLogged(
    List<PrayerLogModel> logs,
    String prayerDisplayName,
    PrayerName? prayerType,
  ) => isLoggedByName(logs, prayerDisplayName, prayerType: prayerType);
}
