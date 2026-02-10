import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/controller/settings_controller.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/services/theme_service.dart';
import 'package:salah/core/services/localization_service.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/view/widgets/app_dialogs.dart';

/// Settings screen for app preferences
///
/// Allows users to change language and theme
class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('settings'.tr)),
      body: Obx(() {
        // Reactive to theme and language via services
        final themeMode = Get.find<ThemeService>().currentThemeMode.value;
        final language = Get.find<LocalizationService>().currentLanguage.value;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Language Section
            _buildSectionTitle(context, 'language'.tr),
            const SizedBox(height: 8),
            _buildLanguageSelector(context, language),
            const SizedBox(height: 24),

            // Location Section (prayer times depend on it)
            _buildSectionTitle(context, 'location_section'.tr),
            const SizedBox(height: 8),
            _buildLocationCard(context),
            const SizedBox(height: 24),

            // Theme Section
            _buildSectionTitle(context, 'theme'.tr),
            const SizedBox(height: 8),
            _buildThemeSelector(context, themeMode),
            const SizedBox(height: 24),

            // Notifications Section
            _buildSectionTitle(context, 'notifications'.tr),
            const SizedBox(height: 8),
            _buildNotificationsCard(context),
            const SizedBox(height: 24),

            // About Section
            _buildSectionTitle(context, 'about'.tr),
            const SizedBox(height: 8),
            _buildAboutCard(context),
            const SizedBox(height: 24),

            // Logout Section
            _buildLogoutButton(context),
            const SizedBox(height: 24),

            // Delete Account Section
            _buildDeleteAccountButton(context),
            const SizedBox(height: 40),
          ],
        );
      }),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(
    BuildContext context,
    AppLanguage currentLanguage,
  ) {
    return Card(
      child: Column(
        children: AppLanguage.values.map((language) {
          final isSelected = currentLanguage == language;
          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.language,
                color: isSelected ? AppColors.primary : Colors.grey,
              ),
            ),
            title: Text(language.name),
            trailing: isSelected
                ? const Icon(Icons.check_circle, color: AppColors.primary)
                : null,
            onTap: () => controller.changeLanguage(language),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildThemeSelector(
    BuildContext context,
    AppThemeMode currentThemeMode,
  ) {
    return Card(
      child: Column(
        children: [
          _buildThemeOption(
            context,
            'theme_system'.tr,
            Icons.brightness_auto,
            AppThemeMode.system,
            currentThemeMode,
          ),
          _buildThemeOption(
            context,
            'theme_light'.tr,
            Icons.light_mode,
            AppThemeMode.light,
            currentThemeMode,
          ),
          _buildThemeOption(
            context,
            'theme_dark'.tr,
            Icons.dark_mode,
            AppThemeMode.dark,
            currentThemeMode,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context) {
    return Obx(() {
      final isLoading = controller.isLocationLoading;
      final label = controller.locationDisplayLabel;
      final isDefault = controller.isUsingDefaultLocation;
      return Card(
        child: Column(
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.location_on_outlined,
                  color: AppColors.primary,
                ),
              ),
              title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
              subtitle: isDefault
                  ? Text(
                      'location_default_hint'.tr,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    )
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () => controller.refreshLocation(),
                  icon: isLoading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.refresh),
                  label: Text(
                    isLoading ? 'updating_location'.tr : 'update_location'.tr,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildThemeOption(
    BuildContext context,
    String title,
    IconData icon,
    AppThemeMode mode,
    AppThemeMode currentThemeMode,
  ) {
    final isSelected = currentThemeMode == mode;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: isSelected ? AppColors.primary : Colors.grey),
      ),
      title: Text(title),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : null,
      onTap: () => controller.changeTheme(mode),
    );
  }

  Widget _buildNotificationsCard(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // Master toggle
          Obx(
            () => SwitchListTile(
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.primary,
                ),
              ),
              title: Text('prayer_notifications'.tr),
              value: controller.notificationsEnabled.value,
              onChanged: (value) => controller.setNotificationsEnabled(value),
            ),
          ),

          // Per-type toggles (only visible when master is on)
          Obx(() {
            if (!controller.notificationsEnabled.value)
              return const SizedBox.shrink();
            return Column(
              children: [
                const Divider(height: 1),
                // Adhan notification
                SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.mosque_outlined,
                      color: Colors.teal,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'adhan_notification'.tr,
                    style: AppFonts.bodyMedium,
                  ),
                  subtitle: Text(
                    'adhan_notification_desc'.tr,
                    style: AppFonts.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  value: controller.adhanEnabled.value,
                  onChanged: (v) => controller.setAdhanEnabled(v),
                ),
                // Reminder notification
                SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.alarm_outlined,
                      color: Colors.amber,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'reminder_notification'.tr,
                    style: AppFonts.bodyMedium,
                  ),
                  subtitle: Text(
                    'reminder_notification_desc'.tr,
                    style: AppFonts.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  value: controller.reminderEnabled.value,
                  onChanged: (v) => controller.setReminderEnabled(v),
                ),
                // Family notification
                SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.family_restroom_outlined,
                      color: Colors.purple,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'family_notification_label'.tr,
                    style: AppFonts.bodyMedium,
                  ),
                  subtitle: Text(
                    'family_notification_desc'.tr,
                    style: AppFonts.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  value: controller.familyNotificationsEnabled.value,
                  onChanged: (v) => controller.setFamilyNotificationsEnabled(v),
                ),
              ],
            );
          }),

          // Sound mode selector
          Obx(
            () => Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.music_note_outlined,
                      color: Colors.grey,
                    ),
                  ),
                  title: Text('notification_sound'.tr),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: NotificationSoundMode.values.map((mode) {
                      final isSelected =
                          controller.notificationSoundMode.value == mode;
                      String label = '';
                      IconData icon = Icons.notifications;

                      switch (mode) {
                        case NotificationSoundMode.adhan:
                          label = 'sound_adhan'.tr;
                          icon = Icons.volume_up_rounded;
                          break;
                        case NotificationSoundMode.vibrate:
                          label = 'sound_vibrate'.tr;
                          icon = Icons.vibration_rounded;
                          break;
                        case NotificationSoundMode.silent:
                          label = 'sound_silent'.tr;
                          icon = Icons.notifications_off_rounded;
                          break;
                      }

                      return Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              controller.setNotificationSoundMode(mode),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.1)
                                  : AppColors.surface,
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
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.grey,
                                  size: 20,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  label,
                                  style: AppFonts.labelSmall.copyWith(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.grey,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.info_outline, color: Colors.grey),
            ),
            title: Text('about'.tr),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => controller.showAboutDialog(),
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.star_outline, color: Colors.grey),
            ),
            title: Text('rate_app'.tr),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => controller.openRateApp(),
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.share_outlined, color: Colors.grey),
            ),
            title: Text('share_app'.tr),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => controller.shareApp(),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${'version'.tr}: 1.0.0',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.logout, color: AppColors.error),
        ),
        title: Text(
          'logout'.tr,
          style: AppFonts.bodyLarge.copyWith(
            color: AppColors.error,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () async {
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
        },
      ),
    );
  }

  Widget _buildDeleteAccountButton(BuildContext context) {
    return Card(
      color: AppColors.error.withValues(alpha: 0.05),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.delete_forever, color: AppColors.error),
        ),
        title: Text(
          'delete_account'.tr,
          style: AppFonts.bodyLarge.copyWith(
            color: AppColors.error,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'delete_account_warning'.tr,
          style: AppFonts.bodySmall.copyWith(color: AppColors.error),
        ),
        onTap: () => controller.deleteAccount(),
      ),
    );
  }
}
