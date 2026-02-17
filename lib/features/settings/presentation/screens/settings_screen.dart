import 'package:flutter/material.dart';
import 'package:salah/core/helpers/image_helper.dart';
import 'package:get/get.dart';
import 'package:salah/core/di/injection_container.dart';
import 'package:adhan/adhan.dart' as adhan;
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/core/constants/storage_keys.dart';
import 'package:salah/core/widgets/app_dialogs.dart';
import 'package:salah/features/settings/controller/settings_controller.dart';
import 'package:salah/features/settings/data/services/localization_service.dart';
import 'package:salah/features/settings/data/services/theme_service.dart';
import 'package:salah/features/settings/presentation/screens/prayer_adjustment_screen.dart';
import 'package:salah/features/settings/presentation/screens/privacy_settings_screen.dart';

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
          // --- Prayer Identity ---
          _buildHeader('prayer_identity'.tr),
          _buildCard(context, [
            _buildLocationTile(context),
            Divider(indent: 56, height: 1, color: AppColors.divider),
            _buildCalculationMethodTile(context),
            Divider(indent: 56, height: 1, color: AppColors.divider),
            _buildMadhabTile(context),
            const Divider(indent: 16),
            _buildTile(
              context,
              icon: Icons.tune_rounded,
              title: 'adjust_prayer_times'.tr,
              onTap: () => Get.to(() => const PrayerAdjustmentScreen()),
            ),
          ]),

          const SizedBox(height: AppDimensions.paddingMD),
          _buildProfileHeader(context),
          const SizedBox(height: AppDimensions.paddingLG),

          // --- Personalization ---
          _buildHeader('personalization'.tr),
          _buildCard(context, [
            _buildLanguageTile(context),
            Divider(indent: 56, height: 1, color: AppColors.divider),
            _buildThemeTile(context),
          ]),

          const SizedBox(height: AppDimensions.paddingLG),

          // --- Integration & Sync ---
          _buildHeader('integration_sync'.tr),
          _buildCard(context, [
            _buildNotificationTile(context),
            Divider(indent: 56, height: 1, color: AppColors.divider),
            _buildTile(
              context,
              icon: Icons.calendar_today_rounded,
              title: 'google_calendar_sync'.tr,
              onTap: () => controller.syncWithGoogleCalendar(),
            ),
          ]),

          const SizedBox(height: AppDimensions.paddingLG),

          // --- Support & Feedback ---
          _buildHeader('support_feedback'.tr),
          _buildCard(context, [
            _buildTile(
              context,
              icon: Icons.info_outline,
              title: 'about'.tr,
              onTap: () => controller.showAboutDialog(),
            ),
            Divider(indent: 56, height: 1, color: AppColors.divider),
            _buildTile(
              context,
              icon: Icons.email_outlined,
              title: 'contact_us_email'.tr,
              onTap: () => controller.reportBug(),
            ),
            Divider(indent: 56, height: 1, color: AppColors.divider),
            _buildTile(
              context,
              icon: Icons.bug_report_outlined,
              title: 'report_bug'.tr,
              onTap: () => controller.reportBug(),
            ),
            Divider(indent: 56, height: 1, color: AppColors.divider),
            _buildTile(
              context,
              icon: Icons.lightbulb_outline_rounded,
              title: 'suggest_feature'.tr,
              onTap: () => controller.suggestFeature(),
            ),
            Divider(indent: 56, height: 1, color: AppColors.divider),
            _buildTile(
              context,
              icon: Icons.star_border_rounded,
              title: 'rate_app'.tr,
              onTap: () => controller.openRateApp(),
            ),
            Divider(indent: 56, height: 1, color: Theme.of(context).dividerColor),
            _buildTile(
              context,
              icon: Icons.share_outlined,
              title: 'share_app'.tr,
              onTap: () => controller.shareApp(),
            ),
          ]),

          const SizedBox(height: AppDimensions.paddingLG),

          // --- Support & Feedback ---
          _buildHeader('sound_vibration'.tr),
          _buildCard(context, [_buildSoundModeSelector()]),

          const SizedBox(height: AppDimensions.paddingLG),

          // --- Account Actions ---
          _buildHeader('account'.tr),
          _buildCard(context, [
            _buildTile(
              context,
              icon: Icons.privacy_tip_outlined,
              title: 'privacy_settings'.tr,
              onTap: () => Get.to(() => const PrivacySettingsScreen()),
            ),
            Divider(indent: 56, height: 1, color: AppColors.divider),
            _buildTile(
              context,
              icon: Icons.file_download_outlined,
              title: 'export_data'.tr,
              onTap: () => controller.exportPrayerData(),
            ),
            Divider(indent: 56, height: 1, color: AppColors.divider),
            _buildTile(
              context,
              icon: Icons.logout_rounded,
              title: 'logout'.tr,
              titleColor: AppColors.error,
              iconColor: AppColors.error,
              onTap: () => _handleLogout(),
            ),
            Divider(indent: 56, height: 1, color: Theme.of(context).dividerColor),
            _buildTile(
              context,
              icon: Icons.delete_forever_rounded,
              title: 'delete_account'.tr,
              titleColor: AppColors.error,
              iconColor: AppColors.error,
              onTap: () => controller.deleteAccount(),
            ),
          ]),

          const SizedBox(height: 16),
          Center(
            child: Text(
              '${'version'.tr}: 1.0.0',
              style: AppFonts.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
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

  Widget _buildCard(BuildContext context, List<Widget> children) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.03),
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
      final current = sl<LocalizationService>().currentLanguage.value;
      return _buildTile(
        context,
        icon: Icons.translate_rounded,
        title: 'language'.tr,
        subtitle: current.name,
        onTap: () {
          _showLanguagePicker(context);
        },
      );
    });
  }

  Widget _buildThemeTile(BuildContext context) {
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
    return Obx(() {
      return _buildTile(
        context,
        icon: Icons.notifications_active_rounded,
        title: 'notifications'.tr,
        subtitle: controller.notificationsEnabled.value
            ? 'enabled'.tr
            : 'disabled'.tr,
        onTap: () => _navigateToNotifications(context),
      );
    });
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
        return 'muslim_world_league'.tr;
      case adhan.CalculationMethod.egyptian:
        return 'egyptian'.tr;
      case adhan.CalculationMethod.karachi:
        return 'karachi'.tr;
      case adhan.CalculationMethod.umm_al_qura:
        return 'umm_al_qura'.tr;
      case adhan.CalculationMethod.dubai:
        return 'dubai'.tr;
      case adhan.CalculationMethod.qatar:
        return 'qatar'.tr;
      case adhan.CalculationMethod.kuwait:
        return 'kuwait'.tr;
      case adhan.CalculationMethod.moon_sighting_committee:
        return 'moon_sighting_committee'.tr;
      case adhan.CalculationMethod.singapore:
        return 'singapore'.tr;
      case adhan.CalculationMethod.turkey:
        return 'turkey'.tr;
      case adhan.CalculationMethod.tehran:
        return 'tehran'.tr;
      case adhan.CalculationMethod.north_america:
        return 'north_america'.tr;
      default:
        return method.name;
    }
  }

  String _getMadhabName(adhan.Madhab madhab) {
    switch (madhab) {
      case adhan.Madhab.shafi:
        return 'shafi'.tr;
      case adhan.Madhab.hanafi:
        return 'hanafi'.tr;
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
      trailing: sl<ThemeService>().currentThemeMode.value == mode
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

  Widget _buildSoundModeSelector() {
    return Obx(
      () => Padding(
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
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Obx(() {
      final user = controller.userModel.value;
      final authUser = controller.currentUser.value;

      if (user == null && authUser == null) return const SizedBox();

      final displayName = user?.name ?? authUser?.displayName ?? 'guest'.tr;
      final photoUrl = user?.photoUrl ?? authUser?.photoURL;
      final email = user?.email ?? authUser?.email;

      final colorScheme = Theme.of(context).colorScheme;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                GestureDetector(
                  onTap: controller.updateProfilePhoto,
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage: ImageHelper.getImageProvider(photoUrl),
                    child: photoUrl == null
                        ? const Icon(
                            Icons.person,
                            size: 32,
                            color: AppColors.primary,
                          )
                        : null,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: controller.updateProfilePhoto,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: 14,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: AppFonts.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () =>
                            _showEditNameDialog(context, displayName),
                        splashRadius: 20,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                      ),
                    ],
                  ),
                  if (email != null)
                    Text(
                      email,
                      style: AppFonts.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  void _showEditNameDialog(BuildContext context, String? currentName) {
    final nameController = TextEditingController(text: currentName);
    Get.dialog(
      AlertDialog(
        title: Text('edit_profile'.tr),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'name'.tr,
            hintText: 'enter_your_name'.tr,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                controller.updateDisplayName(nameController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text('save'.tr),
          ),
        ],
      ),
    );
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
            _buildCard(context, [
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
              _buildCard(context, [
                _buildSwitchTile(
                  title: 'adhan_notification'.tr,
                  subtitle: 'adhan_notification_desc'.tr,
                  value: controller.adhanEnabled.value,
                  onChanged: (v) => controller.setAdhanEnabled(v),
                ),
                if (controller.adhanEnabled.value) ...[
                  _buildPrayerToggle(
                    title: 'fajr'.tr,
                    value: controller.fajrNotif.value,
                    onChanged: (v) => controller.setPrayerNotif(
                      StorageKeys.fajrNotification,
                      v,
                    ),
                  ),
                  _buildPrayerToggle(
                    title: 'dhuhr'.tr,
                    value: controller.dhuhrNotif.value,
                    onChanged: (v) => controller.setPrayerNotif(
                      StorageKeys.dhuhrNotification,
                      v,
                    ),
                  ),
                  _buildPrayerToggle(
                    title: 'asr'.tr,
                    value: controller.asrNotif.value,
                    onChanged: (v) => controller.setPrayerNotif(
                      StorageKeys.asrNotification,
                      v,
                    ),
                  ),
                  _buildPrayerToggle(
                    title: 'maghrib'.tr,
                    value: controller.maghribNotif.value,
                    onChanged: (v) => controller.setPrayerNotif(
                      StorageKeys.maghribNotification,
                      v,
                    ),
                  ),
                  _buildPrayerToggle(
                    title: 'isha'.tr,
                    value: controller.ishaNotif.value,
                    onChanged: (v) => controller.setPrayerNotif(
                      StorageKeys.ishaNotification,
                      v,
                    ),
                  ),
                ],
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

  Widget _buildCard(BuildContext context, List<Widget> children) {
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
      activeThumbColor: AppColors.primary,
    );
  }

  Widget _buildPrayerToggle({
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 32),
      child: SwitchListTile(
        title: Text(title, style: AppFonts.bodyMedium),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
        dense: true,
      ),
    );
  }
}
