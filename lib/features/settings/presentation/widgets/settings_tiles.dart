import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/di/injection_container.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/features/settings/controller/settings_controller.dart';
import 'package:salah/features/settings/data/services/localization_service.dart';
import 'package:salah/features/settings/data/services/theme_service.dart';
import 'package:salah/features/settings/presentation/screens/prayer_adjustment_screen.dart';
import 'package:salah/features/settings/presentation/widgets/notification_settings_view.dart';
import 'package:salah/features/settings/presentation/widgets/settings_pickers.dart';
import 'package:salah/core/constants/enums.dart';

/// Shared tile builder for settings screen
Widget buildSettingsTile(
  BuildContext context, {
  required IconData icon,
  required String title,
  String? subtitle,
  Color? iconColor,
  Color? titleColor,
  VoidCallback? onTap,
  Widget? trailing,
}) {
  return ListTile(
    leading: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: iconColor ?? AppColors.primary, size: 22),
    ),
    title: Text(
      title,
      style: AppFonts.bodyLarge.copyWith(
        color: titleColor ?? AppColors.textPrimary,
        fontWeight: FontWeight.w500,
      ),
    ),
    subtitle: subtitle != null
        ? Text(
            subtitle,
            style: AppFonts.bodySmall.copyWith(color: AppColors.textSecondary),
          )
        : null,
    trailing: trailing ??
        const Icon(Icons.chevron_right_rounded,
            color: AppColors.secondary, size: 20),
    onTap: onTap,
  );
}

Widget buildLanguageTile(BuildContext context, SettingsController controller) {
  return Obx(() {
    final current = sl<LocalizationService>().currentLanguage.value;
    return buildSettingsTile(
      context,
      icon: Icons.translate_rounded,
      title: 'language'.tr,
      subtitle: current.name,
      onTap: () => SettingsPickers.showLanguagePicker(context, controller),
    );
  });
}

Widget buildThemeTile(BuildContext context, SettingsController controller) {
  return Obx(() {
    final current = sl<ThemeService>().currentThemeMode.value;
    String themeLabel = 'theme_system'.tr;
    IconData themeIcon = Icons.settings_brightness_rounded;
    switch (current) {
      case AppThemeMode.light:
        themeLabel = 'theme_light'.tr;
        themeIcon = Icons.light_mode_rounded;
        break;
      case AppThemeMode.dark:
        themeLabel = 'theme_dark'.tr;
        themeIcon = Icons.dark_mode_rounded;
        break;
      case AppThemeMode.system:
        themeLabel = 'theme_system'.tr;
        themeIcon = Icons.settings_brightness_rounded;
        break;
    }
    return buildSettingsTile(
      context,
      icon: themeIcon,
      title: 'theme'.tr,
      subtitle: themeLabel,
      onTap: () => SettingsPickers.showThemePicker(context, controller),
    );
  });
}

Widget buildLocationTile(BuildContext context, SettingsController controller) {
  return Obx(() {
    final isLoading = controller.isLocationLoading;
    final label = controller.locationDisplayLabel;
    return buildSettingsTile(
      context,
      icon: Icons.location_on_rounded,
      title: 'location_section'.tr,
      subtitle: label,
      trailing: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 20),
              onPressed: () => controller.refreshLocation(),
            ),
      onTap: () => controller.refreshLocation(),
    );
  });
}

Widget buildNotificationTile(
  BuildContext context,
  SettingsController controller, {
  required VoidCallback onTap,
}) {
  return Obx(() => buildSettingsTile(
        context,
        icon: Icons.notifications_active_rounded,
        title: 'notifications'.tr,
        subtitle: controller.notificationsEnabled.value
            ? 'enabled'.tr
            : 'disabled'.tr,
        onTap: onTap,
      ));
}

// buildCalculationMethodTile / buildMadhabTile removed — method is now automatic per country (Aladhan API)
