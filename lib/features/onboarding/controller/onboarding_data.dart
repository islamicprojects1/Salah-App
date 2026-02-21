import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/constants/image_assets.dart';

class OnboardingPageData {
  final String? lottieAsset;
  final IconData? iconData;
  final String titleKey;
  final String subtitleKey;
  final String emoji;

  OnboardingPageData({
    this.lottieAsset,
    this.iconData,
    required this.titleKey,
    required this.subtitleKey,
    required this.emoji,
  });

  String get localizedTitle => titleKey.tr;
  String get localizedSubtitle => subtitleKey.tr;
}

class OnboardingDataFactory {
  static OnboardingPageData getPageData(OnboardingStep step) {
    switch (step) {
      case OnboardingStep.welcome:
        return OnboardingPageData(
          lottieAsset: ImageAssets.mosqueAnimation,
          titleKey: 'onboarding_title_welcome',
          subtitleKey: 'onboarding_subtitle_welcome',
          emoji: '🕌',
        );
      case OnboardingStep.features:
        return OnboardingPageData(
          lottieAsset: ImageAssets.mosqueAnimation,
          titleKey: 'onboarding_title_features',
          subtitleKey: 'onboarding_subtitle_features',
          emoji: '✅',
        );
      case OnboardingStep.family:
        return OnboardingPageData(
          lottieAsset: ImageAssets.familyPrayingAnimation,
          titleKey: 'onboarding_title_family',
          subtitleKey: 'onboarding_subtitle_family',
          emoji: '👨‍👩‍👧‍👦',
        );
      case OnboardingStep.permissions:
        return OnboardingPageData(
          iconData: Icons.location_on_rounded,
          titleKey: 'onboarding_title_permissions',
          subtitleKey: 'onboarding_subtitle_permissions',
          emoji: '🔐',
        );
      case OnboardingStep.profileSetup:
        return OnboardingPageData(
          iconData: Icons.person_rounded,
          titleKey: 'onboarding_title_profile',
          subtitleKey: 'onboarding_subtitle_profile',
          emoji: '👤',
        );
      case OnboardingStep.complete:
        return OnboardingPageData(
          lottieAsset: ImageAssets.successAnimation,
          titleKey: 'onboarding_title_complete',
          subtitleKey: 'onboarding_subtitle_complete',
          emoji: '🎉',
        );
    }
  }

  static String getButtonText(OnboardingStep step, bool allPermissionsGranted) {
    switch (step) {
      case OnboardingStep.welcome:
        return 'start_journey'.tr;
      case OnboardingStep.features:
      case OnboardingStep.family:
        return 'next'.tr;
      case OnboardingStep.permissions:
        return allPermissionsGranted ? 'next'.tr : 'grant_permissions'.tr;
      case OnboardingStep.profileSetup:
        return 'complete_btn'.tr;
      case OnboardingStep.complete:
        return 'get_started'.tr;
    }
  }
}
