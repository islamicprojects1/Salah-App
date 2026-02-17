import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/core/helpers/date_time_helper.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/features/family/controller/family_controller.dart';

/// Family pulse section: recent activity feed (who prayed, encouraged, etc.).
class FamilyPulseSection extends StatelessWidget {
  final FamilyController controller;
  static const int _maxDisplayCount = 5;

  const FamilyPulseSection({
    super.key,
    required this.controller,
  });

  String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'now_label'.tr;
    if (diff.inMinutes < 60) return '${diff.inMinutes} ${'minutes_short'.tr}';
    if (diff.inHours < 24) return '${diff.inHours} ${'hours_short'.tr}';
    return DateTimeHelper.formatTime12(time);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Obx(() {
      final events = controller.pulseEvents;
      if (events.isEmpty) return const SizedBox.shrink();

      final displayEvents = events.take(_maxDisplayCount).toList();

      return Card(
        elevation: AppDimensions.cardElevationLow,
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
                  Icon(Icons.favorite, color: colorScheme.primary, size: 20),
                  const SizedBox(width: AppDimensions.paddingSM),
                  Text(
                    'family_pulse'.tr,
                    style: AppFonts.titleMedium.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingMD),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayEvents.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppDimensions.paddingXS),
                  itemBuilder: (context, index) {
                    final e = displayEvents[index];
                    final isCelebration =
                        e.type == PulseEventType.familyCelebration;
                    final isEncouragement = e.type == PulseEventType.encouragement;
                    final isPrayer = e.type == PulseEventType.prayerLogged;
                    final isDailyComplete =
                        e.type == PulseEventType.dailyComplete;
                    final accentColor = isCelebration
                        ? AppColors.amber
                        : isEncouragement
                            ? AppColors.info
                            : isDailyComplete
                                ? AppColors.primary
                                : AppColors.success;
                    final bgColor = accentColor.withValues(alpha: 0.08);
                    IconData icon = Icons.mosque;
                    if (isCelebration) {
                      icon = Icons.celebration_rounded;
                    } else if (isEncouragement) {
                      icon = Icons.thumb_up_rounded;
                    } else if (isDailyComplete) {
                      icon = Icons.emoji_events_rounded;
                    } else if (isPrayer) {
                      icon = Icons.nightlight_round;
                    }

                    return AnimatedContainer(
                      duration: Duration(milliseconds: 300 + index * 50),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 10,
                      ),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border(
                          left: BorderSide(
                            color: accentColor,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            icon,
                            size: isCelebration ? 22 : 20,
                            color: accentColor,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              e.displayText,
                              style: AppFonts.bodyMedium.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: isCelebration
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            _relativeTime(e.timestamp),
                            style: AppFonts.labelSmall.copyWith(
                              color: accentColor.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
