import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/features/onboarding/controller/onboarding_controller.dart';
import 'package:salah/features/onboarding/presentation/widgets/onboarding_widgets.dart';

// ─────────────────────────────────────────────
// Features Page
// ─────────────────────────────────────────────
class FeaturesPage extends GetView<OnboardingController> {
  const FeaturesPage({super.key});

  static const _features = [
    _FeatureData(
      icon: Icons.touch_app_rounded,
      titleKey: 'feature_one_tap_title',
      subtitleKey: 'feature_one_tap_desc',
      colorKey: 'feature1',
    ),
    _FeatureData(
      icon: Icons.analytics_rounded,
      titleKey: 'feature_stats_title',
      subtitleKey: 'feature_stats_desc',
      colorKey: 'feature2',
    ),
    _FeatureData(
      icon: Icons.celebration_rounded,
      titleKey: 'feature_achievements_title',
      subtitleKey: 'feature_motivation_desc',
      colorKey: 'feature3',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final data = controller.pageData;

    return OnboardingPageLayout(
      scrollable: true,
      lottieAsset: data.lottieAsset,
      title: data.localizedTitle,
      subtitle: data.localizedSubtitle,
      navigationRow: _NavRow(controller: controller),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: _features.asMap().entries.map((e) {
              final index = e.key;
              final feat = e.value;
              final color = _colorForKey(feat.colorKey);
              return StaggeredFeatureItem(
                index: index,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: index < _features.length - 1 ? 12 : 0,
                  ),
                  child: _FeatureCard(
                    icon: feat.icon,
                    title: feat.titleKey.tr,
                    subtitle: feat.subtitleKey.tr,
                    color: color,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Color _colorForKey(String key) {
    switch (key) {
      case 'feature1':
        return AppColors.feature1;
      case 'feature2':
        return AppColors.feature2;
      case 'feature3':
        return AppColors.feature3;
      default:
        return AppColors.primary;
    }
  }
}

class _FeatureData {
  final IconData icon;
  final String titleKey;
  final String subtitleKey;
  final String colorKey;

  const _FeatureData({
    required this.icon,
    required this.titleKey,
    required this.subtitleKey,
    required this.colorKey,
  });
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: AppFonts.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded, color: color, size: 16),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Family Page
// ─────────────────────────────────────────────
class FamilyPage extends GetView<OnboardingController> {
  const FamilyPage({super.key});

  static const _familyFeatures = [
    _FamilyItem(emoji: '👀', key: 'feature_family_track'),
    _FamilyItem(emoji: '💚', key: 'feature_family_encourage'),
    _FamilyItem(emoji: '🔔', key: 'feature_family_reminders'),
    _FamilyItem(emoji: '🔒', key: 'feature_family_privacy'),
  ];

  @override
  Widget build(BuildContext context) {
    final data = controller.pageData;

    return OnboardingPageLayout(
      scrollable: true,
      lottieAsset: data.lottieAsset,
      iconData: data.iconData,
      title: data.localizedTitle,
      subtitle: data.localizedSubtitle,
      emoji: data.emoji,
      navigationRow: _NavRow(controller: controller),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: _familyFeatures.asMap().entries.map((e) {
                return StaggeredFeatureItem(
                  index: e.key,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: e.key < _familyFeatures.length - 1 ? 16 : 0,
                    ),
                    child: _FamilyFeatureRow(item: e.value),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _FamilyItem {
  final String emoji;
  final String key;
  const _FamilyItem({required this.emoji, required this.key});
}

class _FamilyFeatureRow extends StatelessWidget {
  final _FamilyItem item;
  const _FamilyFeatureRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(item.emoji, style: const TextStyle(fontSize: 22)),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            item.key.tr,
            style: AppFonts.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Shared navigation row
// ─────────────────────────────────────────────
class _NavRow extends StatelessWidget {
  final OnboardingController controller;
  const _NavRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        OnboardingSecondaryButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: controller.previousStep,
        ),
        const Spacer(),
        OnboardingButton(
          fullWidth: false,
          text: controller.buttonText,
          onTap: controller.nextStep,
          icon: Icons.arrow_forward_ios_rounded,
        ),
      ],
    );
  }
}
