import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/core/helpers/date_time_helper.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/core/widgets/app_loading.dart';
import 'package:salah/core/widgets/connection_status_indicator.dart';
import 'package:salah/features/prayer/controller/dashboard_controller.dart';
import 'package:salah/features/prayer/presentation/widgets/dashboard_progress_widgets.dart';
import 'package:salah/features/prayer/presentation/widgets/daily_review_card.dart';
import 'package:salah/features/prayer/presentation/widgets/smart_prayer_circle.dart';

class DashboardHomeContent extends StatefulWidget {
  const DashboardHomeContent({super.key});

  @override
  State<DashboardHomeContent> createState() => _DashboardHomeContentState();
}

class _DashboardHomeContentState extends State<DashboardHomeContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final controller = Get.find<DashboardController>();

    return SafeArea(
      child: Obx(() {
        if (controller.isLoading.value) {
          return const AppLoading(message: '');
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              Obx(
                () => controller.isUsingDefaultLocation
                    ? LocationHintBanner(onTap: controller.openSelectCity)
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: AppDimensions.paddingMD),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingLG,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(child: DigitalClock()),
                    Obx(
                      () => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.orange.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.local_fire_department,
                              color: AppColors.orange,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${controller.currentStreak.value} ${'day_unit'.tr}',
                              style: AppFonts.labelMedium.copyWith(
                                color: AppColors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppDimensions.paddingLG),
                child: DailyReviewCard(),
              ),
              const SizedBox(height: AppDimensions.paddingXL),
              const SmartPrayerCircle(),
              const SizedBox(height: AppDimensions.paddingXL),
              const ConnectionStatusIndicator(),
              const SizedBox(height: AppDimensions.paddingMD),
              _QadaReviewButton(controller: controller),
              const SizedBox(height: AppDimensions.paddingMD),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingLG,
                ),
                child: buildTodayProgress(context, controller),
              ),
              const SizedBox(height: AppDimensions.paddingLG),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingMD,
                ),
                child: buildQuickPrayerIcons(context, controller),
              ),
              const SizedBox(height: AppDimensions.paddingXL),
            ],
          ),
        );
      }),
    );
  }
}

/// Visible button to open qada (unlogged prayers) review.
class _QadaReviewButton extends StatelessWidget {
  const _QadaReviewButton({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLG),
      child: Obx(() {
        final hasUnlogged = controller.unloggedPrayers.isNotEmpty;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => controller.openQadaReview(),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingMD,
                vertical: AppDimensions.paddingSM + 2,
              ),
              decoration: BoxDecoration(
                color: hasUnlogged
                    ? AppColors.orange.withValues(alpha: 0.12)
                    : AppColors.surface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                border: Border.all(
                  color: hasUnlogged
                      ? AppColors.orange.withValues(alpha: 0.4)
                      : AppColors.divider.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    hasUnlogged
                        ? Icons.notifications_active_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 18,
                    color: hasUnlogged
                        ? AppColors.orange
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'qada_review_action'.tr,
                    style: AppFonts.bodySmall.copyWith(
                      color: hasUnlogged
                          ? AppColors.orange
                          : AppColors.textSecondary,
                      fontWeight:
                          hasUnlogged ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class LocationHintBanner extends StatelessWidget {
  const LocationHintBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLG),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppDimensions.borderRadiusLG,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingMD,
              vertical: AppDimensions.paddingSM + 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: AppDimensions.borderRadiusLG,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: AppDimensions.iconMD,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppDimensions.paddingSM),
                Expanded(
                  child: Text(
                    'location_default_hint'.tr,
                    style: AppFonts.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_left_rounded,
                  size: AppDimensions.iconMD,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DigitalClock extends StatefulWidget {
  const DigitalClock({super.key});

  @override
  State<DigitalClock> createState() => _DigitalClockState();
}

class _DigitalClockState extends State<DigitalClock> {
  late DateTime _now;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      DateTimeHelper.formatTime12(_now),
      style: AppFonts.displayLarge.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }
}
