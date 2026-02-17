import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/helpers/prayer_names.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/helpers/date_time_helper.dart';

/// Prayer card widget showing prayer time and status
class PrayerCard extends StatelessWidget {
  final PrayerName prayer;
  final DateTime prayerTime;
  final bool isPrayed;
  final PrayerQuality? quality;
  final bool isCurrentPrayer;
  final VoidCallback? onTap;
  final VoidCallback? onMarkPrayed;

  const PrayerCard({
    super.key,
    required this.prayer,
    required this.prayerTime,
    this.isPrayed = false,
    this.quality,
    this.isCurrentPrayer = false,
    this.onTap,
    this.onMarkPrayed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isCurrentPrayer ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        side: isCurrentPrayer
            ? BorderSide(color: _getPrayerColor(), width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMD),
          child: Row(
            children: [
              // Prayer icon/status indicator
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isPrayed
                      ? _getQualityColor().withValues(alpha: 0.15)
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPrayed ? Icons.check : _getPrayerIcon(),
                  color: isPrayed
                      ? _getQualityColor()
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                  size: 24,
                ),
              ),

              const SizedBox(width: AppDimensions.paddingMD),

              // Prayer info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      PrayerNames.displayName(prayer),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: isCurrentPrayer
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateTimeHelper.formatTime12(prayerTime),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),

              // Action/Status
              if (!isPrayed && onMarkPrayed != null)
                IconButton(
                  onPressed: onMarkPrayed,
                  icon: const Icon(Icons.check_circle_outline),
                  color: AppColors.primary,
                  tooltip: 'log_prayer_tooltip'.tr,
                )
              else if (isPrayed && quality != null)
                _buildQualityBadge(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQualityBadge(BuildContext context) {
    String label;
    switch (quality!) {
      case PrayerQuality.early:
        label = 'prayer_early'.tr;
        break;
      case PrayerQuality.onTime:
        label = 'prayer_on_time'.tr;
        break;
      case PrayerQuality.late:
        label = 'prayer_late'.tr;
        break;
      case PrayerQuality.missed:
        label = 'prayer_missed'.tr;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSM,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: _getQualityColor().withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _getQualityColor(),
        ),
      ),
    );
  }

  Color _getPrayerColor() {
    switch (prayer) {
      case PrayerName.fajr:
        return AppColors.fajr;
      case PrayerName.sunrise:
        return AppColors.sunrise;
      case PrayerName.dhuhr:
        return AppColors.dhuhr;
      case PrayerName.asr:
        return AppColors.asr;
      case PrayerName.maghrib:
        return AppColors.maghrib;
      case PrayerName.isha:
        return AppColors.isha;
    }
  }

  Color _getQualityColor() {
    if (quality == null) return AppColors.success;
    switch (quality!) {
      case PrayerQuality.early:
        return AppColors.success; // Green
      case PrayerQuality.onTime:
        return AppColors.secondary; // Gold
      case PrayerQuality.late:
        return AppColors.warning; // Orange
      case PrayerQuality.missed:
        return AppColors.error; // Red
    }
  }

  IconData _getPrayerIcon() {
    switch (prayer) {
      case PrayerName.fajr:
        return Icons.wb_twilight;
      case PrayerName.sunrise:
        return Icons.wb_sunny_outlined;
      case PrayerName.dhuhr:
        return Icons.wb_sunny;
      case PrayerName.asr:
        return Icons.sunny_snowing;
      case PrayerName.maghrib:
        return Icons.nights_stay_outlined;
      case PrayerName.isha:
        return Icons.nights_stay;
    }
  }

}

