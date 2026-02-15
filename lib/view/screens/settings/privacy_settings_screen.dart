import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/controller/settings/settings_controller.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/data/models/user_privacy_settings.dart';

class PrivacySettingsScreen extends GetView<SettingsController> {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('privacy_settings'.tr),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: Obx(() {
        final user = controller.userModel.value;
        final settings = user?.privacySettings ?? UserPrivacySettings.defaultPublic();
        
        // Only show loading if we really have no data and no defaults to show? 
        // Actually defaults are fine to show while loading real data if we want.
        // But let's stick to existing logic: if userModel is null, maybe show loading?
        // But userModel might be null if not logged in?
        // Let's safe guard.
        
        if (user == null && controller.currentUser.value != null) {
             // Loading profile...
             return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(AppDimensions.paddingMD),
          children: [
            _buildHeader('visibility'.tr),
            _buildCard(context, [
              _buildRadioTile(
                title: 'public'.tr,
                subtitle: 'public_desc'.tr,
                value: PrivacyMode.public,
                groupValue: settings.mode,
                onChanged: (val) =>
                    controller.updatePrivacy(settings.copyWith(mode: val)),
              ),
              Divider(indent: 16, height: 1, color: AppColors.divider),
              _buildRadioTile(
                title: 'family_only'.tr,
                subtitle: 'family_only_desc'.tr,
                value: PrivacyMode.private,
                groupValue: settings.mode,
                onChanged: (val) =>
                    controller.updatePrivacy(settings.copyWith(mode: val)),
              ),
              Divider(indent: 16, height: 1, color: AppColors.divider),
              _buildRadioTile(
                title: 'anonymous'.tr,
                subtitle: 'anonymous_desc'.tr,
                value: PrivacyMode.anonymous,
                groupValue: settings.mode,
                onChanged: (val) =>
                    controller.updatePrivacy(settings.copyWith(mode: val)),
              ),
            ]),

            const SizedBox(height: 24),
            _buildHeader('profile_details'.tr),
            _buildCard(context, [
              _buildSwitchTile(
                title: 'show_name'.tr,
                value: settings.showName,
                onChanged: (val) =>
                    controller.updatePrivacy(settings.copyWith(showName: val)),
              ),
              Divider(indent: 16, height: 1, color: AppColors.divider),
              _buildSwitchTile(
                title: 'show_photo'.tr,
                value: settings.showPhoto,
                onChanged: (val) =>
                    controller.updatePrivacy(settings.copyWith(showPhoto: val)),
              ),
              Divider(indent: 16, height: 1, color: AppColors.divider),
              _buildSwitchTile(
                title: 'show_streak'.tr,
                value: settings.showStreak,
                onChanged: (val) => controller.updatePrivacy(
                  settings.copyWith(showStreak: val),
                ),
              ),
            ]),

            const SizedBox(height: 24),
            _buildHeader('community'.tr),
            _buildCard(context, [
              _buildSwitchTile(
                title: 'show_in_leaderboard'.tr,
                subtitle: 'show_in_leaderboard_desc'.tr,
                value: settings.showInLeaderboard,
                onChanged: (val) => controller.updatePrivacy(
                  settings.copyWith(showInLeaderboard: val),
                ),
              ),
            ]),
          ],
        );
      }),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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

  Widget _buildRadioTile({
    required String title,
    required String subtitle,
    required PrivacyMode value,
    required PrivacyMode groupValue,
    required Function(PrivacyMode) onChanged,
  }) {
    return RadioListTile<PrivacyMode>(
      title: Text(title, style: AppFonts.bodyLarge),
      subtitle: Text(subtitle, style: AppFonts.bodySmall),
      value: value,
      groupValue: groupValue,
      onChanged: (val) {
        if (val != null) onChanged(val);
      },
      activeColor: AppColors.primary,
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: AppFonts.bodyLarge),
      subtitle: subtitle != null
          ? Text(subtitle, style: AppFonts.bodySmall)
          : null,
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.primary,
    );
  }
}
