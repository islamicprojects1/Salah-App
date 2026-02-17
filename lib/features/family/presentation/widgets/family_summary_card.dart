import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/core/helpers/prayer_timing_helper.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/features/family/controller/family_controller.dart';
import 'package:salah/features/family/data/models/family_model.dart';

/// Family daily summary card: total prayers logged today.
class FamilySummaryCard extends StatelessWidget {
  final FamilyModel family;
  final FamilyController controller;

  const FamilySummaryCard({
    super.key,
    required this.family,
    required this.controller,
  });

  Color _getProgressColor(int count) {
    if (count >= 5) {
      return PrayerTimingHelper.getQualityColor(PrayerTimingQuality.veryEarly);
    }
    if (count >= 3) return AppColors.amber;
    if (count >= 1) return AppColors.orange;
    return AppColors.error.withValues(alpha: 0.6);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Obx(() {
      final totalMembers = family.members.length;
      final totalPossible = totalMembers * 5;
      int totalLogged = 0;
      for (final m in family.members) {
        totalLogged += (controller.memberProgress[m.userId] ?? 0);
      }
      final progress = totalPossible > 0 ? totalLogged / totalPossible : 0.0;
      final avgPerMember = totalMembers > 0 ? totalLogged ~/ totalMembers : 0;
      final progressColor = _getProgressColor(avgPerMember);

      return Card(
        elevation: AppDimensions.cardElevationLow,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusLG,
        ),
        shadowColor: colorScheme.shadow.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.bar_chart_rounded,
                    color: colorScheme.primary,
                    size: AppDimensions.iconMD,
                  ),
                  const SizedBox(width: AppDimensions.paddingSM),
                  Text(
                    'family_daily_summary'.tr,
                    style: AppFonts.titleMedium.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$totalLogged/$totalPossible',
                    style: AppFonts.titleLarge.copyWith(
                      color: progressColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingSM),
              ClipRRect(
                borderRadius: AppDimensions.borderRadiusSM,
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
