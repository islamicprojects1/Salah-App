import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/core/widgets/app_button.dart';
import 'package:salah/core/widgets/app_text_field.dart';
import 'package:salah/features/auth/controller/auth_controller.dart';

/// Profile setup screen after registration
class ProfileSetupScreen extends StatelessWidget {
  const ProfileSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        title: Text(
          'profile_setup_title'.tr,
          style: AppFonts.titleLarge.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppDimensions.paddingMD),

              // Avatar placeholder
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: AppDimensions.radiusProfileAvatarLarge,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Icon(
                        Icons.person,
                        size: AppDimensions.radiusProfileAvatarLarge,
                        color: AppColors.primary,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: AppDimensions.radiusProfileCameraBadge,
                        backgroundColor: AppColors.primary,
                        child: const Icon(
                          Icons.camera_alt,
                          size: AppDimensions.radiusProfileCameraBadge,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.paddingXL),

              // Name field
              AppTextField(
                controller: controller.nameController,
                label: 'name_label'.tr,
                prefixIcon: Icons.person_outline,
              ),

              const SizedBox(height: AppDimensions.paddingMD),

              // Birth date field
              AppTextField(
                controller: controller.birthDateController,
                label: 'birthdate_label'.tr,
                prefixIcon: Icons.calendar_today_outlined,
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2000),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    controller.setBirthDate(date);
                  }
                },
              ),

              const SizedBox(height: AppDimensions.paddingMD),

              // Gender selection
              Text(
                'gender_label'.tr,
                style: AppFonts.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingSM),

              Obx(
                () => Row(
                  children: [
                    Expanded(
                      child: _GenderOption(
                        label: 'male'.tr,
                        icon: Icons.male,
                        isSelected: controller.selectedGender.value == 'male',
                        onTap: () => controller.setGender('male'),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.paddingMD),
                    Expanded(
                      child: _GenderOption(
                        label: 'female'.tr,
                        icon: Icons.female,
                        isSelected: controller.selectedGender.value == 'female',
                        onTap: () => controller.setGender('female'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.paddingXL * 2),

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

              // Continue button
              Obx(
                () => AppButton(
                  text: 'continue_btn'.tr,
                  onPressed: () async {
                    final success = await controller.updateProfile();
                    if (success) {
                      Get.offAllNamed('/dashboard');
                    }
                  },
                  isLoading: controller.isLoading.value,
                  width: double.infinity,
                ),
              ),

              const SizedBox(height: AppDimensions.paddingMD),

              // Skip button
              TextButton(
                onPressed: () => Get.offAllNamed('/dashboard'),
                child: Text(
                  'skip_btn'.tr,
                  style: AppFonts.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenderOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingMD),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? AppDimensions.borderWidthSelected : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: AppDimensions.iconGender,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: AppDimensions.paddingXS),
            Text(
              label,
              style: AppFonts.bodyMedium.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
