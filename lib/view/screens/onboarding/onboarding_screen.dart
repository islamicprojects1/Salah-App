import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/image_assets.dart';
import '../../../controller/auth_controller.dart';
import '../../widgets/app_button.dart';

/// Onboarding screen with 3 pages
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final AuthController _authController = Get.find<AuthController>();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      image: ImageAssets.onboardingWelcome,
      title: 'تابع صلاتك',
      subtitle: 'سجّل صلواتك بضغطة واحدة\nوتابع تقدمك اليومي',
    ),
    _OnboardingPage(
      image: ImageAssets.onboardingCommunity,
      title: 'مع عائلتك',
      subtitle: 'تابع صلاة أفراد عائلتك\nوشجّعوا بعضكم',
    ),
    _OnboardingPage(
      image: ImageAssets.onboardingLocation,
      title: 'مواقيت دقيقة',
      subtitle: 'أوقات الصلاة والقبلة\nحسب موقعك',
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() {
    _authController.completeOnboarding();
    Get.offAllNamed('/login');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: AlignmentDirectional.topEnd,
              child: TextButton(
                onPressed: _finishOnboarding,
                child: Text(
                  'تخطي',
                  style: AppFonts.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),

            // Dots indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => _buildDot(index),
              ),
            ),

            const SizedBox(height: AppDimensions.paddingXL),

            // Next/Start button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingLG,
              ),
              child: AppButton(
                text: _currentPage == _pages.length - 1 ? 'ابدأ الآن' : 'التالي',
                onPressed: _nextPage,
                width: double.infinity,
              ),
            ),

            const SizedBox(height: AppDimensions.paddingXL),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingLG,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image
          Image.asset(
            page.image,
            height: AppDimensions.imageOnboarding,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: AppDimensions.imageOnboarding,
                width: AppDimensions.imageOnboarding,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mosque_outlined,
                  size: AppDimensions.iconOnboardingPlaceholder,
                  color: AppColors.primary,
                ),
              );
            },
          ),

          const SizedBox(height: AppDimensions.paddingXL),

          // Title
          Text(
            page.title,
            style: AppFonts.headlineLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppDimensions.paddingMD),

          // Subtitle
          Text(
            page.subtitle,
            style: AppFonts.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    final isActive = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? AppDimensions.dotWidthActive : AppDimensions.dotSize,
      height: AppDimensions.dotSize,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.primary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
      ),
    );
  }
}

class _OnboardingPage {
  final String image;
  final String title;
  final String subtitle;

  _OnboardingPage({
    required this.image,
    required this.title,
    required this.subtitle,
  });
}
