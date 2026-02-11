import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/routes/app_routes.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/controller/dashboard_controller.dart';
import 'package:salah/view/screens/family/family_dashboard_screen.dart';
import 'package:salah/core/helpers/prayer_timing_helper.dart';
import 'package:salah/data/models/prayer_log_model.dart';
import 'package:salah/view/screens/settings/select_city_screen.dart';
import 'package:salah/view/widgets/app_loading.dart';
import 'package:salah/view/widgets/connection_status_indicator.dart';
import 'package:salah/view/widgets/smart_prayer_circle.dart';
import 'package:salah/view/widgets/daily_review_card.dart';
import 'package:salah/view/widgets/prayer_heatmap.dart';
import 'package:salah/view/widgets/drawer.dart';
import 'package:salah/view/screens/qibla/qibla_screen.dart';

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
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            children: [
              const SizedBox(height: AppDimensions.paddingLG),

              // Daily Review Card (visible after Isha)
              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingLG,
                ),
                child: DailyReviewCard(),
              ),

              // Streak Badge
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingLG,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.local_fire_department,
                            color: Colors.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Obx(
                            () => Text(
                              '${controller.currentStreak.value} ${'day_unit'.tr}',
                              style: AppFonts.labelMedium.copyWith(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.paddingXL),

              // Live Smart Prayer Circle
              const SmartPrayerCircle(),

              const SizedBox(height: AppDimensions.paddingXL),

              // Connection Status
              const ConnectionStatusIndicator(),

              const SizedBox(height: AppDimensions.paddingMD),

              // Progress
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingLG,
                ),
                child: _buildTodayProgress(controller),
              ),

              const SizedBox(height: AppDimensions.paddingLG),

              // Quick Prayer Icons (Timeline)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingMD,
                ),
                child: _buildQuickPrayerIcons(controller),
              ),

              const SizedBox(height: AppDimensions.paddingXL),

              // Prayer Heatmap (6 months view)
              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingMD,
                ),
                child: PrayerHeatmap(),
              ),

              const SizedBox(height: AppDimensions.paddingXL),
            ],
          ),
        );
      }),
    );
  }

  /// Progress Card
  Widget _buildTodayProgress(DashboardController controller) {
    return Obx(() {
      final completed = controller.todayLogs
          .where((log) => log.prayer != PrayerName.sunrise)
          .length;
      const total = 5;
      final progress = completed / total;

      return Container(
        padding: const EdgeInsets.all(AppDimensions.paddingMD),
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
                        ? Colors.green
                        : AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  completed >= total ? Colors.green : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Quick Prayer Icons
  Widget _buildQuickPrayerIcons(DashboardController controller) {
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
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingMD,
              vertical: AppDimensions.paddingSM,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: prayers.map((prayer) {
                PrayerLogModel? log;
                try {
                  log = controller.todayLogs.firstWhere(
                    (l) => l.prayer == (prayer.prayerType ?? PrayerName.fajr),
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
          // "Log All" button when 2+ past prayers are unlogged
          if (unloggedPastCount >= 2) ...[
            const SizedBox(height: AppDimensions.paddingSM),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => controller.logAllUnloggedPrayers(),
                icon: const Icon(Icons.done_all_rounded, size: 18),
                label: Text('log_all_prayers'.tr),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
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
    IconData icon;

    if (isLogged && quality != null) {
      iconColor = PrayerTimingHelper.getLegacyQualityColor(quality);
      bgColor = iconColor.withValues(alpha: 0.15);
      icon = Icons.check_circle;
    } else if (isLogged) {
      bgColor = Colors.green.withValues(alpha: 0.15);
      iconColor = Colors.green;
      icon = Icons.check_circle;
    } else if (isPastUnlogged) {
      bgColor = Colors.orange.withValues(alpha: 0.15);
      iconColor = Colors.orange;
      icon = Icons.add_circle_outline;
    } else if (isCurrent) {
      bgColor = AppColors.primary.withValues(alpha: 0.15);
      iconColor = AppColors.primary;
      icon = Icons.access_time_filled;
    } else if (isNext) {
      bgColor = Colors.orange.withValues(alpha: 0.15);
      iconColor = Colors.orange;
      icon = Icons.schedule;
    } else {
      bgColor = Colors.grey.withValues(alpha: 0.1);
      iconColor = Colors.grey;
      icon = Icons.access_time;
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              border: (isCurrent || isPastUnlogged)
                  ? Border.all(color: iconColor, width: 2)
                  : null,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: AppFonts.labelSmall.copyWith(
              color: isLogged && quality != null
                  ? PrayerTimingHelper.getLegacyQualityColor(quality)
                  : isLogged
                  ? Colors.green
                  : isPastUnlogged
                  ? Colors.orange
                  : AppColors.textPrimary,
              fontWeight: (isCurrent || isPastUnlogged)
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
          Text(
            time,
            style: AppFonts.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DashboardAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      centerTitle: true,
      // Settings Button
      leading: IconButton(
        icon: Icon(Icons.menu, color: AppColors.textPrimary),
        onPressed: () => controller.scaffoldKey.currentState?.openDrawer(),
      ),
      // City Name in Center
      title: InkWell(
        onTap: () => Get.toNamed(AppRoutes.selectCity),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 3,
          children: [
            Icon(
              Icons.edit_location_outlined,
              size: 18,
              color: AppColors.textSecondary,
            ),
            Obx(
              () => Text(
                controller.currentCity.value.split(',').first,
                style: AppFonts.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),

      // Qibla Action
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
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  String _getDateString() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }
}
