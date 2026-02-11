import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/image_assets.dart';
import '../../../controller/auth_controller.dart';
import '../../widgets/app_button.dart';

/// Enhanced Onboarding screen with 3 pages and warm animations
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final AuthController _authController = Get.find<AuthController>();
  int _currentPage = 0;

  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      image: ImageAssets.onboardingWelcome,
      title: 'onboarding_title_1'.tr,
      subtitle: 'onboarding_subtitle_1'.tr,
      iconFallback: Icons.mosque_outlined,
      gradientColors: [AppColors.onboarding1Start, AppColors.onboarding1End],
    ),
    _OnboardingPage(
      image: ImageAssets.onboardingCommunity,
      title: 'onboarding_title_2'.tr,
      subtitle: 'onboarding_subtitle_2'.tr,
      iconFallback: Icons.family_restroom_outlined,
      gradientColors: [AppColors.onboarding2Start, AppColors.onboarding2End],
    ),
    _OnboardingPage(
      image: ImageAssets.onboardingLocation,
      title: 'onboarding_title_3'.tr,
      subtitle: 'onboarding_subtitle_3'.tr,
      iconFallback: Icons.location_on_outlined,
      gradientColors: [AppColors.onboarding3Start, AppColors.onboarding3End],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    _fadeController.forward();
    _scaleController.forward();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() {
    _authController.completeOnboarding();
    Get.offAllNamed('/login');
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _fadeController.reset();
    _scaleController.reset();
    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background,
              AppColors.primary.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: AlignmentDirectional.topEnd,
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingMD),
                  child: TextButton(
                    onPressed: _finishOnboarding,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingLG,
                        vertical: AppDimensions.paddingSM,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'skip'.tr,
                          style: AppFonts.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Page view
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return AnimatedBuilder(
                      animation: Listenable.merge([_fadeAnimation, _scaleAnimation]),
                      builder: (context, child) {
                        return Opacity(
                          opacity: index == _currentPage ? _fadeAnimation.value : 1.0,
                          child: Transform.scale(
                            scale: index == _currentPage ? _scaleAnimation.value : 1.0,
                            child: _buildPage(_pages[index]),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Bottom section
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingLG),
                child: Column(
                  children: [
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
                    AppButton(
                      text: _currentPage == _pages.length - 1 ? 'get_started'.tr : 'next'.tr,
                      onPressed: _nextPage,
                      width: double.infinity,
                      icon: _currentPage == _pages.length - 1
                          ? Icons.rocket_launch_outlined
                          : Icons.arrow_back_ios,
                    ),

                    const SizedBox(height: AppDimensions.paddingMD),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingXL,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image with gradient overlay
          Container(
            height: AppDimensions.imageOnboarding,
            width: AppDimensions.imageOnboarding,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  page.gradientColors[0].withValues(alpha: 0.15),
                  page.gradientColors[1].withValues(alpha: 0.15),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: page.gradientColors[0].withValues(alpha: 0.2),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                page.image,
                height: AppDimensions.imageOnboarding,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: AppDimensions.imageOnboarding,
                    width: AppDimensions.imageOnboarding,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: page.gradientColors,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      page.iconFallback,
                      size: AppDimensions.iconOnboardingPlaceholder,
                      color: AppColors.white,
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: AppDimensions.paddingXXL),

          // Title with gradient effect
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                AppColors.primary,
                page.gradientColors[0],
              ],
            ).createShader(bounds),
            child: Text(
              page.title,
              style: AppFonts.headlineLarge.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
                fontSize: 32,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: AppDimensions.paddingMD),

          // Subtitle
          Text(
            page.subtitle,
            style: AppFonts.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              height: 1.8,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    final isActive = index == _currentPage;
    final page = _pages[_currentPage];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? AppDimensions.dotWidthActive : AppDimensions.dotSize,
      height: AppDimensions.dotSize,
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(
                colors: page.gradientColors,
              )
            : null,
        color: isActive ? null : AppColors.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: page.gradientColors[0].withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
    );
  }
}

class _OnboardingPage {
  final String image;
  final String title;
  final String subtitle;
  final IconData iconFallback;
  final List<Color> gradientColors;

  _OnboardingPage({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.iconFallback,
    required this.gradientColors,
  });
}
