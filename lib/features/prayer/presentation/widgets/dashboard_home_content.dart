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

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingLG,
          ),
          child: CustomScrollView(
            slivers: [
              // Location hint — only when using default location
              SliverToBoxAdapter(
                child: Obx(
                  () => controller.isUsingDefaultLocation
                      ? LocationHintBanner(onTap: controller.openSelectCity)
                      : const SizedBox.shrink(),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: AppDimensions.paddingMD),
              ),

              // Clock + streak row
              SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(child: DigitalClock()),
                    _StreakBadge(controller: controller),
                  ],
                ),
              ),

              // Daily review (only after Isha)
              const SliverToBoxAdapter(child: DailyReviewCard()),

              const SliverToBoxAdapter(
                child: SizedBox(height: AppDimensions.paddingSM),
              ),

              // Main prayer circle — use fixed height (LayoutBuilder incompatible with SliverFillRemaining)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.36,
                  child: const SmartPrayerCircle(),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: AppDimensions.paddingSM),
              ),

              // Connection status
              const SliverToBoxAdapter(child: ConnectionStatusIndicator()),

              const SliverToBoxAdapter(
                child: SizedBox(height: AppDimensions.paddingSM),
              ),

              // Qada review button
              SliverToBoxAdapter(
                child: _QadaReviewButton(controller: controller),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: AppDimensions.paddingSM),
              ),

              // Today progress bar
              SliverToBoxAdapter(
                child: buildTodayProgress(context, controller),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: AppDimensions.paddingSM),
              ),

              // Quick prayer icons row
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingXS,
                  ),
                  child: buildQuickPrayerIcons(context, controller),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: AppDimensions.paddingSM),
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// Streak badge extracted as its own widget to limit Obx rebuild scope
class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.controller});
  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMD,
          vertical: AppDimensions.paddingSM,
        ),
        decoration: BoxDecoration(
          color: AppColors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
          border: Border.all(color: AppColors.orange.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department,
              color: AppColors.orange,
              size: AppDimensions.iconSM,
            ),
            const SizedBox(width: AppDimensions.paddingXS),
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
        if (!hasUnlogged) return const SizedBox.shrink();
        return Material(
          color: AppColors.transparent,
          child: InkWell(
            onTap: controller.openQadaReview,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingMD,
                vertical: AppDimensions.paddingSM + 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                border: Border.all(
                  color: AppColors.orange.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_active_rounded,
                    size: AppDimensions.iconMD,
                    color: AppColors.orange,
                  ),
                  const SizedBox(width: AppDimensions.paddingSM),
                  Text(
                    'qada_review_action'.tr,
                    style: AppFonts.bodySmall.copyWith(
                      color: AppColors.orange,
                      fontWeight: FontWeight.bold,
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

/// Banner shown when using default/fallback location
class LocationHintBanner extends StatelessWidget {
  const LocationHintBanner({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLG),
      child: Material(
        color: AppColors.transparent,
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

/// Digital clock that updates every second using Timer.periodic
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
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          DateTimeHelper.formatTime12(_now),
          style: AppFonts.displayLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            height: 1.1,
          ),
        ),
        Text(
          DateTimeHelper.formatDateShort(_now),
          style: AppFonts.bodySmall.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
