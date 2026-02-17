import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/di/injection_container.dart';
import 'package:salah/core/routes/app_routes.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/widgets/app_dialogs.dart';
import 'package:salah/features/auth/data/services/auth_service.dart';
import 'package:salah/features/settings/controller/settings_controller.dart';
import 'package:salah/features/settings/data/services/localization_service.dart';
import 'package:salah/features/settings/data/services/theme_service.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = sl<AuthService>();
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
                      _buildLanguageExpansion(sl<LocalizationService>()),
                      _buildThemeExpansion(sl<ThemeService>(), settingsCtrl),
                      _buildSoundExpansion(settingsCtrl),
                      _buildMenuItem(
                        icon: Icons.settings_outlined,
                        title: 'settings'.tr,
                        subtitle: 'drawer_settings_subtitle'.tr,
                        onTap: () {
                          Get.back();
                          Get.toNamed(AppRoutes.settings);
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.bar_chart_rounded,
                        title: 'my_stats'.tr,
                        onTap: () {
                          Get.back();
                          Get.toNamed(AppRoutes.stats);
                        },
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Divider(
                          color: Theme.of(context).dividerColor.withValues(
                            alpha: 0.5,
                          ),
                        ),
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

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Divider(
                          color: Theme.of(context).dividerColor.withValues(
                            alpha: 0.5,
                          ),
                        ),
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
    String? subtitle,
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
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: AppFonts.labelSmall.copyWith(color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: AppColors.textSecondary,
      ),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildLanguageExpansion(LocalizationService localization) {
    return Obx(() {
      final current = localization.currentLanguage.value;
      return ExpansionTile(
        initiallyExpanded: false,
        leading: Icon(Icons.translate_rounded, color: AppColors.textPrimary, size: 22),
        title: Text(
          'language'.tr,
          style: AppFonts.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          current.name,
          style: AppFonts.labelSmall.copyWith(color: AppColors.textSecondary),
        ),
        children: AppLanguage.values
            .map((lang) => ListTile(
                  dense: true,
                  title: Text(lang.name),
                  trailing: current == lang
                      ? Icon(Icons.check_rounded, color: AppColors.primary, size: 20)
                      : null,
                  onTap: () => localization.changeLanguage(lang),
                ))
            .toList(),
      );
    });
  }

  Widget _buildThemeExpansion(ThemeService themeService, SettingsController settingsCtrl) {
    return Obx(() {
      final current = themeService.currentThemeMode.value;
      String themeLabel;
      switch (current) {
        case AppThemeMode.light:
          themeLabel = 'theme_light'.tr;
          break;
        case AppThemeMode.dark:
          themeLabel = 'theme_dark'.tr;
          break;
        case AppThemeMode.system:
          themeLabel = 'theme_system'.tr;
          break;
      }
      return ExpansionTile(
        initiallyExpanded: false,
        leading: Icon(
          current == AppThemeMode.dark
              ? Icons.dark_mode_rounded
              : current == AppThemeMode.light
                  ? Icons.light_mode_rounded
                  : Icons.settings_brightness_rounded,
          color: AppColors.textPrimary,
          size: 22,
        ),
        title: Text(
          'theme'.tr,
          style: AppFonts.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          themeLabel,
          style: AppFonts.labelSmall.copyWith(color: AppColors.textSecondary),
        ),
        children: [
          _buildThemeOption(themeService, settingsCtrl, 'theme_system'.tr, AppThemeMode.system),
          _buildThemeOption(themeService, settingsCtrl, 'theme_light'.tr, AppThemeMode.light),
          _buildThemeOption(themeService, settingsCtrl, 'theme_dark'.tr, AppThemeMode.dark),
        ],
      );
    });
  }

  Widget _buildThemeOption(ThemeService themeService, SettingsController ctrl, String label, AppThemeMode mode) {
    return Obx(() => ListTile(
          dense: true,
          title: Text(label),
          trailing: themeService.currentThemeMode.value == mode
              ? Icon(Icons.check_rounded, color: AppColors.primary, size: 20)
              : null,
          onTap: () => ctrl.changeTheme(mode),
        ));
  }

  Widget _buildSoundExpansion(SettingsController settingsCtrl) {
    return Obx(() {
      final current = settingsCtrl.notificationSoundMode.value;
      String soundLabel;
      IconData soundIcon;
      switch (current) {
        case NotificationSoundMode.adhan:
          soundLabel = 'sound_adhan'.tr;
          soundIcon = Icons.volume_up_rounded;
          break;
        case NotificationSoundMode.vibrate:
          soundLabel = 'sound_vibrate'.tr;
          soundIcon = Icons.vibration_rounded;
          break;
        case NotificationSoundMode.silent:
          soundLabel = 'sound_silent'.tr;
          soundIcon = Icons.notifications_off_rounded;
          break;
      }
      return ExpansionTile(
        initiallyExpanded: false,
        leading: Icon(soundIcon, color: AppColors.textPrimary, size: 22),
        title: Text(
          'sound_settings'.tr,
          style: AppFonts.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          soundLabel,
          style: AppFonts.labelSmall.copyWith(color: AppColors.textSecondary),
        ),
        children: [
          _buildSoundOption(settingsCtrl, 'sound_adhan'.tr, NotificationSoundMode.adhan),
          _buildSoundOption(settingsCtrl, 'sound_vibrate'.tr, NotificationSoundMode.vibrate),
          _buildSoundOption(settingsCtrl, 'sound_silent'.tr, NotificationSoundMode.silent),
        ],
      );
    });
  }

  ListTile _buildSoundOption(SettingsController ctrl, String label, NotificationSoundMode mode) {
    return ListTile(
      dense: true,
      title: Text(label),
      trailing: ctrl.notificationSoundMode.value == mode
          ? Icon(Icons.check_rounded, color: AppColors.primary, size: 20)
          : null,
      onTap: () => ctrl.setNotificationSoundMode(mode),
    );
  }

  Widget _buildLogoutButton(
    SettingsController settingsCtrl,
    AuthService authService,
  ) {
    return ListTile(
      onTap: () async {
        Get.back();
        final confirm = await AppDialogs.confirm(
          title: 'logout'.tr,
          message: 'logout_confirm_message'.tr,
          confirmText: 'logout'.tr,
          cancelText: 'cancel'.tr,
          isDestructive: true,
        );
        if (!confirm) return;
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
