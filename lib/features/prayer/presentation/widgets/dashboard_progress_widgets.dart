import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/helpers/date_time_helper.dart';
import 'package:salah/core/helpers/prayer_timing_helper.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/features/prayer/controller/dashboard_controller.dart';
import 'package:salah/features/prayer/data/models/prayer_log_model.dart';
import 'package:salah/features/prayer/data/models/prayer_time_model.dart';

Widget buildTodayProgress(
  BuildContext context,
  DashboardController controller,
) {
  final colorScheme = Theme.of(context).colorScheme;
  return Obx(() {
    final completed = controller.todayLogs
      .where((log) => log.prayer != PrayerName.sunrise)
      .length;
    const total = 5;
    final progress = completed / total;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimensions.borderRadiusLG,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppDimensions.paddingLG),
      child: Row(
        children: [
          Text(
            '$completed/$total',
            style: AppFonts.titleLarge.copyWith(
              color: completed >= total ? AppColors.success : AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ClipRRect(
              borderRadius: AppDimensions.borderRadiusSM,
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(
                  completed >= total ? AppColors.success : AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  });
}

Widget buildQuickPrayerIcons(
  BuildContext context,
  DashboardController controller,
) {
  final colorScheme = Theme.of(context).colorScheme;
  return Obx(() {
    final prayers = controller.todayPrayers
        .where((p) => p.prayerType != PrayerName.sunrise)
        .toList();
    final now = DateTime.now();

    int unloggedPastCount = 0;
    for (final p in prayers) {
      if (p.dateTime.isAfter(now)) continue;
      final alreadyLogged = controller.todayLogs.any(
        (l) => l.prayer == (p.prayerType ?? PrayerName.fajr),
      );
      if (!alreadyLogged) unloggedPastCount++;
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingMD,
                vertical: AppDimensions.paddingMD,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: prayers.map((prayer) {
                  final prayerType = prayer.prayerType ?? PrayerName.fajr;
                  PrayerLogModel? log;
                  try {
                    log = controller.todayLogs
                        .firstWhere((l) => l.prayer == prayerType);
                  } catch (_) {
                    log = null;
                  }
                  final isLogged = log != null;
                  final isNext = prayer == controller.nextPrayer.value;
                  final isCurrent = prayer == controller.currentPrayer.value;
                  final isPast = !prayer.dateTime.isAfter(now) && !isCurrent;
                  final quality = log?.quality;

                  return buildPrayerIcon(
                    controller: controller,
                    prayerType: prayerType,
                    prayer: prayer,
                    name: prayer.name,
                    time: DateTimeHelper.formatTime12(prayer.dateTime),
                    isLogged: isLogged,
                    quality: quality,
                    isNext: isNext,
                    isCurrent: isCurrent,
                    isPastUnlogged: isPast && !isLogged,
                    onTap: isLogged
                        ? null
                        : (isCurrent
                            ? () => controller.logPrayer(prayer)
                            : (isPast
                                ? () => controller.logPastPrayer(prayer)
                                : null)),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        if (unloggedPastCount >= 2) ...[
          const SizedBox(height: AppDimensions.paddingMD),
          InkWell(
            onTap: () => controller.logAllUnloggedPrayers(),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                ),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.done_all_rounded,
                    color: colorScheme.onPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'log_all_prayers'.tr,
                    style: AppFonts.bodyLarge.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  });
}

Widget buildPrayerIcon({
  required DashboardController controller,
  required PrayerName prayerType,
  required dynamic prayer,
  required String name,
  required String time,
  required bool isLogged,
  PrayerQuality? quality,
  required bool isNext,
  required bool isCurrent,
  bool isPastUnlogged = false,
  VoidCallback? onTap,
}) {
  Color bgColor;
  Color iconColor;
  IconData iconData = PrayerTimingHelper.getPrayerIcon(prayerType);

  if (isLogged && quality != null) {
    iconColor = PrayerTimingHelper.getLegacyQualityColor(quality);
    bgColor = iconColor.withValues(alpha: 0.2);
  } else if (isLogged) {
    bgColor = AppColors.success.withValues(alpha: 0.2);
    iconColor = AppColors.success;
  } else if (isPastUnlogged) {
    bgColor = AppColors.orange.withValues(alpha: 0.15);
    iconColor = AppColors.orange;
  } else if (isCurrent) {
    bgColor = AppColors.primary.withValues(alpha: 0.25);
    iconColor = AppColors.primary;
  } else if (isNext) {
    bgColor = AppColors.secondary.withValues(alpha: 0.2);
    iconColor = AppColors.secondary;
  } else {
    bgColor = AppColors.textSecondary.withValues(alpha: 0.08);
    iconColor = AppColors.textSecondary.withValues(alpha: 0.5);
  }

  return GestureDetector(
    onTap: onTap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            boxShadow: (isCurrent || isNext)
                ? [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
            border: isCurrent
                ? Border.all(color: iconColor, width: 2.5)
                : isNext
                    ? Border.all(
                        color: iconColor.withValues(alpha: 0.5),
                        width: 1.5,
                        style: BorderStyle.solid,
                      )
                    : null,
          ),
          child: Center(
            child: isLogged
                ? Icon(Icons.check_circle_rounded, color: iconColor, size: 28)
                : Icon(iconData, color: iconColor, size: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: AppFonts.labelSmall.copyWith(
            color: isLogged && quality != null
                ? PrayerTimingHelper.getLegacyQualityColor(quality)
                : isLogged
                    ? AppColors.success
                    : isPastUnlogged
                        ? AppColors.orange
                        : AppColors.textPrimary,
            fontWeight: (isCurrent || isPastUnlogged)
                ? FontWeight.bold
                : FontWeight.normal,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          time,
          style: AppFonts.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 9,
            letterSpacing: 0.2,
          ),
        ),
      ],
    ),
  );
}
