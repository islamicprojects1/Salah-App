import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/features/settings/controller/settings_controller.dart';

/// Sound/vibration mode selector for notification settings
class SettingsSoundSelector extends StatelessWidget {
  const SettingsSoundSelector({
    super.key,
    required this.controller,
  });

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
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
}
