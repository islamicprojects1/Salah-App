import 'package:salah/core/localization/ar_translations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/routes/app_routes.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: AppColors.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.mosque, color: Colors.white, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Qurb',
                  style: AppFonts.titleLarge.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.settings_outlined, color: AppColors.textPrimary),
            title: Text(
              'Settings'.tr, // Assuming there's a key or just 'Settings' for now, better to use 'settings' key if exists
              style: AppFonts.bodyMedium.copyWith(color: AppColors.textPrimary),
            ),
            onTap: () {
              Get.back(); // Close drawer
              Get.toNamed(AppRoutes.settings);
            },
          ),
        ],
      ),
    );
  }
}
