import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/services/prayer_time_service.dart';

/// Helper class for prayer timing quality related UI functions
class PrayerTimingHelper {
  /// Get color for a prayer timing quality
  static Color getQualityColor(PrayerTimingQuality quality) {
    switch (quality) {
      case PrayerTimingQuality.veryEarly:
        return const Color(0xFF1B5E20); // Dark Green
      case PrayerTimingQuality.early:
        return const Color(0xFF4CAF50); // Light Green
      case PrayerTimingQuality.onTime:
        return const Color(0xFFFFC107); // Yellow/Amber
      case PrayerTimingQuality.late:
        return const Color(0xFFFF9800); // Orange
      case PrayerTimingQuality.veryLate:
        return const Color(0xFFE57373); // Light Red
      case PrayerTimingQuality.missed:
        return const Color(0xFFD32F2F); // Dark Red
      case PrayerTimingQuality.notYet:
        return const Color(0xFFBDBDBD); // Gray
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
        return const Color(0xFF4CAF50); // Green
      case PrayerQuality.onTime:
        return const Color(0xFFFFC107); // Yellow
      case PrayerQuality.late:
        return const Color(0xFFFF9800); // Orange
      case PrayerQuality.missed:
        return const Color(0xFFD32F2F); // Red
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
}
