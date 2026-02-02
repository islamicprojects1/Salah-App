import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controller/settings_controller.dart';
import '../../../core/services/theme_service.dart';
import '../../../core/services/localization_service.dart';
import '../../../core/theme/app_colors.dart';

/// Settings screen for app preferences
/// 
/// Allows users to change language and theme
class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('settings'.tr),
      ),
      body: GetBuilder<SettingsController>(
        builder: (controller) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Language Section
            _buildSectionTitle(context, 'language'.tr),
            const SizedBox(height: 8),
            _buildLanguageSelector(context),
            const SizedBox(height: 24),
            
            // Theme Section
            _buildSectionTitle(context, 'theme'.tr),
            const SizedBox(height: 8),
            _buildThemeSelector(context),
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
          ],
        ),
      ),
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

  Widget _buildLanguageSelector(BuildContext context) {
    return Card(
      child: Column(
        children: AppLanguage.values.map((language) {
          final isSelected = controller.currentLanguage == language;
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

  Widget _buildThemeSelector(BuildContext context) {
    return Card(
      child: Column(
        children: [
          _buildThemeOption(
            context,
            'theme_system'.tr,
            Icons.brightness_auto,
            AppThemeMode.system,
          ),
          _buildThemeOption(
            context,
            'theme_light'.tr,
            Icons.light_mode,
            AppThemeMode.light,
          ),
          _buildThemeOption(
            context,
            'theme_dark'.tr,
            Icons.dark_mode,
            AppThemeMode.dark,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    String title,
    IconData icon,
    AppThemeMode mode,
  ) {
    final isSelected = controller.currentThemeMode == mode;
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
          icon,
          color: isSelected ? AppColors.primary : Colors.grey,
        ),
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
          SwitchListTile(
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
            value: true, // TODO: Connect to actual notification state
            onChanged: (value) {
              // TODO: Implement notification toggle
            },
          ),
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
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to sound selection
            },
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
            onTap: () {
              // TODO: Navigate to about screen
            },
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
            onTap: () {
              // TODO: Open app store for rating
            },
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
            onTap: () {
              // TODO: Share app
            },
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
}
