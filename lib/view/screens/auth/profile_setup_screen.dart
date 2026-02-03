import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../controller/auth_controller.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

/// Profile setup screen after registration
class ProfileSetupScreen extends StatelessWidget {
  const ProfileSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'إعداد الملف الشخصي',
          style: AppFonts.titleLarge.copyWith(
            color: AppColors.textPrimary,
          ),
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
                          color: Colors.white,
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
                label: 'الاسم',
                prefixIcon: Icons.person_outline,
              ),

              const SizedBox(height: AppDimensions.paddingMD),

              // Birth date field
              AppTextField(
                controller: controller.birthDateController,
                label: 'تاريخ الميلاد',
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
                'الجنس',
                style: AppFonts.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingSM),

              Obx(() => Row(
                children: [
                  Expanded(
                    child: _GenderOption(
                      label: 'ذكر',
                      icon: Icons.male,
                      isSelected: controller.selectedGender.value == 'male',
                      onTap: () => controller.setGender('male'),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingMD),
                  Expanded(
                    child: _GenderOption(
                      label: 'أنثى',
                      icon: Icons.female,
                      isSelected: controller.selectedGender.value == 'female',
                      onTap: () => controller.setGender('female'),
                    ),
                  ),
                ],
              )),

              const SizedBox(height: AppDimensions.paddingXL * 2),

              // Error message
              Obx(() {
                if (controller.errorMessage.value.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppDimensions.paddingMD),
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
              Obx(() => AppButton(
                text: 'متابعة',
                onPressed: () async {
                  final success = await controller.updateProfile();
                  if (success) {
                    Get.offAllNamed('/dashboard');
                  }
                },
                isLoading: controller.isLoading.value,
                width: double.infinity,
              )),

              const SizedBox(height: AppDimensions.paddingMD),

              // Skip button
              TextButton(
                onPressed: () => Get.offAllNamed('/dashboard'),
                child: Text(
                  'تخطي الآن',
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
        padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.paddingMD,
        ),
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
