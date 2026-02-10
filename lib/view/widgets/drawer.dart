import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/controller/settings_controller.dart';
import 'package:salah/core/routes/app_routes.dart';
import 'package:salah/core/services/auth_service.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();

    return Drawer(
      backgroundColor: AppColors.background,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Obx(() {
                  final photoUrl = authService.userPhotoUrl;
                  return CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white24,
                    backgroundImage: photoUrl != null
                        ? NetworkImage(photoUrl)
                        : null,
                    child: photoUrl == null
                        ? const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 35,
                          )
                        : null,
                  );
                }),
                const SizedBox(height: 12),
                Obx(
                  () => Text(
                    authService.userName ?? 'app_name'.tr,
                    style: AppFonts.titleMedium.copyWith(color: Colors.white),
                  ),
                ),
                Obx(
                  () => Text(
                    authService.userEmail ?? '',
                    style: AppFonts.bodySmall.copyWith(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.person_outline, color: AppColors.textPrimary),
            title: Text(
              'profile'.tr,
              style: AppFonts.bodyMedium.copyWith(color: AppColors.textPrimary),
            ),
            onTap: () {
              Get.back(); // Close drawer
              Get.toNamed(AppRoutes.profile);
            },
          ),
          ListTile(
            leading: Icon(
              Icons.settings_outlined,
              color: AppColors.textPrimary,
            ),
            title: Text(
              'settings'.tr,
              style: AppFonts.bodyMedium.copyWith(color: AppColors.textPrimary),
            ),
            onTap: () {
              Get.back(); // Close drawer
              Get.toNamed(AppRoutes.settings);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.error),
            title: Text(
              'logout'.tr,
              style: AppFonts.bodyMedium.copyWith(color: AppColors.error),
            ),
            onTap: () async {
              Get.back(); // Close drawer
              try {
                final settingsCtrl = Get.find<SettingsController>();
                await settingsCtrl.logout();
              } catch (_) {
                await authService.signOut();
                Get.offAllNamed(AppRoutes.login);
              }
            },
          ),
        ],
      ),
    );
  }
}
