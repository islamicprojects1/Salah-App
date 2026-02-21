import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/core/di/injection_container.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/features/settings/controller/settings_controller.dart';
import 'package:salah/features/settings/data/services/localization_service.dart';
import 'package:salah/features/settings/data/services/theme_service.dart';
import 'package:salah/core/constants/enums.dart';

/// Shared picker dialogs for settings (language, theme). Method/madhab now automatic via Aladhan.
class SettingsPickers {
  SettingsPickers._();

  static void showLanguagePicker(
    BuildContext context,
    SettingsController controller,
  ) {
    Get.dialog(
      AlertDialog(
        title: Text('select_language'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppLanguage.values
              .map<Widget>(
                (lang) => ListTile(
                  title: Text(lang.name),
                  trailing:
                      sl<LocalizationService>().currentLanguage.value == lang
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                  onTap: () {
                    controller.changeLanguage(lang);
                    Get.back();
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  static void showThemePicker(
    BuildContext context,
    SettingsController controller,
  ) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(AppDimensions.paddingLG),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'select_theme'.tr,
              style: AppFonts.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildThemeOption(
              controller,
              'theme_system'.tr,
              AppThemeMode.system,
            ),
            _buildThemeOption(controller, 'theme_light'.tr, AppThemeMode.light),
            _buildThemeOption(controller, 'theme_dark'.tr, AppThemeMode.dark),
          ],
        ),
      ),
    );
  }

  static Widget _buildThemeOption(
    SettingsController controller,
    String title,
    AppThemeMode mode,
  ) {
    return ListTile(
      title: Text(title),
      trailing: sl<ThemeService>().currentThemeMode.value == mode
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : null,
      onTap: () {
        controller.changeTheme(mode);
        Get.back();
      },
    );
  }
}
