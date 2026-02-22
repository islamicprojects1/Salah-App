import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/core/helpers/prayer_timing_helper.dart';
import 'package:salah/features/prayer/controller/dashboard_controller.dart';
import 'package:salah/features/prayer/data/models/prayer_log_model.dart';

/// Daily Review Card — shown on dashboard after Isha to summarize the day's prayers.
/// Displays quality dots for each prayer with a motivational message.
///
/// FIX: Previous condition `logs.length >= 5` caused the card to show all day
/// if the user logged all prayers early. Now it ONLY shows after Isha time.
class DailyReviewCard extends StatelessWidget {
  const DailyReviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();

    return Obx(() {
      final logs = controller.todayLogs;
      final prayers = controller.todayPrayers
          .where((p) => p.prayerType != PrayerName.sunrise)
          .toList();

      if (prayers.isEmpty) return const SizedBox.shrink();

      // Only show after Isha time has passed — no early trigger based on log count
      final ishaTime = prayers.last.dateTime;
      final now = DateTime.now();
      if (!now.isAfter(ishaTime)) return const SizedBox.shrink();

      final completed = logs
          .where((l) => l.prayer != PrayerName.sunrise)
          .length
          .clamp(0, 5);
      const total = 5;

      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;

      final String message;
      final Color messageColor;
      final IconData messageIcon;

      if (completed >= total) {
        message = 'all_prayers_complete'.tr;
        messageColor = AppColors.success;
        messageIcon = Icons.star_rounded;
      } else if (completed >= 3) {
        message = 'most_prayers_done'.tr;
        messageColor = AppColors.amber;
        messageIcon = Icons.thumb_up_rounded;
      } else if (completed >= 1) {
        message = 'some_prayers_missed'.tr;
        messageColor = AppColors.orange;
        messageIcon = Icons.favorite_rounded;
      } else {
        message = 'no_prayers_today'.tr;
        messageColor = theme.colorScheme.onSurface.withValues(alpha: 0.5);
        messageIcon = Icons.wb_sunny_outlined;
      }

      return Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.paddingMD),
        padding: const EdgeInsets.all(AppDimensions.paddingMD),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.surface,
              completed >= total
                  ? AppColors.success.withValues(alpha: 0.08)
                  : AppColors.amber.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
          border: Border.all(
            color: completed >= total
                ? AppColors.success.withValues(alpha: 0.2)
                : colorScheme.primary.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.nights_stay_rounded,
                  color: colorScheme.primary,
                  size: AppDimensions.iconLG,
                ),
                const SizedBox(width: AppDimensions.paddingSM),
                Text(
                  'daily_review_title'.tr,
                  style: AppFonts.titleMedium.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '$completed/$total',
                  style: AppFonts.titleLarge.copyWith(
                    color: completed >= total
                        ? AppColors.success
                        : colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingLG),

            // Prayer quality dots
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: prayers.map((prayer) {
                final prayerType = prayer.prayerType;
                final log = logs.firstWhereOrNull((l) => l.prayer == prayerType);
                return _buildReviewDot(
                  context,
                  name: prayer.name,
                  isLogged: log != null,
                  quality: log?.quality,
                );
              }).toList(),
            ),
            const SizedBox(height: AppDimensions.paddingLG),

            // Motivational message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingMD,
                vertical: AppDimensions.paddingSM + 2,
              ),
              decoration: BoxDecoration(
                color: messageColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    messageIcon,
                    color: messageColor,
                    size: AppDimensions.iconMD,
                  ),
                  const SizedBox(width: AppDimensions.paddingSM),
                  Flexible(
                    child: Text(
                      message,
                      style: AppFonts.bodyMedium.copyWith(
                        color: messageColor,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildReviewDot(
    BuildContext context, {
    required String name,
    required bool isLogged,
    PrayerQuality? quality,
  }) {
    final Color dotColor;
    final IconData dotIcon;

    if (isLogged && quality != null) {
      dotColor = PrayerTimingHelper.getLegacyQualityColor(quality);
      dotIcon = quality == PrayerQuality.early
          ? Icons.star_rounded
          : quality == PrayerQuality.onTime
          ? Icons.check_circle
          : Icons.check_circle_outline;
    } else if (isLogged) {
      dotColor = AppColors.success;
      dotIcon = Icons.check_circle;
    } else {
      dotColor = Theme.of(context).colorScheme.error.withValues(alpha: 0.5);
      dotIcon = Icons.cancel_rounded;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: AppDimensions.buttonHeightLG,
          height: AppDimensions.buttonHeightLG,
          decoration: BoxDecoration(
            color: dotColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: dotColor, width: 2),
          ),
          child: Icon(dotIcon, color: dotColor, size: AppDimensions.iconLG),
        ),
        const SizedBox(height: AppDimensions.paddingXS),
        Text(
          name,
          style: AppFonts.labelSmall.copyWith(
            color: dotColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
