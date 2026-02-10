import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:adhan/adhan.dart' as adhan;
import 'package:salah/controller/settings_controller.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/services/theme_service.dart';
import 'package:salah/core/services/localization_service.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/data/models/user_model.dart';
import 'package:salah/view/widgets/app_dialogs.dart';

/// Settings screen for app preferences
///
/// Allows users to change language and theme
class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('settings'.tr),
        elevation: 0,
        backgroundColor: AppColors.surface,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMD,
          vertical: AppDimensions.paddingLG,
        ),
        children: [
          // --- General Preferences ---
          _buildHeader('general_preferences'.tr),
          _buildCard([
            _buildLanguageTile(context),
            const Divider(indent: 56, height: 1),
            _buildThemeTile(context),
          ]),

          const SizedBox(height: AppDimensions.paddingLG),

          // --- Prayer Settings ---
          _buildHeader('prayer_settings'.tr),
          _buildCard([
            _buildCalculationMethodTile(context),
            const Divider(indent: 56, height: 1),
            _buildMadhabTile(context),
          ]),

          const SizedBox(height: AppDimensions.paddingLG),

          // --- Prayer & Location ---
          _buildHeader('prayer_location'.tr),
          _buildCard([
            _buildLocationTile(context),
            const Divider(indent: 56, height: 1),
            _buildNotificationTile(context),
          ]),

          const SizedBox(height: AppDimensions.paddingLG),

          // --- App Information ---
          _buildHeader('app_info'.tr),
          _buildCard([
            _buildTile(
              context,
              icon: Icons.info_outline,
              title: 'about'.tr,
              onTap: () => controller.showAboutDialog(),
            ),
            const Divider(indent: 56, height: 1),
            _buildTile(
              context,
              icon: Icons.star_border_rounded,
              title: 'rate_app'.tr,
              onTap: () => controller.openRateApp(),
            ),
            const Divider(indent: 56, height: 1),
            _buildTile(
              context,
              icon: Icons.share_outlined,
              title: 'share_app'.tr,
              onTap: () => controller.shareApp(),
            ),
            const Divider(indent: 56, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  '${'version'.tr}: 1.0.0',
                  style: AppFonts.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ]),

          const SizedBox(height: AppDimensions.paddingLG),

          // --- Account Actions ---
          _buildHeader('account'.tr),
          _buildCard([
            _buildTile(
              context,
              icon: Icons.logout_rounded,
              title: 'logout'.tr,
              titleColor: AppColors.error,
              iconColor: AppColors.error,
              onTap: () => _handleLogout(),
            ),
            const Divider(indent: 56, height: 1),
            _buildTile(
              context,
              icon: Icons.delete_forever_rounded,
              title: 'delete_account'.tr,
              titleColor: AppColors.error,
              iconColor: AppColors.error,
              onTap: () => controller.deleteAccount(),
            ),
          ]),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppDimensions.paddingSM,
        bottom: AppDimensions.paddingSM,
      ),
      child: Text(
        title.toUpperCase(),
        style: AppFonts.labelMedium.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTile(
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
              style: AppFonts.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          : null,
      trailing:
          trailing ??
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.secondary,
            size: 20,
          ),
      onTap: onTap,
    );
  }

  Widget _buildLanguageTile(BuildContext context) {
    return Obx(() {
      final current = Get.find<LocalizationService>().currentLanguage.value;
      return _buildTile(
        context,
        icon: Icons.translate_rounded,
        title: 'language'.tr,
        subtitle: current.name,
        onTap: () => _showLanguagePicker(context),
      );
    });
  }

  Widget _buildThemeTile(BuildContext context) {
    return Obx(() {
      final current = Get.find<ThemeService>().currentThemeMode.value;
      String themeLabel;
      IconData themeIcon;
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

      return _buildTile(
        context,
        icon: themeIcon,
        title: 'theme'.tr,
        subtitle: themeLabel,
        onTap: () => _showThemePicker(context),
      );
    });
  }

  Widget _buildLocationTile(BuildContext context) {
    return Obx(() {
      final isLoading = controller.isLocationLoading;
      final label = controller.locationDisplayLabel;
      return _buildTile(
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

  Widget _buildNotificationTile(BuildContext context) {
    return _buildTile(
      context,
      icon: Icons.notifications_active_rounded,
      title: 'notifications'.tr,
      subtitle: controller.notificationsEnabled.value
          ? 'enabled'.tr
          : 'disabled'.tr,
      onTap: () => _navigateToNotifications(context),
    );
  }

  Widget _buildCalculationMethodTile(BuildContext context) {
    return Obx(() {
      final method = controller.currentCalculationMethod;
      return _buildTile(
        context,
        icon: Icons.access_time_filled_rounded,
        title: 'calculation_method'.tr,
        subtitle: _getCalculationMethodName(method),
        onTap: () => _showCalculationMethodPicker(context),
      );
    });
  }

  Widget _buildMadhabTile(BuildContext context) {
    return Obx(() {
      final madhab = controller.currentMadhab;
      return _buildTile(
        context,
        icon: Icons.mosque_rounded,
        title: 'madhab'.tr,
        subtitle: _getMadhabName(madhab),
        onTap: () => _showMadhabPicker(context),
      );
    });
  }

  String _getCalculationMethodName(adhan.CalculationMethod method) {
    // Basic mapping, can be improved with localization keys
    switch (method) {
      case adhan.CalculationMethod.muslim_world_league:
        return 'Muslim World League';
      case adhan.CalculationMethod.egyptian:
        return 'Egyptian General Authority';
      case adhan.CalculationMethod.karachi:
        return 'University of Islamic Sciences, Karachi';
      case adhan.CalculationMethod.umm_al_qura:
        return 'Umm Al-Qura University, Makkah';
      case adhan.CalculationMethod.dubai:
        return 'Dubai';
      case adhan.CalculationMethod.qatar:
        return 'Qatar';
      case adhan.CalculationMethod.kuwait:
        return 'Kuwait';
      case adhan.CalculationMethod.moon_sighting_committee:
        return 'Moon Sighting Committee';
      case adhan.CalculationMethod.singapore:
        return 'Singapore';
      case adhan.CalculationMethod.turkey:
        return 'Turkey';
      case adhan.CalculationMethod.tehran:
        return 'Tehran';
      case adhan.CalculationMethod.north_america:
        return 'ISNA (North America)';
      default:
        return method.name;
    }
  }

  String _getMadhabName(adhan.Madhab madhab) {
    switch (madhab) {
      case adhan.Madhab.shafi:
        return 'Shafi (Standard)';
      case adhan.Madhab.hanafi:
        return 'Hanafi';
    }
  }

  void _showCalculationMethodPicker(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(AppDimensions.paddingLG),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        constraints: BoxConstraints(maxHeight: Get.height * 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'select_calculation_method'.tr,
              style: AppFonts.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children:
                    [
                          adhan.CalculationMethod.muslim_world_league,
                          adhan.CalculationMethod.egyptian,
                          adhan.CalculationMethod.karachi,
                          adhan.CalculationMethod.umm_al_qura,
                          adhan.CalculationMethod.dubai,
                          adhan.CalculationMethod.kuwait,
                          adhan.CalculationMethod.qatar,
                          adhan.CalculationMethod.singapore,
                          adhan.CalculationMethod.turkey,
                          adhan.CalculationMethod.tehran,
                          adhan.CalculationMethod.north_america,
                        ]
                        .map<Widget>(
                          (method) => ListTile(
                            title: Text(_getCalculationMethodName(method)),
                            trailing:
                                controller.currentCalculationMethod == method
                                ? const Icon(
                                    Icons.check_circle,
                                    color: AppColors.primary,
                                  )
                                : null,
                            onTap: () {
                              controller.updateCalculationMethod(method);
                              Get.back();
                            },
                          ),
                        )
                        .toList(),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showMadhabPicker(BuildContext context) {
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
              'select_madhab'.tr,
              style: AppFonts.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...adhan.Madhab.values.map(
              (m) => ListTile(
                title: Text(_getMadhabName(m)),
                trailing: controller.currentMadhab == m
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () {
                  controller.updateMadhab(m);
                  Get.back();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(AppDimensions.paddingLG),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'select_language'.tr,
              style: AppFonts.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...AppLanguage.values.map(
              (lang) => ListTile(
                title: Text(lang.name),
                trailing:
                    Get.find<LocalizationService>().currentLanguage.value ==
                        lang
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () {
                  controller.changeLanguage(lang);
                  Get.back();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemePicker(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(AppDimensions.paddingLG),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'select_theme'.tr,
              style: AppFonts.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildThemeOption('theme_system'.tr, AppThemeMode.system),
            _buildThemeOption('theme_light'.tr, AppThemeMode.light),
            _buildThemeOption('theme_dark'.tr, AppThemeMode.dark),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(String title, AppThemeMode mode) {
    return ListTile(
      title: Text(title),
      trailing: Get.find<ThemeService>().currentThemeMode.value == mode
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : null,
      onTap: () {
        controller.changeTheme(mode);
        Get.back();
      },
    );
  }

  void _navigateToNotifications(BuildContext context) {
    Get.to(() => _NotificationSettingsView(controller: controller));
  }

  Future<void> _handleLogout() async {
    final confirm = await AppDialogs.confirm(
      title: 'logout'.tr,
      message: 'logout_confirm_message'.tr,
      confirmText: 'logout'.tr,
      cancelText: 'cancel'.tr,
      isDestructive: true,
    );

    if (confirm) {
      AppDialogs.showLoading(message: 'logging_out'.tr);
      await controller.logout();
      AppDialogs.hideLoading();
    }
  }
}

class _NotificationSettingsView extends StatelessWidget {
  final SettingsController controller;
  const _NotificationSettingsView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('notifications'.tr),
        elevation: 0,
        backgroundColor: AppColors.surface,
      ),
      body: Obx(
        () => ListView(
          padding: const EdgeInsets.all(AppDimensions.paddingMD),
          children: [
            _buildCard([
              SwitchListTile(
                title: Text(
                  'prayer_notifications'.tr,
                  style: AppFonts.titleMedium,
                ),
                subtitle: Text('prayer_notifications_desc'.tr),
                value: controller.notificationsEnabled.value,
                onChanged: (v) => controller.setNotificationsEnabled(v),
                activeThumbColor: AppColors.primary,
              ),
            ]),

            if (controller.notificationsEnabled.value) ...[
              const SizedBox(height: 24),
              _buildHeader('notification_types'.tr.toUpperCase()),
              _buildCard([
                _buildSwitchTile(
                  title: 'adhan_notification'.tr,
                  subtitle: 'adhan_notification_desc'.tr,
                  value: controller.adhanEnabled.value,
                  onChanged: (v) => controller.setAdhanEnabled(v),
                ),
                const Divider(indent: 16),
                _buildSwitchTile(
                  title: 'reminder_notification'.tr,
                  subtitle: 'reminder_notification_desc'.tr,
                  value: controller.reminderEnabled.value,
                  onChanged: (v) => controller.setReminderEnabled(v),
                ),
                const Divider(indent: 16),
                _buildSwitchTile(
                  title: 'family_notification_label'.tr,
                  subtitle: 'family_notification_desc'.tr,
                  value: controller.familyNotificationsEnabled.value,
                  onChanged: (v) => controller.setFamilyNotificationsEnabled(v),
                ),
              ]),

              const SizedBox(height: 24),
              _buildHeader('sound_vibration'.tr.toUpperCase()),
              _buildCard([_buildSoundModeSelector()]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title,
        style: AppFonts.labelMedium.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: AppFonts.bodyLarge),
      subtitle: Text(subtitle, style: AppFonts.bodySmall),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
    );
  }

  Widget _buildSoundModeSelector() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: NotificationSoundMode.values.map((mode) {
          final isSelected = controller.notificationSoundMode.value == mode;
          IconData icon;
          String label;
          switch (mode) {
            case NotificationSoundMode.adhan:
              icon = Icons.volume_up_rounded;
              label = 'sound_adhan'.tr;
              break;
            case NotificationSoundMode.vibrate:
              icon = Icons.vibration_rounded;
              label = 'sound_vibrate'.tr;
              break;
            case NotificationSoundMode.silent:
              icon = Icons.notifications_off_rounded;
              label = 'sound_silent'.tr;
              break;
          }

          return Expanded(
            child: GestureDetector(
              onTap: () => controller.setNotificationSoundMode(mode),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.grey.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      icon,
                      color: isSelected ? AppColors.primary : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: AppFonts.labelSmall.copyWith(
                        color: isSelected ? AppColors.primary : Colors.grey,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
