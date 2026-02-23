import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/features/onboarding/controller/onboarding_controller.dart';
import 'package:salah/features/onboarding/presentation/widgets/onboarding_widgets.dart';

class WelcomePage extends GetView<OnboardingController> {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final data = controller.pageData;

    return OnboardingPageLayout(
      scrollable: false,
      lottieAsset: data.lottieAsset,
      iconData: data.iconData,
      title: data.localizedTitle,
      subtitle: data.localizedSubtitle,
      children: [
        const SizedBox(height: 16),

        // ── CTA button ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: OnboardingButton(
            text: controller.buttonText,
            onTap: controller.nextStep,
            icon: Icons.arrow_forward_rounded,
          ),
        ),
        const SizedBox(height: 60), // space for progress dots
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Language switcher
// ─────────────────────────────────────────────
class _LanguageSwitcher extends GetView<OnboardingController> {
  const _LanguageSwitcher();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<OnboardingController>(
      builder: (ctrl) {
        final currentLang = Get.locale?.languageCode ?? 'ar';
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LangButton(
              label: 'العربية',
              code: 'ar',
              isSelected: currentLang == 'ar',
              onTap: () => ctrl.switchLanguage('ar'),
            ),
            Container(
              width: 1,
              height: 20,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: AppColors.textSecondary.withValues(alpha: 0.25),
            ),
            _LangButton(
              label: 'English',
              code: 'en',
              isSelected: currentLang == 'en',
              onTap: () => ctrl.switchLanguage('en'),
            ),
          ],
        );
      },
    );
  }
}

class _LangButton extends StatelessWidget {
  final String label;
  final String code;
  final bool isSelected;
  final VoidCallback onTap;

  const _LangButton({
    required this.label,
    required this.code,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppFonts.bodyMedium.copyWith(
            color: isSelected ? AppColors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
