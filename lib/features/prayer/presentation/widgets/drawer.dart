import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/di/injection_container.dart';
import 'package:salah/core/routes/app_routes.dart';
import 'package:salah/core/feedback/app_feedback.dart';
import 'package:salah/features/auth/data/services/auth_service.dart';
import 'package:salah/features/settings/controller/settings_controller.dart';
import 'package:salah/features/settings/data/services/localization_service.dart';
import 'package:salah/features/settings/data/services/theme_service.dart';
import 'package:salah/features/prayer/presentation/widgets/drawer_expansions.dart';
import 'package:salah/features/prayer/presentation/widgets/drawer_parts.dart';
import 'package:salah/core/constants/app_dimensions.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = sl<AuthService>();
    final settingsCtrl = Get.find<SettingsController>();
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Stack(
        children: [
          ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.8),
                  border: Border(
                    right: BorderSide(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                buildDrawerHeader(authService),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLG),
                    children: [
                      const SizedBox(height: AppDimensions.spaceXL),
                      buildDrawerSectionHeader('personalization'.tr),
                      buildDrawerLanguageExpansion(sl<LocalizationService>()),
                      buildDrawerThemeExpansion(
                        sl<ThemeService>(),
                        settingsCtrl,
                      ),
                      buildDrawerSoundExpansion(settingsCtrl),
                      buildDrawerMenuItem(
                        icon: Icons.settings_outlined,
                        title: 'settings'.tr,
                        subtitle: 'drawer_settings_subtitle'.tr,
                        onTap: () {
                          Get.back();
                          Get.toNamed(AppRoutes.settings);
                        },
                      ),
                      buildDrawerMenuItem(
                        icon: Icons.bar_chart_rounded,
                        title: 'my_stats'.tr,
                        onTap: () {
                          Get.back();
                          Get.toNamed(AppRoutes.stats);
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingSM + 2),
                        child: Divider(
                          color: Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: 0.5),
                        ),
                      ),
                      buildDrawerSectionHeader('integration_sync'.tr),
                      buildDrawerMenuItem(
                        icon: Icons.calendar_today_outlined,
                        title: 'google_calendar_sync'.tr,
                        onTap: () {
                          Get.back();
                          settingsCtrl.syncWithGoogleCalendar();
                        },
                      ),
                      buildDrawerMenuItem(
                        icon: Icons.people_outline_rounded,
                        title: 'social_media'.tr,
                        onTap: () {
                          AppFeedback.showSnackbar('info'.tr, 'coming_soon'.tr);
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Divider(
                          color: Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: 0.5),
                        ),
                      ),
                      buildDrawerSectionHeader('support_feedback'.tr),
                      buildDrawerMenuItem(
                        icon: Icons.email_outlined,
                        title: 'contact_us_email'.tr,
                        onTap: () {
                          Get.back();
                          settingsCtrl.reportBug();
                        },
                      ),
                      buildDrawerMenuItem(
                        icon: Icons.bug_report_outlined,
                        title: 'report_bug'.tr,
                        onTap: () {
                          Get.back();
                          settingsCtrl.reportBug();
                        },
                      ),
                      buildDrawerMenuItem(
                        icon: Icons.lightbulb_outline_rounded,
                        title: 'suggest_feature'.tr,
                        onTap: () {
                          Get.back();
                          settingsCtrl.suggestFeature();
                        },
                      ),
                      const SizedBox(height: AppDimensions.spaceHuge),
                      buildDrawerLogoutButton(settingsCtrl, authService),
                      const SizedBox(height: AppDimensions.spaceXL),
                    ],
                  ),
                ),
                buildDrawerFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
