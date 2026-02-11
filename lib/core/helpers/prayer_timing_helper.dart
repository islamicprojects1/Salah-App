import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/services/prayer_time_service.dart';
import 'package:salah/core/theme/app_colors.dart';

/// Helper class for prayer timing quality related UI functions
class PrayerTimingHelper {
  /// Get color for a prayer timing quality
  static Color getQualityColor(PrayerTimingQuality quality) {
    switch (quality) {
      case PrayerTimingQuality.veryEarly:
        return AppColors.primary; // Dark Green
      case PrayerTimingQuality.early:
        return AppColors.success; // Light Green
      case PrayerTimingQuality.onTime:
        return AppColors.warning; // Yellow/Amber
      case PrayerTimingQuality.late:
        return AppColors.orange; // Orange
      case PrayerTimingQuality.veryLate:
        return AppColors.error.withValues(alpha: 0.6); // Light Red
      case PrayerTimingQuality.missed:
        return AppColors.googleRed; // Dark Red
      case PrayerTimingQuality.notYet:
        return AppColors.grey400; // Gray
    }
  }

  /// Get translated label for a prayer timing quality
  static String getQualityLabel(PrayerTimingQuality quality) {
    switch (quality) {
      case PrayerTimingQuality.veryEarly:
        return 'prayer_timing_very_early'.tr;
      case PrayerTimingQuality.early:
        return 'prayer_timing_early'.tr;
      case PrayerTimingQuality.onTime:
        return 'prayer_timing_on_time'.tr;
      case PrayerTimingQuality.late:
        return 'prayer_timing_late'.tr;
      case PrayerTimingQuality.veryLate:
        return 'prayer_timing_very_late'.tr;
      case PrayerTimingQuality.missed:
        return 'prayer_timing_missed'.tr;
      case PrayerTimingQuality.notYet:
        return 'prayer_timing_not_yet'.tr;
    }
  }

  /// Get icon for a prayer timing quality
  static IconData getQualityIcon(PrayerTimingQuality quality) {
    switch (quality) {
      case PrayerTimingQuality.veryEarly:
      case PrayerTimingQuality.early:
        return Icons.check_circle;
      case PrayerTimingQuality.onTime:
        return Icons.check_circle_outline;
      case PrayerTimingQuality.late:
      case PrayerTimingQuality.veryLate:
        return Icons.schedule;
      case PrayerTimingQuality.missed:
        return Icons.cancel;
      case PrayerTimingQuality.notYet:
        return Icons.circle_outlined;
    }
  }

  /// Get emoji for a prayer timing quality
  static String getQualityEmoji(PrayerTimingQuality quality) {
    switch (quality) {
      case PrayerTimingQuality.veryEarly:
        return '🟩'; // Dark Green square
      case PrayerTimingQuality.early:
        return '🟢'; // Green circle
      case PrayerTimingQuality.onTime:
        return '🟡'; // Yellow circle
      case PrayerTimingQuality.late:
        return '🟠'; // Orange circle
      case PrayerTimingQuality.veryLate:
        return '🔴'; // Red circle
      case PrayerTimingQuality.missed:
        return '⚫'; // Black circle
      case PrayerTimingQuality.notYet:
        return '⚪'; // White circle
    }
  }

  /// Get legacy PrayerQuality color (for backward compatibility)
  static Color getLegacyQualityColor(PrayerQuality quality) {
    switch (quality) {
      case PrayerQuality.early:
        return AppColors.success; // Green
      case PrayerQuality.onTime:
        return AppColors.warning; // Yellow
      case PrayerQuality.late:
        return AppColors.orange; // Orange
      case PrayerQuality.missed:
        return AppColors.googleRed; // Red
    }
  }

  /// Calculate and get quality with color for a prayer log
  static PrayerTimingQuality? calculateQualityFromLog({
    required DateTime prayedAt,
    required DateTime adhanTime,
    required DateTime nextPrayerTime,
  }) {
    final range = PrayerTimeRange(
      adhanTime: adhanTime,
      nextPrayerTime: nextPrayerTime,
      prayerName: PrayerName.fajr, // Placeholder, not used in calculation
    );

    return range.calculateQuality(prayedAt);
  }

  /// Get a gradient color based on quality (for fancy UI)
  static List<Color> getQualityGradient(PrayerTimingQuality quality) {
    final baseColor = getQualityColor(quality);
    return [
      baseColor.withValues(alpha: 0.7),
      baseColor,
      baseColor.withValues(alpha: 0.9),
    ];
  }

  /// Check if quality is good (early or on time)
  static bool isGoodQuality(PrayerTimingQuality quality) {
    return quality == PrayerTimingQuality.veryEarly ||
        quality == PrayerTimingQuality.early ||
        quality == PrayerTimingQuality.onTime;
  }

  /// Check if quality needs attention (late or very late)
  static bool needsAttention(PrayerTimingQuality quality) {
    return quality == PrayerTimingQuality.late ||
        quality == PrayerTimingQuality.veryLate;
  }

  /// Get unique icon for each prayer type
  static IconData getPrayerIcon(PrayerName prayer) {
    switch (prayer) {
      case PrayerName.fajr:
        return Icons.wb_twilight_rounded;
      case PrayerName.sunrise:
        return Icons.wb_sunny_outlined;
      case PrayerName.dhuhr:
        return Icons.wb_sunny_rounded;
      case PrayerName.asr:
        return Icons.wb_cloudy_rounded;
      case PrayerName.maghrib:
        return Icons.nightlight_round;
      case PrayerName.isha:
        return Icons.dark_mode_rounded;
    }
  }
}
