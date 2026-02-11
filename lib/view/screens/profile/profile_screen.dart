import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/controller/profile_controller.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/view/widgets/app_text_field.dart';

class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        title: Text('profile'.tr, style: AppFonts.titleLarge.copyWith(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Stack(
        children: [
          // Background Gradient/Glow
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: const SizedBox.shrink(),
              ),
            ),
          ),
          
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Header with Avatar
                _buildHeader(context),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      
                      // Frosted Form Card
                      _buildFrostedCard(
                        child: Column(
                          children: [
                            _buildSectionTitle('info_personal'.tr),
                            const SizedBox(height: 16),
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
                              readOnly: true,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Action Buttons
                      _buildPremiumActions(context),
                      
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 120, bottom: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.8),
            AppColors.primaryDark,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer Glow
            Obx(() => AnimatedContainer(
              duration: const Duration(seconds: 1),
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: controller.isLoading.value 
                        ? AppColors.secondary.withValues(alpha: 0.4) 
                        : AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
            )),
            
            // Avatar Stack
            Stack(
              children: [
                Obx(() {
                  final imagePath = controller.userImage.value;
                  final loading = controller.isLoading.value;
                  
                  ImageProvider? imageProvider;
                  if (imagePath.isNotEmpty) {
                    if (imagePath.startsWith('http')) {
                      imageProvider = NetworkImage(imagePath);
                    } else {
                      imageProvider = FileImage(File(imagePath));
                    }
                  }

                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      backgroundImage: imageProvider,
                      child: imagePath.isEmpty && !loading
                          ? const Icon(Icons.person, size: 60, color: Colors.white)
                          : null,
                    ),
                  );
                }),
                
                // Camera Button Badge
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: () => controller.pickImage(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
            
            // Upload Loading Overlay
            Obx(() {
              if (controller.isLoading.value && controller.uploadProgress.value > 0) {
                return SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: controller.uploadProgress.value,
                    strokeWidth: 4,
                    color: AppColors.secondary,
                    backgroundColor: Colors.white24,
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFrostedCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        title,
        style: AppFonts.titleMedium.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildPremiumActions(BuildContext context) {
    return Column(
      children: [
        // Update Button
        Obx(() {
          final loading = controller.isLoading.value;
          return InkWell(
            onTap: loading ? null : () => controller.updateProfile(),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: loading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        'update_profile'.tr,
                        style: AppFonts.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          );
        }),
        
        const SizedBox(height: 16),
        
        // Change Password Button
        TextButton.icon(
          onPressed: () => _showChangePasswordDialog(context),
          icon: const Icon(Icons.lock_reset_rounded, color: AppColors.primary),
          label: Text(
            'change_password'.tr,
            style: AppFonts.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          ),
        ),
      ],
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('change_password'.tr, textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: controller.newPasswordController,
              label: 'new_password'.tr,
              obscureText: true,
              prefixIcon: Icons.lock_outline,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: controller.confirmPasswordController,
              label: 'confirm_password'.tr,
              obscureText: true,
              prefixIcon: Icons.lock_clock_outlined,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr, style: const TextStyle(color: Colors.grey)),
          ),
          Obx(() => ElevatedButton(
            onPressed: controller.isLoading.value ? null : () => controller.changePassword(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('save'.tr, style: const TextStyle(color: Colors.white)),
          )),
        ],
      ),
    );
  }
}
