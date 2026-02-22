import 'package:salah/core/constants/enums.dart';
import 'package:salah/features/prayer/data/models/prayer_log_model.dart';
import 'package:salah/features/prayer/data/models/prayer_time_model.dart';

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
