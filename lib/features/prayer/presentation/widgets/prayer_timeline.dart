import 'package:flutter/material.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/features/prayer/data/models/prayer_time_model.dart';

class PrayerTimeline extends StatelessWidget {
  final List<PrayerTimeModel> prayers;
  final PrayerTimeModel? currentPrayer;
  final PrayerTimeModel? nextPrayer;
  final List<PrayerName> completedPrayers;

  const PrayerTimeline({
    super.key,
    required this.prayers,
    this.currentPrayer,
    this.nextPrayer,
    this.completedPrayers = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMD),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: prayers
            .map((prayer) => _buildPrayerNode(context, prayer))
            .toList(),
      ),
    );
  }

  Widget _buildPrayerNode(BuildContext context, PrayerTimeModel prayer) {
    final isCompleted =
        prayer.prayerType != null &&
        completedPrayers.contains(prayer.prayerType);
    final isCurrent = prayer == currentPrayer;
    final isNext = prayer == nextPrayer;

    Color color;
    if (isCompleted) {
      color = AppColors.success;
    } else if (isCurrent) {
      color = AppColors.secondary;
    } else if (isNext) {
      color = AppColors.primary;
    } else {
      color = AppColors.textSecondary.withValues(alpha: 0.3);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 16, color: AppColors.success)
                : null,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingXS),
        Text(
          prayer.name,
          style: AppFonts.labelSmall.copyWith(
            color: isCurrent || isNext
                ? AppColors.textPrimary
                : AppColors.textSecondary,
            fontWeight: isCurrent || isNext
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
        if (isCurrent)
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }
}
