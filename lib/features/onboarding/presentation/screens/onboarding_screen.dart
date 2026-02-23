import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/features/onboarding/controller/onboarding_controller.dart';
import 'package:salah/features/onboarding/presentation/screens/welcome_page.dart';
import 'package:salah/features/onboarding/presentation/screens/features_page.dart';
import 'package:salah/features/onboarding/presentation/screens/permissions_page.dart';
import 'package:salah/features/onboarding/presentation/screens/profile_setup_page.dart';
import 'package:salah/features/onboarding/presentation/widgets/onboarding_widgets.dart';

class OnboardingScreen extends GetView<OnboardingController> {
  const OnboardingScreen({super.key});

  // Subtle background tint per page
  static const List<Color> _pageTints = [
    Color(0xFFF0FFF4), // welcome  — soft mint
    Color(0xFFF0F8FF), // features — cool blue
    Color(0xFFF5F0FF), // perms    — soft purple
    Color(0xFFF0FFF8), // profile  — soft teal
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      const WelcomePage(),
      const FeaturesPage(),
      const PermissionsPage(),
      const ProfileSetupPage(),
    ];

    return Obx(() {
      final page = controller.currentPage.value.clamp(0, _pageTints.length - 1);

      return AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        color: _pageTints[page],
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // ── Decorative top arc ──
              Positioned(top: -80, left: -60, child: _TopArc()),

              // ── Page content ──
              // Page content — animations handled by controller's
              // fadeController/slideController wrapping the whole view.
              FadeTransition(
                opacity: controller.fadeAnimation,
                child: SlideTransition(
                  position: controller.slideAnimation,
                  child: PageView.builder(
                    controller: controller.pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pages.length,
                    itemBuilder: (_, index) => pages[index],
                  ),
                ),
              ),

              // ── Language toggle (only on welcome page) ──
              _LanguageToggleButton(controller: controller),

              // ── Skip button ──
              _SkipButton(controller: controller),

              // ── Progress dots ──
              _ProgressBar(controller: controller),
            ],
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────
// Language toggle button (top-left, welcome page only)
// ─────────────────────────────────────────────
class _LanguageToggleButton extends StatelessWidget {
  final OnboardingController controller;
  const _LanguageToggleButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 12,
      child: SafeArea(
        child: Obx(() {
          // Only show on welcome page (page 0)
          if (controller.currentPage.value != 0) {
            return const SizedBox.shrink();
          }
          final isArabic = Get.locale?.languageCode == 'ar';
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => controller.switchLanguage(isArabic ? 'en' : 'ar'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.language_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isArabic ? 'EN' : 'عر',
                      style: AppFonts.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Decorative top arc
// ─────────────────────────────────────────────
class _TopArc extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: 260,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.primary.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Skip button (top-right)
// ─────────────────────────────────────────────
class _SkipButton extends StatelessWidget {
  final OnboardingController controller;
  const _SkipButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    // Positioned must be a direct child of Stack — wrap Obx inside it.
    return Positioned(
      top: 0,
      right: 12,
      child: SafeArea(
        child: Obx(() {
          if (!controller.canSkip) return const SizedBox.shrink();
          return TextButton(
            onPressed: controller.skip,
            style: TextButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(
              'skip_btn'.tr,
              style: AppFonts.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Progress dots (bottom)
// ─────────────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  final OnboardingController controller;
  const _ProgressBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final bottomOffset = safeBottom + 16 < 24 ? 24.0 : safeBottom + 16;
    return Positioned(
      bottom: bottomOffset,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: Obx(
            () => OnboardingProgressDots(
              current: controller.currentPage.value,
              total: OnboardingController.totalPages,
            ),
          ),
        ),
      ),
    );
  }
}
