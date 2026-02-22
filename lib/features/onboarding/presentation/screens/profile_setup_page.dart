import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/features/onboarding/controller/onboarding_controller.dart';
import 'package:salah/features/onboarding/presentation/widgets/onboarding_widgets.dart';

class ProfileSetupPage extends GetView<OnboardingController> {
  const ProfileSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final data = controller.pageData;

    return OnboardingPageLayout(
      scrollable: true,
      lottieAsset: data.lottieAsset,
      iconData: data.iconData,
      title: data.localizedTitle,
      subtitle: data.localizedSubtitle,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Gender ── (name asked only in Register to avoid duplication)
              _SectionLabel(label: 'gender_label'.tr),
              const SizedBox(height: 10),
              Obx(
                () => Row(
                  children: [
                    Expanded(
                      child: _GenderCard(
                        icon: Icons.male_rounded,
                        label: 'male'.tr,
                        value: 'male',
                        selectedValue: controller.selectedGender.value,
                        onTap: () => controller.setGender('male'),
                        color: const Color(0xFF4285F4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _GenderCard(
                        icon: Icons.female_rounded,
                        label: 'female'.tr,
                        value: 'female',
                        selectedValue: controller.selectedGender.value,
                        onTap: () => controller.setGender('female'),
                        color: const Color(0xFFE91E63),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // ── Birth date ──
              _SectionLabel(label: 'birthdate_label'.tr),
              const SizedBox(height: 8),
              Obx(
                () => _DatePickerCard(
                  selectedDate: controller.selectedBirthDate.value,
                  onTap: () => _showDatePicker(context),
                ),
              ),
              const SizedBox(height: 32),

              // ── Validation hint ──
              Obx(() {
                if (controller.isProfileValid) {
                  return _ValidationSuccess();
                }
                return const SizedBox.shrink();
              }),

              // ── Complete button ──
              Obx(
                () => OnboardingButton(
                  text: 'complete_btn'.tr,
                  onTap: controller.isProfileValid
                      ? controller.completeOnboarding
                      : () {},
                  color: controller.isProfileValid
                      ? AppColors.success
                      : AppColors.textSecondary.withValues(alpha: 0.35),
                  icon: controller.isProfileValid
                      ? Icons.check_circle_rounded
                      : Icons.person_outline,
                  isLoading: controller.isLoading.value,
                ),
              ),
              const SizedBox(height: 12),

              // ── Skip ──
              Center(
                child: TextButton(
                  onPressed: controller.completeOnboarding,
                  child: Text(
                    'skip_btn'.tr,
                    style: AppFonts.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final initialDate = controller.selectedBirthDate.value ?? DateTime(2000);
    DateTime tempDate = initialDate;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return _DatePickerSheet(
          initialDate: initialDate,
          onDateChanged: (d) => tempDate = d,
          onConfirm: () {
            controller.setBirthDate(tempDate);
            Get.back();
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppFonts.bodyMedium.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        fontSize: 14,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Gender card
// ─────────────────────────────────────────────
class _GenderCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? selectedValue;
  final VoidCallback onTap;
  final Color color;

  const _GenderCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedValue == value;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.25),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : color, size: 32),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppFonts.bodyMedium.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Date picker card
// ─────────────────────────────────────────────
class _DatePickerCard extends StatelessWidget {
  final DateTime? selectedDate;
  final VoidCallback onTap;

  const _DatePickerCard({required this.selectedDate, required this.onTap});

  String _format(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} / ${d.month.toString().padLeft(2, '0')} / ${d.year}';

  @override
  Widget build(BuildContext context) {
    final hasDate = selectedDate != null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: hasDate
              ? AppColors.primary.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasDate
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.textSecondary.withValues(alpha: 0.2),
            width: hasDate ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              color: hasDate ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              hasDate ? _format(selectedDate!) : 'select_birthdate'.tr,
              style: AppFonts.bodyLarge.copyWith(
                color: hasDate
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontWeight: hasDate ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Validation success banner
// ─────────────────────────────────────────────
class _ValidationSuccess extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
          const SizedBox(width: 8),
          Text(
            'profile_ready'.tr,
            style: AppFonts.bodySmall.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Date picker bottom sheet
// ─────────────────────────────────────────────
class _DatePickerSheet extends StatelessWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onConfirm;

  const _DatePickerSheet({
    required this.initialDate,
    required this.onDateChanged,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 4),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: Get.back,
                child: Text(
                  'cancel'.tr,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              Text(
                'select_date'.tr,
                style: AppFonts.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: onConfirm,
                child: Text(
                  'confirm'.tr,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        SizedBox(
          height: 220,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            initialDateTime: initialDate,
            minimumDate: DateTime(1920),
            maximumDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
            onDateTimeChanged: onDateChanged,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
