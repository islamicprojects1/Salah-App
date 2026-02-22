import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/constants/image_assets.dart';
import 'package:salah/core/helpers/prayer_timing_helper.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/features/prayer/controller/missed_prayers_controller.dart';
import 'package:salah/features/prayer/data/models/prayer_time_model.dart';
import 'package:salah/features/prayer/data/services/qada_detection_service.dart';
import 'package:salah/features/prayer/presentation/widgets/missed_prayer_card.dart';

class MissedPrayersScreen extends GetView<MissedPrayersController> {
  const MissedPrayersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const _LoadingState();
        }

        final hasData =
            controller.unloggedByDay.isNotEmpty ||
            controller.missedPrayers.isNotEmpty;

        if (!hasData) {
          return const _EmptyState();
        }

        return Column(
          children: [
            _MissedPrayersHeader(),
            Expanded(
              child: controller.unloggedByDay.isEmpty
                  ? _buildLegacyList(context)
                  : _buildByDayList(context),
            ),
            _BottomActions(controller: controller),
          ],
        );
      }),
    );
  }

  Widget _buildLegacyList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: controller.missedPrayers.length,
      itemBuilder: (context, index) {
        final prayer = controller.missedPrayers[index];
        final prayerType = prayer.prayerType;
        if (prayerType == null) return const SizedBox.shrink();
        return Obx(() {
          final status =
              controller.prayerStatuses[prayerType] ?? PrayerCardStatus.prayed;
          final timing =
              controller.prayerTimings[prayerType] ??
              PrayerTimingQuality.onTime;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: MissedPrayerCard(
              prayer: prayer,
              status: status,
              timing: timing,
              onStatusChanged: (newStatus) {
                HapticFeedback.mediumImpact();
                controller.setPrayerStatus(prayerType, newStatus);
              },
              onTimingChanged: (newTiming) =>
                  controller.setPrayerTiming(prayerType, newTiming),
              onDismissed: () => controller.missedPrayers.removeAt(index),
            ),
          );
        });
      },
    );
  }

  Widget _buildByDayList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: controller.unloggedByDay.length,
      itemBuilder: (context, groupIndex) {
        final group = controller.unloggedByDay[groupIndex];
        return Obx(() {
          final isLogging = controller.isLoggingDay.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DayGroupHeader(
                label: group.label,
                count: group.count,
                isLogging: isLogging,
                onLogAll: () => controller.logAllForDay(group),
              ),
              ...group.prayers.map((info) {
                final prayerModel = prayerTimeModelFromUnlogged(info);
                return Obx(() {
                  final status =
                      controller.statusByKey[info.key] ??
                      PrayerCardStatus.prayed;
                  final timing =
                      controller.timingByKey[info.key] ??
                      PrayerTimingQuality.onTime;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: MissedPrayerCard(
                      prayer: prayerModel,
                      status: status,
                      timing: timing,
                      onStatusChanged: (newStatus) {
                        HapticFeedback.mediumImpact();
                        controller.setPrayerStatusByKey(info.key, newStatus);
                      },
                      onTimingChanged: (newTiming) =>
                          controller.setPrayerTimingByKey(info.key, newTiming),
                      pastDate: info.date,
                    ),
                  );
                });
              }),
              const SizedBox(height: 8),
            ],
          );
        });
      },
    );
  }

  static PrayerTimeModel prayerTimeModelFromUnlogged(UnloggedPrayerInfo info) {
    return PrayerTimeModel(
      name: info.displayName,
      prayerType: info.prayer,
      dateTime: info.adhanTime,
    );
  }
}

// ─────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Lottie.asset(
        ImageAssets.loadingAnimation,
        width: 150,
        height: 150,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                size: 54,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingLG),
            Text(
              'all_prayers_completed'.tr,
              style: AppFonts.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.paddingSM),
            Text(
              'أحسنت! جميع صلواتك مسجّلة',
              style: AppFonts.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MissedPrayersHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.85),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // App bar row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Get.back(),
                  ),
                  Expanded(
                    child: Text(
                      'missed_prayers'.tr,
                      textAlign: TextAlign.center,
                      style: AppFonts.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            // Info section
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'missed_prayers_desc'.tr,
                        style: AppFonts.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.90),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayGroupHeader extends StatelessWidget {
  final String label;
  final int count;
  final bool isLogging;
  final VoidCallback onLogAll;

  const _DayGroupHeader({
    required this.label,
    required this.count,
    required this.isLogging,
    required this.onLogAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 13,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  '$label ($count)',
                  style: AppFonts.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: isLogging ? null : onLogAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isLogging
                    ? Colors.grey.withValues(alpha: 0.10)
                    : AppColors.success.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  if (isLogging)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 14,
                      color: AppColors.success,
                    ),
                  const SizedBox(width: 5),
                  Text(
                    'qada_log_all'.tr,
                    style: AppFonts.labelSmall.copyWith(
                      color: isLogging
                          ? AppColors.textSecondary
                          : AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  final MissedPrayersController controller;
  const _BottomActions({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          OutlinedButton(
            onPressed: controller.skip,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              ),
              side: BorderSide(color: AppColors.divider),
            ),
            child: Text(
              'skip_for_now'.tr,
              style: AppFonts.labelLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Obx(
              () => ElevatedButton(
                onPressed: controller.isSaving.value
                    ? null
                    : controller.saveAll,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  ),
                  elevation: 0,
                  shadowColor: AppColors.primary.withValues(alpha: 0.4),
                ),
                child: controller.isSaving.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'save_all'.tr,
                        style: AppFonts.titleSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
