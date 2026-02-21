import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/routes/app_routes.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/features/auth/controller/auth_controller.dart';
import 'package:salah/features/splash/presentation/widgets/splash_content.dart';

/// Splash screen shown when app starts.
/// Handles initial loading and navigation to home screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _navigateToHome();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.repeat(reverse: true);
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 2));

    final authController = Get.find<AuthController>();

    if (authController.isFirstTime) {
      Get.offAllNamed(AppRoutes.onboarding);
    } else if (!authController.isLoggedIn) {
      Get.offAllNamed(AppRoutes.login);
    } else {
      Get.offAllNamed(AppRoutes.dashboard);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? AppColors.splashDarkGradient
                : AppColors.splashLightGradient,
          ),
        ),
        child: Stack(
          children: [
            SplashDecorativeElements(glowAnimation: _glowAnimation),
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SplashLogoWithGlow(glowAnimation: _glowAnimation),
                    const SizedBox(height: 32),
                    const SplashAppName(),
                    const SizedBox(height: 12),
                    const SplashTagline(),
                    const SizedBox(height: 60),
                    const SplashLoadingIndicator(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
