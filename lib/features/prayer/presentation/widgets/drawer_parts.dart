import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/core/widgets/app_dialogs.dart';
import 'package:salah/core/routes/app_routes.dart';
import 'package:salah/features/auth/data/services/auth_service.dart';
import 'package:salah/features/settings/controller/settings_controller.dart';

Widget buildDrawerHeader(AuthService authService) {
  return Container(
    padding: const EdgeInsets.all(24),
    child: Row(
      children: [
        Obx(() {
          final photoUrl = authService.userPhotoUrl;
          return InkWell(
            onTap: () {
              Get.back();
              Get.toNamed(AppRoutes.profile);
            },
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage:
                    photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null
                    ? const Icon(
                        Icons.person,
                        color: AppColors.primary,
                        size: 35,
                      )
                    : null,
              ),
            ),
          );
        }),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(
                () => Text(
                  authService.userName ?? 'app_name'.tr,
                  style: AppFonts.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Obx(
                () => Text(
                  authService.userEmail ?? '',
                  style: AppFonts.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget buildDrawerSectionHeader(String title) {
  return Padding(
    padding: const EdgeInsets.only(left: 12, top: 12, bottom: 8),
    child: Text(
      title.toUpperCase(),
      style: AppFonts.labelSmall.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    ),
  );
}

Widget buildDrawerMenuItem({
  required IconData icon,
  required String title,
  String? subtitle,
  required VoidCallback onTap,
}) {
  return ListTile(
    onTap: onTap,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    leading: Icon(icon, color: AppColors.textPrimary, size: 22),
    title: Text(
      title,
      style: AppFonts.bodyMedium.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w500,
      ),
    ),
    subtitle: subtitle != null
        ? Text(
            subtitle,
            style: AppFonts.labelSmall.copyWith(color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
        : null,
    trailing: Icon(
      Icons.chevron_right_rounded,
      size: 18,
      color: AppColors.textSecondary,
    ),
    visualDensity: VisualDensity.compact,
  );
}

Widget buildDrawerLogoutButton(
  SettingsController settingsCtrl,
  AuthService authService,
) {
  return ListTile(
    onTap: () async {
      Get.back();
      final confirm = await AppDialogs.confirm(
        title: 'logout'.tr,
        message: 'logout_confirm_message'.tr,
        confirmText: 'logout'.tr,
        cancelText: 'cancel'.tr,
        isDestructive: true,
      );
      if (!confirm) return;
      try {
        await settingsCtrl.logout();
      } catch (_) {
        await authService.signOut();
        Get.offAllNamed(AppRoutes.login);
      }
    },
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: AppColors.error.withValues(alpha: 0.1)),
    ),
    leading: const Icon(Icons.logout_rounded, color: AppColors.error, size: 22),
    title: Text(
      'logout'.tr,
      style: AppFonts.bodyMedium.copyWith(
        color: AppColors.error,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

Widget buildDrawerFooter() {
  return Padding(
    padding: const EdgeInsets.all(20),
    child: Center(
      child: Text(
        'about_app_salah'.tr,
        style: AppFonts.labelSmall.copyWith(color: AppColors.textSecondary),
      ),
    ),
  );
}
