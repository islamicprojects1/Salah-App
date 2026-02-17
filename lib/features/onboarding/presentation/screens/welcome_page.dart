import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/features/onboarding/controller/onboarding_controller.dart';

/// Premium welcome page with animated entrance
class WelcomePage extends GetView<OnboardingController> {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final pageData = controller.getPageData(OnboardingStep.welcome);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.05),
            AppColors.white,
            AppColors.secondary.withValues(alpha: 0.03),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 1),

            // Animated Logo/Illustration
            Hero(
              tag: 'onboarding_animation',
              child: Container(
                height: 280,
                width: 280,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.1),
                      AppColors.transparent,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Lottie.asset(
                  pageData.lottieAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildFallbackIcon();
                  },
                ),
              ),
            ),

            const Spacer(flex: 1),

            // Welcome Text with shimmer effect
            _buildAnimatedTitle(pageData),

            const SizedBox(height: 16),

            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                pageData.subtitleKey.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.textSecondary,
                  height: 1.6,
                  letterSpacing: 0.3,
                ),
              ),
            ),

            const Spacer(flex: 2),

            // Start Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: _buildPrimaryButton(
                label: controller.getButtonText(),
                onTap: () {
                  HapticFeedback.mediumImpact();
                  controller.nextStep();
                },
              ),
            ),

            const SizedBox(height: 24),

            // Language Switcher
            _buildLanguageSwitcher(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
        ),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.mosque_outlined,
        size: 120,
        color: AppColors.white,
      ),
    );
  }

  Widget _buildAnimatedTitle(OnboardingPageData pageData) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [AppColors.primary, AppColors.secondary],
      ).createShader(bounds),
      child: Text(
        pageData.titleKey.tr,
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSwitcher() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLanguageButton('AR', 'ar'),
        const SizedBox(width: 16),
        Container(
          width: 1,
          height: 20,
          color: AppColors.textSecondary.withValues(alpha: 0.3),
        ),
        const SizedBox(width: 16),
        _buildLanguageButton('EN', 'en'),
      ],
    );
  }

  Widget _buildLanguageButton(String label, String code) {
    final isSelected = Get.locale?.languageCode == code;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Get.updateLocale(Locale(code));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.textSecondary.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
