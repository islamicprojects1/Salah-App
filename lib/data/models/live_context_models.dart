import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/services/prayer_time_service.dart';
import 'package:salah/data/models/prayer_log_model.dart';
import 'package:salah/data/models/prayer_time_model.dart';

/// Context about the currently active prayer and the next one.
class PrayerContextModel {
  final PrayerTimeModel? currentPrayer;
  final PrayerTimeModel? nextPrayer;
  final LivePrayerStatus status;
  final Duration? timeUntilNext;

  const PrayerContextModel({
    required this.currentPrayer,
    required this.nextPrayer,
    required this.status,
    required this.timeUntilNext,
  });

  factory PrayerContextModel.empty() => const PrayerContextModel(
        currentPrayer: null,
        nextPrayer: null,
        status: LivePrayerStatus.notStarted,
        timeUntilNext: null,
      );

  /// Convenience for UI countdown text.
  String get formattedCountdown {
    if (timeUntilNext == null) return '--:--:--';
    final diff = timeUntilNext!;
    if (diff.isNegative) return '--:--:--';
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);
    final seconds = diff.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}

/// Summary of today's prayers for the user.
class DaySummary {
  final DateTime date;
  final Map<PrayerName, PrayerLogModel?> prayers;

  const DaySummary({
    required this.date,
    required this.prayers,
  });

  factory DaySummary.empty(DateTime date) {
    return DaySummary(
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

  int get completedCount =>
      prayers.values.where((p) => p != null).length;

  int get totalPrayers => 5;

  double get completionRatio =>
      totalPrayers == 0 ? 0 : completedCount / totalPrayers;

  int get onTimeCount => prayers.values
      .where((p) =>
          p != null &&
          (p.quality == PrayerQuality.early ||
              p.quality == PrayerQuality.onTime))
      .length;
}

