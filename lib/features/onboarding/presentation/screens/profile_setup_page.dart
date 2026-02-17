import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/features/onboarding/controller/onboarding_controller.dart';

/// Profile setup page
class ProfileSetupPage extends GetView<OnboardingController> {
  const ProfileSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pageData = controller.getPageData(OnboardingStep.profileSetup);
    final isArabic = Get.locale?.languageCode == 'ar';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),

            // Animation
            Center(
              child: SizedBox(
                height: 150,
                child: Lottie.asset(
                  pageData.lottieAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        size: 50,
                        color: AppColors.primary,
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Title
            Center(
              child: Text(
                pageData.titleKey.tr,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            const SizedBox(height: 8),

            Center(
              child: Text(
                pageData.subtitleKey.tr,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
            ),

            const SizedBox(height: 40),

            // Name Input
            _buildInputSection(
              label: 'name_label'.tr,
              child: TextField(
                controller: controller.nameController,
                textAlign: isArabic ? TextAlign.right : TextAlign.left,
                decoration: InputDecoration(
                  hintText: 'name_label'.tr,
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: AppColors.primary,
                  ),
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppColors.textSecondary.withValues(alpha: 0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppColors.textSecondary.withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Gender Selection
            _buildInputSection(
              label: 'gender_label'.tr,
              child: Obx(
                () => Row(
                  children: [
                    Expanded(
                      child: _buildGenderOption(
                        icon: Icons.male,
                        label: 'male'.tr,
                        value: 'male',
                        isSelected: controller.selectedGender.value == 'male',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildGenderOption(
                        icon: Icons.female,
                        label: 'female'.tr,
                        value: 'female',
                        isSelected: controller.selectedGender.value == 'female',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Birth Date (Optional)
            _buildInputSection(
              label: 'birthdate_label'.tr,
              child: Obx(
                () => Material(
                  color: AppColors.transparent,
                  child: InkWell(
                    onTap: () => _showDatePicker(context),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.textSecondary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            controller.selectedBirthDate.value != null
                                ? _formatDate(
                                    controller.selectedBirthDate.value!,
                                  )
                                : 'birthdate_label'.tr,
                            style: TextStyle(
                              color: controller.selectedBirthDate.value != null
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_drop_down,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Complete button
            _buildCompleteButton(isArabic),

            const SizedBox(height: 16),

            // Skip
            Center(
              child: TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  controller.completeOnboarding();
                },
                child: Text(
                  'skip_btn'.tr,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildGenderOption({
    required IconData icon,
    required String label,
    required String value,
    required bool isSelected,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          controller.setGender(value);
        },
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textSecondary.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedBirthDate.value ?? DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 7), // Minimum 7 years old
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.setBirthDate(picked);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildCompleteButton(bool isArabic) {
    return Obx(() {
      final isValid = controller.nameController.text.isNotEmpty;

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isValid
              ? () {
                  HapticFeedback.mediumImpact();
                  controller.completeOnboarding();
                }
              : null,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isValid
                    ? [
                        AppColors.success,
                        AppColors.success.withValues(alpha: 0.8),
                      ]
                    : [
                        AppColors.textSecondary.withValues(alpha: 0.3),
                        AppColors.textSecondary.withValues(alpha: 0.2),
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: isValid
                  ? [
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isValid ? Icons.check_circle : Icons.person_outline,
                    color: AppColors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'complete_btn'.tr,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
