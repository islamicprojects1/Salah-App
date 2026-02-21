import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/core/widgets/app_dialogs.dart';
import 'package:salah/features/settings/controller/settings_controller.dart';
import 'package:salah/features/settings/presentation/screens/prayer_adjustment_screen.dart';
import 'package:salah/features/settings/presentation/screens/privacy_settings_screen.dart';
import 'package:salah/features/settings/presentation/widgets/notification_settings_view.dart';
import 'package:salah/features/settings/presentation/widgets/settings_pickers.dart';
import 'package:salah/features/settings/presentation/widgets/settings_profile_section.dart';
import 'package:salah/features/settings/presentation/widgets/settings_sound_selector.dart';
import 'package:salah/features/settings/presentation/widgets/settings_tiles.dart';

/// Settings screen for app preferences
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
          _buildHeader('prayer_identity'.tr),
          _buildCard(context, [
            buildLocationTile(context, controller),
            const Divider(indent: 16),
            _buildTile(
              context,
              icon: Icons.tune_rounded,
              title: 'adjust_prayer_times'.tr,
              onTap: () => Get.to(() => const PrayerAdjustmentScreen()),
            ),
          ]),
          const SizedBox(height: AppDimensions.paddingMD),
          SettingsProfileSection(controller: controller),
          const SizedBox(height: AppDimensions.paddingLG),
          _buildHeader('personalization'.tr),
          _buildCard(context, [
            buildLanguageTile(context, controller),
            Divider(indent: 56, height: 1, color: AppColors.divider),
            buildThemeTile(context, controller),
          ]),
          const SizedBox(height: AppDimensions.paddingLG),
          _buildHeader('integration_sync'.tr),
          _buildCard(context, [
            buildNotificationTile(
              context,
              controller,
              onTap: () => _navigateToNotifications(context),
            ),
            Divider(indent: 56, height: 1, color: AppColors.divider),
            _buildTile(
              context,
              icon: Icons.calendar_today_rounded,
              title: 'google_calendar_sync'.tr,
              onTap: () => controller.syncWithGoogleCalendar(),
            ),
          ]),
          const SizedBox(height: AppDimensions.paddingLG),
          _buildHeader('support_feedback'.tr),
          _buildCard(context, _buildSupportTiles(context)),
          const SizedBox(height: AppDimensions.paddingLG),
          _buildHeader('sound_vibration'.tr),
          _buildCard(context, [SettingsSoundSelector(controller: controller)]),
          const SizedBox(height: AppDimensions.paddingLG),
          _buildHeader('account'.tr),
          _buildCard(context, _buildAccountTiles(context)),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '${'version'.tr}: 1.0.0',
              style: AppFonts.labelSmall.copyWith(color: AppColors.textSecondary),
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
  }) =>
      buildSettingsTile(
        context,
        icon: icon,
        title: title,
        subtitle: subtitle,
        iconColor: iconColor,
        titleColor: titleColor,
        onTap: onTap,
        trailing: trailing,
      );

  List<Widget> _buildSupportTiles(BuildContext context) {
    return [
      _buildTile(context, icon: Icons.info_outline, title: 'about'.tr,
          onTap: () => controller.showAboutDialog()),
      Divider(indent: 56, height: 1, color: AppColors.divider),
      _buildTile(context, icon: Icons.email_outlined, title: 'contact_us_email'.tr,
          onTap: () => controller.reportBug()),
      Divider(indent: 56, height: 1, color: AppColors.divider),
      _buildTile(context, icon: Icons.bug_report_outlined, title: 'report_bug'.tr,
          onTap: () => controller.reportBug()),
      Divider(indent: 56, height: 1, color: AppColors.divider),
      _buildTile(context, icon: Icons.lightbulb_outline_rounded, title: 'suggest_feature'.tr,
          onTap: () => controller.suggestFeature()),
      Divider(indent: 56, height: 1, color: AppColors.divider),
      _buildTile(context, icon: Icons.star_border_rounded, title: 'rate_app'.tr,
          onTap: () => controller.openRateApp()),
      Divider(indent: 56, height: 1, color: Theme.of(context).dividerColor),
      _buildTile(context, icon: Icons.share_outlined, title: 'share_app'.tr,
          onTap: () => controller.shareApp()),
    ];
  }

  List<Widget> _buildAccountTiles(BuildContext context) {
    return [
      _buildTile(
        context,
        icon: Icons.privacy_tip_outlined,
        title: 'privacy_settings'.tr,
        onTap: () => Get.to(() => const PrivacySettingsScreen()),
      ),
      Divider(indent: 56, height: 1, color: AppColors.divider),
      _buildTile(context, icon: Icons.file_download_outlined, title: 'export_data'.tr,
          onTap: () => controller.exportPrayerData()),
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
    ];
  }

  void _navigateToNotifications(BuildContext context) {
    Get.to(() => NotificationSettingsView(controller: controller));
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
