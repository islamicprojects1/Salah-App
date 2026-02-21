import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/features/prayer/data/services/prayer_time_service.dart';

/// UI helpers for [PrayerTimingQuality] and [PrayerName].
///
/// Provides colors, icons, labels, and gradients used across prayer-related widgets.
/// Keep all quality → visual mapping here as the single source of truth.
class PrayerTimingHelper {
  const PrayerTimingHelper._();

  // ============================================================
  // QUALITY → COLOR
  // ============================================================

  static Color qualityColor(PrayerTimingQuality quality) => switch (quality) {
    PrayerTimingQuality.veryEarly => AppColors.primary,
    PrayerTimingQuality.early => AppColors.success,
    PrayerTimingQuality.onTime => AppColors.warning,
    PrayerTimingQuality.late => AppColors.orange,
    PrayerTimingQuality.veryLate => AppColors.error.withValues(alpha: 0.6),
    PrayerTimingQuality.missed => AppColors.googleRed,
    PrayerTimingQuality.notYet => AppColors.grey400,
  };

  /// Gradient for fancy cards / progress indicators.
  static List<Color> qualityGradient(PrayerTimingQuality quality) {
    final c = qualityColor(quality);
    return [c.withValues(alpha: 0.7), c, c.withValues(alpha: 0.9)];
  }

  // ============================================================
  // QUALITY → ICON
  // ============================================================

  static IconData qualityIcon(PrayerTimingQuality quality) => switch (quality) {
    PrayerTimingQuality.veryEarly ||
    PrayerTimingQuality.early => Icons.check_circle,
    PrayerTimingQuality.onTime => Icons.check_circle_outline,
    PrayerTimingQuality.late || PrayerTimingQuality.veryLate => Icons.schedule,
    PrayerTimingQuality.missed => Icons.cancel,
    PrayerTimingQuality.notYet => Icons.circle_outlined,
  };

  // ============================================================
  // QUALITY → EMOJI
  // ============================================================

  static String qualityEmoji(PrayerTimingQuality quality) => switch (quality) {
    PrayerTimingQuality.veryEarly => '🟩',
    PrayerTimingQuality.early => '🟢',
    PrayerTimingQuality.onTime => '🟡',
    PrayerTimingQuality.late => '🟠',
    PrayerTimingQuality.veryLate => '🔴',
    PrayerTimingQuality.missed => '⚫',
    PrayerTimingQuality.notYet => '⚪',
  };

  // ============================================================
  // QUALITY → LABEL (localised)
  // ============================================================

  static String qualityLabel(PrayerTimingQuality quality) => switch (quality) {
    PrayerTimingQuality.veryEarly => 'prayer_timing_very_early'.tr,
    PrayerTimingQuality.early => 'prayer_timing_early'.tr,
    PrayerTimingQuality.onTime => 'prayer_timing_on_time'.tr,
    PrayerTimingQuality.late => 'prayer_timing_late'.tr,
    PrayerTimingQuality.veryLate => 'prayer_timing_very_late'.tr,
    PrayerTimingQuality.missed => 'prayer_timing_missed'.tr,
    PrayerTimingQuality.notYet => 'prayer_timing_not_yet'.tr,
  };

  // ============================================================
  // QUALITY PREDICATES
  // ============================================================

  /// True for veryEarly, early, or onTime.
  static bool isGoodQuality(PrayerTimingQuality q) =>
      q == PrayerTimingQuality.veryEarly ||
      q == PrayerTimingQuality.early ||
      q == PrayerTimingQuality.onTime;

  /// True for late or veryLate.
  static bool needsAttention(PrayerTimingQuality q) =>
      q == PrayerTimingQuality.late || q == PrayerTimingQuality.veryLate;

  // ============================================================
  // PRAYER NAME → ICON
  // ============================================================

  static IconData prayerIcon(PrayerName prayer) => switch (prayer) {
    PrayerName.fajr => Icons.wb_twilight_rounded,
    PrayerName.sunrise => Icons.wb_sunny_outlined,
    PrayerName.dhuhr => Icons.wb_sunny_rounded,
    PrayerName.asr => Icons.wb_cloudy_rounded,
    PrayerName.maghrib => Icons.nightlight_round,
    PrayerName.isha => Icons.dark_mode_rounded,
  };

  // ============================================================
  // LEGACY SUPPORT
  // ============================================================

  /// Color for the legacy [PrayerQuality] enum. Kept for backward compatibility.
  static Color legacyQualityColor(PrayerQuality quality) => switch (quality) {
    PrayerQuality.early => AppColors.success,
    PrayerQuality.onTime => AppColors.warning,
    PrayerQuality.late => AppColors.orange,
    PrayerQuality.missed => AppColors.googleRed,
  };

  // ============================================================
  // CALCULATION HELPER
  // ============================================================

  /// Convenience wrapper around [PrayerTimeRange.calculateQuality].
  static PrayerTimingQuality? calculateQuality({
    required DateTime prayedAt,
    required DateTime adhanTime,
    required DateTime nextPrayerTime,
  }) {
    final range = PrayerTimeRange(
      adhanTime: adhanTime,
      nextPrayerTime: nextPrayerTime,
      prayerName: PrayerName.fajr, // name not used in quality calculation
    );
    return range.calculateQuality(prayedAt);
  }

  // ============================================================
  // DEPRECATED ALIASES (remove after refactor sweep)
  // ============================================================

  @Deprecated('Use qualityColor()')
  static Color getQualityColor(PrayerTimingQuality q) => qualityColor(q);

  @Deprecated('Use qualityLabel()')
  static String getQualityLabel(PrayerTimingQuality q) => qualityLabel(q);

  @Deprecated('Use qualityIcon()')
  static IconData getQualityIcon(PrayerTimingQuality q) => qualityIcon(q);

  @Deprecated('Use qualityEmoji()')
  static String getQualityEmoji(PrayerTimingQuality q) => qualityEmoji(q);

  @Deprecated('Use prayerIcon()')
  static IconData getPrayerIcon(PrayerName p) => prayerIcon(p);

  @Deprecated('Use legacyQualityColor()')
  static Color getLegacyQualityColor(PrayerQuality q) => legacyQualityColor(q);

  @Deprecated('Use calculateQuality()')
  static PrayerTimingQuality? calculateQualityFromLog({
    required DateTime prayedAt,
    required DateTime adhanTime,
    required DateTime nextPrayerTime,
  }) => calculateQuality(
    prayedAt: prayedAt,
    adhanTime: adhanTime,
    nextPrayerTime: nextPrayerTime,
  );
}
