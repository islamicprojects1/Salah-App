import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/features/settings/controller/settings_controller.dart';
import 'package:salah/features/settings/data/services/localization_service.dart';
import 'package:salah/features/settings/data/services/theme_service.dart';

Widget buildDrawerLanguageExpansion(LocalizationService localization) {
  return Obx(() {
    final current = localization.currentLanguage.value;
    return ExpansionTile(
      initiallyExpanded: false,
      leading: Icon(
        Icons.translate_rounded,
        color: AppColors.textPrimary,
        size: 22,
      ),
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
          .map(
            (lang) => ListTile(
              dense: true,
              title: Text(lang.name),
              trailing: current == lang
                  ? Icon(
                      Icons.check_rounded,
                      color: AppColors.primary,
                      size: 20,
                    )
                  : null,
              onTap: () => localization.changeLanguage(lang),
            ),
          )
          .toList(),
    );
  });
}

Widget buildDrawerThemeExpansion(
  ThemeService themeService,
  SettingsController settingsCtrl,
) {
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
        _buildThemeOption(
          themeService,
          settingsCtrl,
          'theme_system'.tr,
          AppThemeMode.system,
        ),
        _buildThemeOption(
          themeService,
          settingsCtrl,
          'theme_light'.tr,
          AppThemeMode.light,
        ),
        _buildThemeOption(
          themeService,
          settingsCtrl,
          'theme_dark'.tr,
          AppThemeMode.dark,
        ),
      ],
    );
  });
}

Widget _buildThemeOption(
  ThemeService themeService,
  SettingsController ctrl,
  String label,
  AppThemeMode mode,
) {
  return Obx(
    () => ListTile(
      dense: true,
      title: Text(label),
      trailing: themeService.currentThemeMode.value == mode
          ? Icon(Icons.check_rounded, color: AppColors.primary, size: 20)
          : null,
      onTap: () => ctrl.changeTheme(mode),
    ),
  );
}

Widget buildDrawerSoundExpansion(SettingsController settingsCtrl) {
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
      default:
        soundLabel = 'sound_adhan'.tr;
        soundIcon = Icons.volume_up_rounded;
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
        _buildSoundOption(
          settingsCtrl,
          'sound_adhan'.tr,
          NotificationSoundMode.adhan,
        ),
        _buildSoundOption(
          settingsCtrl,
          'sound_vibrate'.tr,
          NotificationSoundMode.vibrate,
        ),
        _buildSoundOption(
          settingsCtrl,
          'sound_silent'.tr,
          NotificationSoundMode.silent,
        ),
      ],
    );
  });
}

Widget _buildSoundOption(
  SettingsController ctrl,
  String label,
  NotificationSoundMode mode,
) {
  return Obx(
    () => ListTile(
      dense: true,
      title: Text(label),
      trailing: ctrl.notificationSoundMode.value == mode
          ? Icon(Icons.check_rounded, color: AppColors.primary, size: 20)
          : null,
      onTap: () => ctrl.setNotificationSoundMode(mode),
    ),
  );
}
