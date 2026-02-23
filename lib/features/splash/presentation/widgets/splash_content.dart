import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/image_assets.dart';
import 'package:salah/core/theme/app_colors.dart';

/// Decorative background elements for splash screen
class SplashDecorativeElements extends StatelessWidget {
  const SplashDecorativeElements({
    super.key,
    required this.glowAnimation,
  });

  final Animation<double> glowAnimation;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: glowAnimation,
        builder: (context, child) {
          return Stack(
            children: [
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.splashGlowColor.withValues(
                          alpha: 0.1 * glowAnimation.value,
                        ),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -80,
                left: -80,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.splashWhite.withValues(
                          alpha: 0.05 * glowAnimation.value,
                        ),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Logo with glow effect
class SplashLogoWithGlow extends StatelessWidget {
  const SplashLogoWithGlow({
    super.key,
    required this.glowAnimation,
  });

  final Animation<double> glowAnimation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glowAnimation,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(35),
          clipBehavior: Clip.antiAlias,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(35),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.15),
                  Colors.white.withValues(alpha: 0.06),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withValues(
                    alpha: 0.25 * glowAnimation.value,
                  ),
                  blurRadius: 30 + (10 * glowAnimation.value),
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Image.asset(
                ImageAssets.appLogo,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.mosque,
                  size: 70,
                  color: AppColors.secondary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// App name text
class SplashAppName extends StatelessWidget {
  const SplashAppName({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'app_title'.tr,
      style: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: AppColors.splashWhite,
        letterSpacing: 2,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
    );
  }
}

/// Tagline text
class SplashTagline extends StatelessWidget {
  const SplashTagline({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'prayer_times_subtitle'.tr,
      style: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColors.secondary.withValues(alpha: 0.9),
        letterSpacing: 1.2,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

/// Loading indicator
class SplashLoadingIndicator extends StatefulWidget {
  const SplashLoadingIndicator({super.key});

  @override
  State<SplashLoadingIndicator> createState() => _SplashLoadingIndicatorState();
}

class _SplashLoadingIndicatorState extends State<SplashLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final delay = i / 3;
                final t = (((_controller.value - delay) % 1.0 + 1.0) % 1.0);
                final scale = 0.5 + 0.5 * (t < 0.5 ? t * 2 : (1 - t) * 2);
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: 10 * scale,
                  height: 10 * scale,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(
                      alpha: 0.5 + 0.5 * scale,
                    ),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          'loading_msg'.tr,
          style: TextStyle(
            color: AppColors.splashWhite.withValues(alpha: 0.8),
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

