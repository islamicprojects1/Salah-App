import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:salah/controller/onboarding_controller.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/theme/app_colors.dart';

/// Features showcase page with swipeable feature cards
class FeaturesPage extends GetView<OnboardingController> {
  const FeaturesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pageData = controller.getPageData(OnboardingStep.features);
    final isArabic = Get.locale?.languageCode == 'ar';

    return SafeArea(
      child: Column(
        children: [
          const Spacer(flex: 1),

          // Animation
          SizedBox(
            height: 220,
            child: Lottie.asset(
              pageData.lottieAsset,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.check_circle_outline,
                  size: 120,
                  color: AppColors.primary,
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Title
          Text(
            isArabic ? pageData.title : pageData.titleEn,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            isArabic ? pageData.subtitle : pageData.subtitleEn,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),

          const Spacer(flex: 1),

          // Feature highlights
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _buildFeatureRow(
                  icon: Icons.touch_app_rounded,
                  title: isArabic ? 'سجّل بضغطة واحدة' : 'One-tap logging',
                  subtitle: isArabic ? 'سريع وسهل' : 'Fast and easy',
                  color: const Color(0xFF6366F1),
                ),
                const SizedBox(height: 12),
                _buildFeatureRow(
                  icon: Icons.analytics_rounded,
                  title: isArabic ? 'إحصائيات مفصلة' : 'Detailed statistics',
                  subtitle: isArabic ? 'تابع تقدمك' : 'Track your progress',
                  color: const Color(0xFF10B981),
                ),
                const SizedBox(height: 12),
                _buildFeatureRow(
                  icon: Icons.celebration_rounded,
                  title: isArabic
                      ? 'إنجازات وتحديات'
                      : 'Achievements & challenges',
                  subtitle: isArabic
                      ? 'حافز للاستمرار'
                      : 'Motivation to continue',
                  color: const Color(0xFFF59E0B),
                ),
              ],
            ),
          ),

          const Spacer(flex: 2),

          // Navigation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: _buildNavigationRow(),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: color, size: 24),
        ],
      ),
    );
  }

  Widget _buildNavigationRow() {
    return Row(
      children: [
        // Back button
        IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            controller.previousStep();
          },
          icon: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const Spacer(),
        // Next button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              controller.nextStep();
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    controller.getButtonText(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Family intro page
class FamilyPage extends GetView<OnboardingController> {
  const FamilyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pageData = controller.getPageData(OnboardingStep.family);
    final isArabic = Get.locale?.languageCode == 'ar';

    return SafeArea(
      child: Column(
        children: [
          const Spacer(flex: 1),

          // Animation
          SizedBox(
            height: 220,
            child: Lottie.asset(
              pageData.lottieAsset,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.family_restroom_rounded,
                  size: 120,
                  color: AppColors.primary,
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Title with emoji
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(pageData.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Text(
                isArabic ? pageData.title : pageData.titleEn,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              isArabic ? pageData.subtitle : pageData.subtitleEn,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),

          const Spacer(flex: 1),

          // Family features
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.secondary.withValues(alpha: 0.1),
                    AppColors.primary.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  _buildFamilyFeature(
                    emoji: '👀',
                    text: isArabic
                        ? 'تابع صلاة أفراد عائلتك'
                        : 'Track family prayers',
                  ),
                  const SizedBox(height: 12),
                  _buildFamilyFeature(
                    emoji: '💚',
                    text: isArabic
                        ? 'أرسل تشجيعاً لمن تحب'
                        : 'Send encouragements',
                  ),
                  const SizedBox(height: 12),
                  _buildFamilyFeature(
                    emoji: '🔔',
                    text: isArabic
                        ? 'تذكيرات لطيفة ومحفزة'
                        : 'Gentle reminders',
                  ),
                  const SizedBox(height: 12),
                  _buildFamilyFeature(
                    emoji: '🔒',
                    text: isArabic
                        ? 'الخصوصية محفوظة دائماً'
                        : 'Privacy always protected',
                  ),
                ],
              ),
            ),
          ),

          const Spacer(flex: 2),

          // Navigation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: _buildNavigationRow(),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFamilyFeature({required String emoji, required String text}) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationRow() {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            controller.previousStep();
          },
          icon: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const Spacer(),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              controller.nextStep();
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    controller.getButtonText(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
