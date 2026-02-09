import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/controller/dashboard_controller.dart';
import 'package:salah/view/screens/family/family_dashboard_screen.dart';
import 'package:salah/view/screens/settings/settings_screen.dart';
import 'package:salah/view/screens/qibla/qibla_screen.dart';
import 'package:salah/core/helpers/prayer_names.dart';
import 'package:salah/core/services/prayer_time_service.dart';
import 'package:salah/view/widgets/app_button.dart';
import 'package:salah/view/widgets/app_loading.dart';

class DashboardScreen extends GetView<DashboardController> {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    return Obx(() {
      switch (controller.tabIndex.value) {
        case 0:
          return _buildHomeContent();
        case 1:
          return const FamilyDashboardScreen();
        case 2:
          return const SizedBox.shrink();
        case 3:
          return const SettingsScreen();
        default:
          return _buildHomeContent();
      }
    });
  }

  Widget _buildBottomBar() {
    return Obx(
      () => BottomNavigationBar(
        currentIndex: controller.tabIndex.value,
        onTap: (index) {
          if (index == 2) {
            Get.to(
              () => const QiblaScreen(),
              transition: Transition.downToUp,
              fullscreenDialog: true,
            );
          } else {
            controller.changeTabIndex(index);
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'home'.tr,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.family_restroom_outlined),
            activeIcon: Icon(Icons.family_restroom),
            label: 'family'.tr,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'qibla'.tr,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'settings'.tr,
          ),
        ],
      ),
    );
  }

  /// الشاشة الرئيسية المبسطة - بدون scroll
  Widget _buildHomeContent() {
    return SafeArea(
      child: Obx(() {
        if (controller.isLoading.value) {
          return const AppLoading(message: 'جاري التحميل...');
        }

        return Column(
          children: [
            // Header - الصلاة القادمة
            _buildCompactHeader(),
            
            const SizedBox(height: AppDimensions.paddingLG),
            
            // Progress - صلوات اليوم
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLG),
              child: _buildTodayProgress(),
            ),
            
            const Spacer(),
            
            // Main Action - زر التسجيل الرئيسي
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLG),
              child: _buildMainAction(),
            ),
            
            const Spacer(),
            
            // Quick Prayer Icons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMD),
              child: _buildQuickPrayerIcons(),
            ),
            
            const SizedBox(height: AppDimensions.paddingXL),
          ],
        );
      }),
    );
  }

  /// Header مدمج - الصلاة القادمة + الوقت المتبقي
  Widget _buildCompactHeader() {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.paddingLG),
      padding: const EdgeInsets.all(AppDimensions.paddingLG),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // الصلاة القادمة
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'next_prayer'.tr,
                      style: AppFonts.bodyMedium.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Streak Badge
                    Obx(() => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department, color: Colors.orange, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            '${controller.currentStreak.value}',
                            style: AppFonts.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
                const SizedBox(height: 4),
                Obx(() => Text(
                  controller.nextPrayer.value?.name ?? 
                      PrayerNames.displayName(PrayerName.fajr),
                  style: AppFonts.headlineLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )),
              ],
            ),
          ),
          
          // الوقت المتبقي
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                controller.currentCity.value,
                style: AppFonts.bodySmall.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Obx(() => Text(
                controller.timeUntilNextPrayer.value,
                style: AppFonts.headlineMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              )),
            ],
          ),
        ],
      ),
    );
  }

  /// Progress Card - صلوات اليوم بشكل واضح
  Widget _buildTodayProgress() {
    return Obx(() {
      final completed = controller.todayLogs.length;
      final total = 5;
      final progress = completed / total;
      
      return Container(
        padding: const EdgeInsets.all(AppDimensions.paddingMD),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'صلوات اليوم',
                  style: AppFonts.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '$completed/$total',
                  style: AppFonts.titleLarge.copyWith(
                    color: completed >= total ? Colors.green : AppColors.primary,
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
                backgroundColor: AppColors.primary.withOpacity(0.1),
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

  /// الزر الرئيسي - سجلت صلاتي
  Widget _buildMainAction() {
    return Obx(() {
      final current = controller.currentPrayer.value;
      if (current == null) return const SizedBox.shrink();
      
      final isLogged = PrayerNames.isPrayerLogged(
        controller.todayLogs,
        current.name,
        current.prayerType,
      );

      if (isLogged) {
        return Container(
          padding: const EdgeInsets.all(AppDimensions.paddingXL),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 60),
              const SizedBox(height: 12),
              Text(
                'تم تسجيل ${current.name} ✓',
                style: AppFonts.titleLarge.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'prayer_accepted'.tr,
                style: AppFonts.bodyMedium.copyWith(color: Colors.green.shade700),
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          Text(
            'هل صليت ${current.name}؟',
            style: AppFonts.titleMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          
          // زر كبير للتسجيل
          SizedBox(
            width: double.infinity,
            height: 70,
            child: ElevatedButton.icon(
              onPressed: () => controller.logPrayer(current),
              icon: const Icon(Icons.check, size: 28),
              label: Text(
                'نعم، صليت ✓',
                style: AppFonts.titleLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                ),
                elevation: 4,
              ),
            ),
          ),
        ],
      );
    });
  }

  /// أيقونات الصلوات السريعة
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
            final isLogged = PrayerNames.isPrayerLogged(
              controller.todayLogs,
              prayer.name,
              prayer.prayerType,
            );
            final isNext = prayer == controller.nextPrayer.value;
            final isCurrent = prayer == controller.currentPrayer.value;
            
            return _buildPrayerIcon(
              name: prayer.name,
              time: _formatTime(prayer.dateTime),
              isLogged: isLogged,
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
    required bool isNext,
    required bool isCurrent,
    VoidCallback? onTap,
  }) {
    Color bgColor;
    Color iconColor;
    IconData icon;
    
    if (isLogged) {
      bgColor = Colors.green.withOpacity(0.15);
      iconColor = Colors.green;
      icon = Icons.check_circle;
    } else if (isCurrent) {
      bgColor = AppColors.primary.withOpacity(0.15);
      iconColor = AppColors.primary;
      icon = Icons.access_time_filled;
    } else if (isNext) {
      bgColor = Colors.orange.withOpacity(0.15);
      iconColor = Colors.orange;
      icon = Icons.schedule;
    } else {
      bgColor = Colors.grey.withOpacity(0.1);
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
              color: isLogged ? Colors.green : AppColors.textPrimary,
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
