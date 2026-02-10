import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/services/prayer_time_service.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/controller/dashboard_controller.dart';
import 'package:salah/view/screens/family/family_dashboard_screen.dart';
import 'package:salah/core/routes/app_routes.dart';
import 'package:salah/core/helpers/prayer_timing_helper.dart';
import 'package:salah/data/models/prayer_log_model.dart';
import 'package:salah/view/widgets/app_loading.dart';
import 'package:salah/view/widgets/connection_status_indicator.dart';
import 'package:salah/view/widgets/smart_prayer_circle.dart';
import 'package:salah/view/screens/qibla/qibla_screen.dart';

class DashboardScreen extends GetView<DashboardController> {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      centerTitle: true,
      // Settings Button
      leading: IconButton(
        icon: Icon(Icons.settings_outlined, color: AppColors.textPrimary),
        onPressed: () => Get.toNamed(AppRoutes.settings),
      ),
      // City Name in Center
      title: Obx(
        () => Column(
          children: [
            Text(
              controller.currentCity.value,
              style: AppFonts.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _getDateString(),
              style: AppFonts.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
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

      // Tabs: Dashboard | Family
      bottom: TabBar(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        labelStyle: AppFonts.titleSmall.copyWith(fontWeight: FontWeight.bold),
        tabs: [
          Tab(text: 'dashboard'.tr),
          Tab(text: 'family_tab'.tr),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return TabBarView(
      children: [_buildHomeContent(), const FamilyDashboardScreen()],
    );
  }

  Widget _buildHomeContent() {
    return SafeArea(
      child: Obx(() {
        if (controller.isLoading.value) {
          return const AppLoading(message: '');
        }

        return SingleChildScrollView(
          padding: EdgeInsets.only(bottom: 20),
          child: Column(
            children: [
              const SizedBox(height: AppDimensions.paddingLG),

              // Streak Badge (Moved from old header)
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

              // Progress - صلوات اليوم
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingLG,
                ),
                child: _buildTodayProgress(),
              ),

              const SizedBox(height: AppDimensions.paddingLG),

              // Quick Prayer Icons (Timeline)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingMD,
                ),
                child: _buildQuickPrayerIcons(),
              ),

              const SizedBox(height: AppDimensions.paddingXL),
            ],
          ),
        );
      }),
    );
  }

  String _getDateString() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }

  /// Progress Card
  Widget _buildTodayProgress() {
    return Obx(() {
      final completed = controller.todayLogs
          .where((log) => log.prayer != PrayerName.sunrise)
          .length;
      final total = 5;
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
  Widget _buildQuickPrayerIcons() {
    return Obx(() {
      final prayers = controller.todayPrayers
          .where((p) => p.prayerType != PrayerName.sunrise)
          .toList();

      return Container(
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
            final quality = log?.quality;

            return _buildPrayerIcon(
              name: prayer.name,
              time: _formatTime(prayer.dateTime),
              isLogged: isLogged,
              quality: quality,
              isNext: isNext,
              isCurrent: isCurrent,
              onTap: isCurrent && !isLogged
                  ? () => controller.logPrayer(prayer)
                  : null,
            );
          }).toList(),
        ),
      );
    });
  }

  Widget _buildPrayerIcon({
    required String name,
    required String time,
    required bool isLogged,
    PrayerQuality? quality,
    required bool isNext,
    required bool isCurrent,
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
              border: isCurrent ? Border.all(color: iconColor, width: 2) : null,
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
                      : AppColors.textPrimary,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
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
