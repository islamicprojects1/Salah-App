import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/controller/profile_controller.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/view/widgets/app_button.dart';
import 'package:salah/view/widgets/app_loading.dart';
import 'package:salah/view/widgets/app_text_field.dart';

class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('profile'.tr),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar Section
            Center(
              child: Stack(
                children: [
                  Obx(() {
                    final imagePath = controller.userImage.value;
                    final loading = controller.isLoading.value;
                    final progress = controller.uploadProgress.value;
                    
                    ImageProvider? imageProvider;
                    if (imagePath.isNotEmpty) {
                      if (imagePath.startsWith('http')) {
                        imageProvider = NetworkImage(imagePath);
                      } else {
                        imageProvider = FileImage(File(imagePath));
                      }
                    }

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          backgroundImage: imageProvider,
                          child: imagePath.isEmpty && !loading
                              ? Icon(Icons.person, size: 60, color: AppColors.primary)
                              : null,
                        ),
                        if (loading && progress > 0)
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 4,
                              color: AppColors.primary,
                              backgroundColor: Colors.white24,
                            ),
                          ),
                        if (loading && progress == 0)
                          const AppLoading(), // Or just a generic spinner if AppLoading is too big
                      ],
                    );
                  }),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => controller.pickImage(),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primary,
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Form Fields
            AppTextField(
              controller: controller.nameController,
              label: 'name'.tr,
              prefixIcon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: controller.emailController,
              label: 'email'.tr,
              prefixIcon: Icons.email_outlined,
              readOnly: true, // Email usually not editable easily in Firebase without re-auth
            ),
            
            const SizedBox(height: 32),

            // Actions
            Obx(() => AppButton(
              text: 'update_profile'.tr,
              onPressed: () => controller.updateProfile(),
              isLoading: controller.isLoading.value,
              width: double.infinity,
            )),
            
            const SizedBox(height: 16),
            
            OutlinedButton.icon(
              onPressed: () => _showChangePasswordDialog(context),
              icon: const Icon(Icons.lock_outline),
              label: Text('change_password'.tr),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: AppColors.primary),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),

            const SizedBox(height: 48),
            
            // Groups Section Placeholder
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'my_groups'.tr,
                style: AppFonts.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.secondary.withValues(alpha: 0.2),
                    child: Icon(Icons.group, color: AppColors.secondary),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('family_group'.tr, style: AppFonts.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                      Text('3 members', style: AppFonts.bodySmall),
                    ],
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: Text('change_password'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: controller.newPasswordController,
              label: 'new_password'.tr,
              obscureText: true,
              prefixIcon: Icons.lock,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: controller.confirmPasswordController,
              label: 'confirm_password'.tr,
              obscureText: true,
              prefixIcon: Icons.lock_clock, // Using lock_clock as substitute for lock_check if not available
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          Obx(() => ElevatedButton(
            onPressed: controller.isLoading.value ? null : () => controller.changePassword(),
            child: Text('save'.tr),
          )),
        ],
      ),
    );
  }
}
