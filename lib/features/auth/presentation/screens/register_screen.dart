import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/core/widgets/app_button.dart';
import 'package:salah/core/widgets/app_text_field.dart';
import 'package:salah/features/auth/controller/auth_controller.dart';

/// Register screen
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Text(
                'create_account'.tr,
                style: AppFonts.headlineLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppDimensions.paddingSM),

              Text(
                'register_subtitle'.tr,
                style: AppFonts.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppDimensions.paddingXL * 2),

              // Name field
              AppTextField(
                controller: controller.nameController,
                label: 'name_label'.tr,
                prefixIcon: Icons.person_outline,
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: AppDimensions.paddingMD),

              // Email field
              EmailTextField(
                controller: controller.emailController,
                label: 'email_label'.tr,
              ),

              const SizedBox(height: AppDimensions.paddingMD),

              // Password field
              PasswordTextField(
                controller: controller.passwordController,
                label: 'password_label'.tr,
              ),

              const SizedBox(height: AppDimensions.paddingXL),

              // Error message
              Obx(() {
                if (controller.errorMessage.value.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppDimensions.paddingMD,
                    ),
                    child: Text(
                      controller.errorMessage.value,
                      style: AppFonts.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),

              // Register button
              Obx(
                () => AppButton(
                  text: 'create_account'.tr,
                  onPressed: () async {
                    final success = await controller.registerWithEmail();
                    if (success) {
                      Get.offAllNamed('/profile-setup');
                    }
                  },
                  isLoading: controller.isLoading.value,
                  width: double.infinity,
                ),
              ),

              const SizedBox(height: AppDimensions.paddingXL),

              // Login link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'already_have_account'.tr,
                    style: AppFonts.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text(
                      'login'.tr,
                      style: AppFonts.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
