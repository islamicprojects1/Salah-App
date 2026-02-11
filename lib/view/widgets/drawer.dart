import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/controller/settings/settings_controller.dart';
import 'package:salah/core/routes/app_routes.dart';
import 'package:salah/core/services/auth_service.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final settingsCtrl = Get.find<SettingsController>();

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Stack(
        children: [
          // Glassmorphism Blur Effect
          ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.8),
                  border: Border(
                    right: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(authService),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      const SizedBox(height: 20),
                      _buildSectionHeader('personalization'.tr),
                      _buildMenuItem(
                        icon: Icons.translate_rounded,
                        title: 'language'.tr,
                        onTap: () {
                          Get.back();
                          Get.toNamed(AppRoutes.settings);
                        },
                      ),
                      _buildThemeToggle(settingsCtrl),
                      _buildMenuItem(
                        icon: Icons.palette_outlined,
                        title: 'app_appearance'.tr,
                        onTap: () {
                          Get.back();
                          Get.toNamed(AppRoutes.settings);
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.volume_up_outlined,
                        title: 'sound_settings'.tr,
                        onTap: () {
                          Get.back();
                          Get.toNamed(AppRoutes.settings);
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.settings_outlined,
                        title: 'settings'.tr,
                        onTap: () {
                          Get.back();
                          Get.toNamed(AppRoutes.settings);
                        },
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(color: Colors.white10),
                      ),

                      _buildSectionHeader('integration_sync'.tr),
                      _buildMenuItem(
                        icon: Icons.calendar_today_outlined,
                        title: 'google_calendar_sync'.tr,
                        onTap: () {
                          Get.back();
                          settingsCtrl.syncWithGoogleCalendar();
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.people_outline_rounded,
                        title: 'social_media'.tr,
                        onTap: () {
                          // Show social links dialog or navigate
                          Get.snackbar('info'.tr, 'coming_soon'.tr);
                        },
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(color: Colors.white10),
                      ),

                      _buildSectionHeader('support_feedback'.tr),
                      _buildMenuItem(
                        icon: Icons.email_outlined,
                        title: 'contact_us_email'.tr,
                        onTap: () {
                          Get.back();
                          settingsCtrl.reportBug();
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.bug_report_outlined,
                        title: 'report_bug'.tr,
                        onTap: () {
                          Get.back();
                          settingsCtrl.reportBug();
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.lightbulb_outline_rounded,
                        title: 'suggest_feature'.tr,
                        onTap: () {
                          Get.back();
                          settingsCtrl.suggestFeature();
                        },
                      ),

                      const SizedBox(height: 40),
                      _buildLogoutButton(settingsCtrl, authService),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AuthService authService) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Obx(() {
            final photoUrl = authService.userPhotoUrl;
            return InkWell(
              onTap: () {
                Get.back();
                Get.toNamed(AppRoutes.profile);
              },
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: photoUrl != null
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl == null
                      ? const Icon(
                          Icons.person,
                          color: AppColors.primary,
                          size: 35,
                        )
                      : null,
                ),
              ),
            );
          }),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(
                  () => Text(
                    authService.userName ?? 'app_name'.tr,
                    style: AppFonts.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Obx(
                  () => Text(
                    authService.userEmail ?? '',
                    style: AppFonts.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 12, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: AppFonts.labelSmall.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Icon(icon, color: AppColors.textPrimary, size: 22),
      title: Text(
        title,
        style: AppFonts.bodyMedium.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: AppColors.textSecondary,
      ),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildThemeToggle(SettingsController settingsCtrl) {
    return Obx(() {
      final isDark = settingsCtrl.isDarkMode;
      return ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
          color: isDark ? AppColors.secondary : AppColors.orange,
          size: 22,
        ),
        title: Text(
          'theme_dark'.tr,
          style: AppFonts.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Switch.adaptive(
          value: isDark,
          activeColor: AppColors.secondary,
          onChanged: (_) => settingsCtrl.toggleTheme(),
        ),
      );
    });
  }

  Widget _buildLogoutButton(
    SettingsController settingsCtrl,
    AuthService authService,
  ) {
    return ListTile(
      onTap: () async {
        Get.back();
        try {
          await settingsCtrl.logout();
        } catch (_) {
          await authService.signOut();
          Get.offAllNamed(AppRoutes.login);
        }
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.error.withValues(alpha: 0.1)),
      ),
      leading: const Icon(
        Icons.logout_rounded,
        color: AppColors.error,
        size: 22,
      ),
      title: Text(
        'logout'.tr,
        style: AppFonts.bodyMedium.copyWith(
          color: AppColors.error,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Text(
          'about_app_salah'.tr,
          style: AppFonts.labelSmall.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
