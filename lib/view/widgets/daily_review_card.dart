import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/core/helpers/prayer_timing_helper.dart';
import 'package:salah/controller/dashboard_controller.dart';
import 'package:salah/data/models/prayer_log_model.dart';

/// Daily Review Card — shown on dashboard after Isha to summarize the day's prayers.
/// Displays quality dots for each prayer with a motivational message.
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

      // Only show after Isha time has passed (or if at least 1 prayer is logged)
      final now = DateTime.now();
      final ishaTime = prayers.isNotEmpty ? prayers.last.dateTime : null;
      final showReview =
          (ishaTime != null && now.isAfter(ishaTime)) || logs.length >= 5;
      if (!showReview) return const SizedBox.shrink();

      final completed = logs
          .where((l) => l.prayer != PrayerName.sunrise)
          .length;
      final total = 5;

      // Motivational message based on completion
      String message;
      Color messageColor;
      IconData messageIcon;
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
        messageColor = AppColors.textSecondary;
        messageIcon = Icons.wb_sunny_outlined;
      }

      return Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.paddingMD),
        padding: const EdgeInsets.all(AppDimensions.paddingMD),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.surface,
              completed >= 5
                  ? AppColors.success.withValues(alpha: 0.08)
                  : AppColors.amber.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
          border: Border.all(
            color: completed >= 5
                ? AppColors.success.withValues(alpha: 0.2)
                : AppColors.primary.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.nights_stay_rounded,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  'daily_review_title'.tr,
                  style: AppFonts.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '$completed/$total',
                  style: AppFonts.titleLarge.copyWith(
                    color: completed >= total
                        ? AppColors.success
                        : AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Prayer quality dots
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: prayers.map((prayer) {
                PrayerLogModel? log;
                try {
                  log = logs.firstWhere(
                    (l) => l.prayer == (prayer.prayerType ?? PrayerName.fajr),
                  );
                } catch (_) {
                  log = null;
                }
                final isLogged = log != null;
                final quality = log?.quality;

                return _buildReviewDot(
                  name: prayer.name,
                  isLogged: isLogged,
                  quality: quality,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Motivational message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: messageColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(messageIcon, color: messageColor, size: 18),
                  const SizedBox(width: 8),
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

  Widget _buildReviewDot({
    required String name,
    required bool isLogged,
    PrayerQuality? quality,
  }) {
    Color dotColor;
    IconData dotIcon;

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
      dotColor = AppColors.error.withValues(alpha: 0.5);
      dotIcon = Icons.cancel_rounded;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: dotColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: dotColor, width: 2),
          ),
          child: Icon(dotIcon, color: dotColor, size: 22),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: AppFonts.labelSmall.copyWith(
            color: dotColor,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
