import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/constants/storage_keys.dart';
import 'package:salah/core/helpers/prayer_names.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/core/services/storage_service.dart';
import 'package:salah/features/settings/controller/settings_controller.dart';

/// Notification settings screen (prayer alerts, approaching, reminders, etc.)
class NotificationSettingsView extends StatelessWidget {
  const NotificationSettingsView({super.key, required this.controller});

  final SettingsController controller;

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
                  title: 'approaching_alert'.tr,
                  subtitle: 'approaching_alert_desc'.tr,
                  value: controller.approachingAlertEnabled.value,
                  onChanged: (v) => controller.setApproachingAlertEnabled(v),
                ),
                if (controller.approachingAlertEnabled.value) ...[
                  _buildApproachingMinutesSelector(context),
                  _buildApproachingSoundPreview(context),
                ],
                const Divider(indent: 16),
                _buildSwitchTile(
                  title: 'takbeer_at_prayer'.tr,
                  subtitle: 'takbeer_at_prayer_desc'.tr,
                  value: controller.takbeerAtPrayerEnabled.value,
                  onChanged: (v) => controller.setTakbeerAtPrayerEnabled(v),
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

  Widget _buildApproachingMinutesSelector(BuildContext context) {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.only(left: 32, top: 8, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'approaching_minutes'.tr,
              style: AppFonts.bodyMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: StorageService.approachingMinutesOptions.map((m) {
                final selected = controller.approachingAlertMinutes.value == m;
                return ChoiceChip(
                  label: Text('$m'),
                  selected: selected,
                  onSelected: (_) => controller.setApproachingAlertMinutes(m),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApproachingSoundPreview(BuildContext context) {
    const prayers = [
      PrayerName.fajr,
      PrayerName.dhuhr,
      PrayerName.asr,
      PrayerName.maghrib,
      PrayerName.isha,
    ];
    return Padding(
      padding: const EdgeInsets.only(left: 32, top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('approaching_sound_preview'.tr, style: AppFonts.bodyMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in prayers)
                ChoiceChip(
                  selected: false,
                  avatar: Icon(Icons.volume_up_rounded, size: 18, color: AppColors.primary),
                  label: Text(PrayerNames.displayName(p)),
                  onSelected: (_) => controller.playApproachPreview(p),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
