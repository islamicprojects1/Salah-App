import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/core/routes/app_routes.dart';
import 'package:salah/core/widgets/app_button.dart';
import 'package:salah/core/widgets/app_text_field.dart';
import 'package:salah/features/auth/controller/auth_controller.dart';

/// Profile setup screen after registration
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<AuthController>()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed(AppRoutes.login);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
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
        // No back button — user just registered
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(AppDimensions.paddingLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Progress indicator (step 2 of 2) ───
                _SetupProgressIndicator(currentStep: 2, totalSteps: 2),
                const SizedBox(height: AppDimensions.paddingLG),

                // ─── Avatar ───
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: AppDimensions.radiusProfileAvatarLarge,
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.1,
                        ),
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

                // ─── Name field ───
                AppTextField(
                  controller: controller.nameController,
                  label: 'name_label'.tr,
                  prefixIcon: Icons.person_outline,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => controller.clearError(),
                ),

                const SizedBox(height: AppDimensions.paddingMD),

                // ─── Birth date field ───
                AppTextField(
                  controller: controller.birthDateController,
                  label: 'birth_date'.tr,
                  prefixIcon: Icons.calendar_today_outlined,
                  readOnly: true,
                  onTap: () => _pickDate(context, controller),
                ),

                const SizedBox(height: AppDimensions.paddingMD),

                // ─── Gender selection ───
                Text(
                  'gender'.tr,
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
                          isSelected:
                              controller.selectedGender.value == 'female',
                          onTap: () => controller.setGender('female'),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppDimensions.paddingXL),

                // ─── Error message ───
                Obx(() {
                  final msg = controller.errorMessage.value;
                  if (msg.isEmpty) return const SizedBox.shrink();
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(
                      bottom: AppDimensions.paddingMD,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingMD,
                      vertical: AppDimensions.paddingSM,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSM,
                      ),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 16,
                        ),
                        const SizedBox(width: AppDimensions.paddingXS),
                        Expanded(
                          child: Text(
                            msg,
                            style: AppFonts.bodySmall.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                // ─── Save button ───
                Obx(
                  () => AppButton(
                    text: 'save_profile'.tr,
                    onPressed: () async {
                      FocusScope.of(context).unfocus();
                      final success = await controller.updateProfile();
                      if (success && context.mounted) {
                        Get.offAllNamed(AppRoutes.dashboard);
                      }
                    },
                    isLoading: controller.isLoading.value,
                    width: double.infinity,
                  ),
                ),

                const SizedBox(height: AppDimensions.paddingMD),

                // ─── Skip button ───
                TextButton(
                  onPressed: () => Get.offAllNamed(AppRoutes.dashboard),
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
      ),
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    AuthController controller,
  ) async {
    final initial = controller.selectedBirthDate.value ?? DateTime(2000);
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1930),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: AppColors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (date != null) {
      controller.setBirthDate(date);
    }
  }
}

// ─────────────────────────────────────────────
// Step progress bar
// ─────────────────────────────────────────────
class _SetupProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _SetupProgressIndicator({
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(totalSteps, (i) {
            final isActive = i < currentStep;
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: i < totalSteps - 1 ? 4 : 0),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: AppDimensions.paddingXS),
        Text(
          '${'step'.tr} $currentStep ${'of'.tr} $totalSteps',
          style: AppFonts.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Gender option card
// ─────────────────────────────────────────────
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.paddingMD,
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
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
