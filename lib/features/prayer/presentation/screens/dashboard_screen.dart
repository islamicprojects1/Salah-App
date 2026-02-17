import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/routes/app_routes.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/core/widgets/app_loading.dart';
import 'package:salah/core/widgets/connection_status_indicator.dart';
import 'package:salah/features/family/presentation/screens/family_dashboard_screen.dart';
import 'package:salah/features/prayer/controller/dashboard_controller.dart';
import 'dart:async'; // Add async import for Timer

import 'package:salah/core/helpers/prayer_timing_helper.dart';

import 'package:salah/core/helpers/date_time_helper.dart';
import 'package:salah/features/prayer/data/models/prayer_log_model.dart';
import 'package:salah/features/prayer/presentation/screens/qibla_screen.dart';
import 'package:salah/features/prayer/presentation/widgets/daily_review_card.dart';
import 'package:salah/features/prayer/presentation/widgets/drawer.dart';
import 'package:salah/features/prayer/presentation/widgets/smart_prayer_circle.dart';

class DashboardScreen extends GetView<DashboardController> {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Controller is initialized by DashboardBinding
    final controller = Get.find<DashboardController>();

    return Scaffold(
      key: controller.scaffoldKey,
      drawer: const CustomDrawer(),
      backgroundColor: AppColors.background,
      appBar: const DashboardAppBar(),
      body: Obx(
        () => IndexedStack(
          index: controller.currentTabIndex.value,
          children: const [DashboardHomeContent(), FamilyDashboardScreen()],
        ),
      ),
      bottomNavigationBar: Obx(
        () => NavigationBar(
          selectedIndex: controller.currentTabIndex.value,
          onDestinationSelected: controller.changeTab,
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primary.withValues(alpha: 0.2),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: AppColors.primary),
              label: 'home'.tr,
            ),
            NavigationDestination(
              icon: const Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people, color: AppColors.primary),
              label: 'family'.tr,
            ),
          ],
        ),
      ),
    );
  }
}

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
              Obx(() => controller.isUsingDefaultLocation
                  ? _LocationHintBanner(onTap: controller.openSelectCity)
                  : const SizedBox.shrink()),
              const SizedBox(height: AppDimensions.paddingMD),
              // Clock + Streak on same line
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingLG,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(child: _DigitalClock()),
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

              // Daily Review Card (visible after Isha)
              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingLG,
                ),
                child: DailyReviewCard(),
              ),

              const SizedBox(height: AppDimensions.paddingXL),

              // Live Smart Prayer Circle
              const SmartPrayerCircle(),

              const SizedBox(height: AppDimensions.paddingXL),

              // Connection Status (offline / pending sync)
              const ConnectionStatusIndicator(),
              const SizedBox(height: AppDimensions.paddingMD),

              // Progress
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingLG,
                ),
                child: _buildTodayProgress(context, controller),
              ),

              const SizedBox(height: AppDimensions.paddingLG),

              // Quick Prayer Icons (Timeline)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingMD,
                ),
                child: _buildQuickPrayerIcons(context, controller),
              ),
              // Bottom padding so last item isn't flush with nav bar
              const SizedBox(height: AppDimensions.paddingXL),
            ],
          ),
        );
      }),
    );
  }

  /// Progress Card
  Widget _buildTodayProgress(
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
        margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLG),
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
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'todays_prayers_label'.tr,
                  style: AppFonts.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
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
            const SizedBox(height: AppDimensions.paddingMD),
            ClipRRect(
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
          ],
        ),
      );
    });
  }

  /// Quick Prayer Icons
  Widget _buildQuickPrayerIcons(
    BuildContext context,
    DashboardController controller,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Obx(() {
      final prayers = controller.todayPrayers
          .where((p) => p.prayerType != PrayerName.sunrise)
          .toList();
      final now = DateTime.now();

      // Count past unlogged prayers for the "log all" button
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
                      log = controller.todayLogs.firstWhere(
                        (l) => l.prayer == prayerType,
                      );
                    } catch (_) {
                      log = null;
                    }
                    final isLogged = log != null;
                    final isNext = prayer == controller.nextPrayer.value;
                    final isCurrent = prayer == controller.currentPrayer.value;
                    final isPast = !prayer.dateTime.isAfter(now) && !isCurrent;
                    final quality = log?.quality;

                    return _buildPrayerIcon(
                      controller: controller,
                      prayerType: prayerType,
                      prayer: prayer,
                      name: prayer.name,
                      time: _formatTime(prayer.dateTime),
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
          // "Log All" button when 2+ past prayers are unlogged
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

  Widget _buildPrayerIcon({
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
          // Icon with Bloom/Glow if current/next
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

  String _formatTime(DateTime date) {
    return DateTimeHelper.formatTime12(date);
  }
}

class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DashboardAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    return Obx(() {
      final isDefaultLocation =
          controller.currentCity.value == 'makkah_fallback_label'.tr;
      return AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        bottom: isDefaultLocation
            ? PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  color: AppColors.error.withValues(alpha: 0.2),
                  height: 1,
                ),
              )
            : null,
        leading: IconButton(
          icon: Icon(Icons.menu, color: AppColors.textPrimary),
          onPressed: () => controller.scaffoldKey.currentState?.openDrawer(),
        ),
        title: InkWell(
        onTap: () => Get.toNamed(AppRoutes.selectCity),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 3,
          children: [
            Obx(
              () => Icon(
                controller.currentCity.value == 'makkah_fallback_label'.tr
                    ? Icons.location_off_outlined
                    : Icons.edit_location_outlined,
                size: 18,
                color:
                    controller.currentCity.value == 'makkah_fallback_label'.tr
                    ? AppColors.error
                    : AppColors.textSecondary,
              ),
            ),
            Flexible(
              child: Obx(
                () => Text(
                  controller.currentCity.value.split(',').first,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: AppFonts.titleMedium.copyWith(
                    color:
                        controller.currentCity.value ==
                            'makkah_fallback_label'.tr
                        ? AppColors.error
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

        actions: [
          IconButton(
            icon: Icon(Icons.explore_outlined, color: AppColors.textPrimary),
            onPressed: () => Get.to(
              () => const QiblaScreen(),
              transition: Transition.downToUp,
              fullscreenDialog: true,
            ),
            tooltip: 'qibla'.tr,
          ),
        ],
      );
    });
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _LocationHintBanner extends StatelessWidget {
  const _LocationHintBanner({required this.onTap});

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

class _DigitalClock extends StatefulWidget {
  const _DigitalClock();

  @override
  State<_DigitalClock> createState() => _DigitalClockState();
}

class _DigitalClockState extends State<_DigitalClock> {
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
