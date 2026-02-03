import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/controller/dashboard_controller.dart';
import 'package:salah/controller/family_controller.dart';
import 'package:salah/view/screens/family/family_dashboard_screen.dart';
import 'package:salah/view/screens/settings/settings_screen.dart';
import 'package:salah/view/screens/qibla/qibla_screen.dart';
import 'package:salah/core/services/prayer_time_service.dart';
import 'package:salah/data/models/prayer_log_model.dart';
import 'package:salah/view/widgets/app_button.dart';
import 'package:salah/view/widgets/prayer_timeline.dart';

class DashboardScreen extends GetView<DashboardController> {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
      backgroundColor: AppColors.background,
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    ));
  }

  Widget _buildBody() {
    switch (controller.tabIndex.value) {
      case 0:
        return _buildHomeContent();
      case 1:
        // Lazy load/ensure FamilyController is available if using BottomNav
        // Usually handled by bindings or Get.put
        return const FamilyDashboardScreen();
      case 2:
        return const QiblaScreen();
      case 3:
        return const SettingsScreen();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildBottomBar() {
    return BottomNavigationBar(
      currentIndex: controller.tabIndex.value,
      onTap: controller.changeTabIndex,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'الرئيسية',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.family_restroom_outlined),
          activeIcon: Icon(Icons.family_restroom),
          label: 'العائلة',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.explore_outlined),
          activeIcon: Icon(Icons.explore),
          label: 'القبلة',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          activeIcon: Icon(Icons.settings),
          label: 'الإعدادات',
        ),
      ],
    );
  }

  Widget _buildHomeContent() {
    return SafeArea(
      child: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              
              const SizedBox(height: AppDimensions.paddingXL),
              
              // Timeline
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMD),
                child: PrayerTimeline(
                  prayers: controller.todayPrayers,
                  currentPrayer: controller.currentPrayer.value,
                  nextPrayer: controller.nextPrayer.value,
                  completedPrayers: controller.todayLogs.map((l) => l.prayer).toList(),
                ),
              ),
              
              const SizedBox(height: AppDimensions.paddingXL),
              
              // Action Button (I Prayed)
              _buildActionSection(),

              const SizedBox(height: AppDimensions.paddingXL),
              
              // Prayer List
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLG),
                child: Text(
                  'مواقيت اليوم',
                  style: AppFonts.titleLarge.copyWith(color: AppColors.textPrimary),
                ),
              ),
              _buildPrayerTimesList(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLG),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'الصلاة القادمة',
                        style: AppFonts.bodyMedium.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(width: AppDimensions.paddingSM),
                      Obx(() => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${controller.currentStreak.value}',
                              style: AppFonts.labelSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                  Text(
                    controller.nextPrayer.value?.name ?? 'الفجر',
                    style: AppFonts.headlineMedium.copyWith(color: Colors.white),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    controller.currentCity.value,
                    style: AppFonts.bodyMedium.copyWith(color: Colors.white70),
                  ),
                  Text(
                    controller.timeUntilNextPrayer.value,
                    style: AppFonts.headlineLarge.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection() {
    final current = controller.currentPrayer.value;
    if (current == null) return const SizedBox.shrink();

    return Obx(() {
      final isLogged = controller.todayLogs.any((l) => l.prayer.name.toLowerCase() == current.name.toLowerCase() 
          || (current.name == 'الشروق' && l.prayer == PrayerName.sunrise));

      if (isLogged) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLG),
          child: Column(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 48),
              const SizedBox(height: AppDimensions.paddingSM),
              Text(
                'تقبل الله صلاتك',
                style: AppFonts.titleMedium.copyWith(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLG),
        child: Column(
          children: [
            Text(
              'هل صليت ${current.name}؟',
              style: AppFonts.titleMedium,
            ),
            const SizedBox(height: AppDimensions.paddingMD),
            AppButton(
              text: 'نعم، صليت',
              icon: Icons.check,
              onPressed: () => controller.logPrayer(current),
              width: double.infinity,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPrayerTimesList() {
    return Obx(() => ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.todayPrayers.length,
      padding: const EdgeInsets.all(AppDimensions.paddingMD),
      itemBuilder: (context, index) {
        final prayer = controller.todayPrayers[index];
        final isNext = prayer == controller.nextPrayer.value;
        final isLogged = controller.todayLogs.any((l) => l.prayer.name.toLowerCase() == prayer.name.toLowerCase() 
            || (prayer.name == 'الشروق' && l.prayer == PrayerName.sunrise));
        
        return Card(
          elevation: isNext ? 4 : 0,
          color: isNext ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          margin: const EdgeInsets.only(bottom: AppDimensions.paddingSM),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            side: isNext ? BorderSide(color: AppColors.primary, width: 1.5) : BorderSide.none,
          ),
          child: ListTile(
            leading: Icon(
              isLogged ? Icons.check_circle : Icons.access_time, 
              color: isLogged ? Colors.green : (isNext ? AppColors.primary : AppColors.textSecondary)
            ),
            title: Text(
              prayer.name,
              style: isNext 
                  ? AppFonts.titleMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)
                  : AppFonts.titleMedium,
            ),
            trailing: Text(
              _formatTime(prayer.dateTime),
              style: AppFonts.bodyLarge,
            ),
          ),
        );
      },
    ));
  }
  
  String _formatTime(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
