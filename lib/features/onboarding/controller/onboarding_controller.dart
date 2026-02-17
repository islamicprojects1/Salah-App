import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/services/storage_service.dart';
import 'package:salah/core/services/location_service.dart';
import 'package:salah/core/di/injection_container.dart';
import 'package:salah/features/prayer/data/services/notification_service.dart';

/// Controller for premium onboarding experience
class OnboardingController extends GetxController
    with GetTickerProviderStateMixin {
  // ============================================================
  // DEPENDENCIES
  // ============================================================

  late final StorageService _storageService;
  late final LocationService _locationService;
  late final NotificationService _notificationService;

  // ============================================================
  // STATE
  // ============================================================

  final currentStep = OnboardingStep.welcome.obs;
  final currentPage = 0.obs;
  final totalPages = 5.obs;
  final isLoading = false.obs;

  // Permissions state
  final locationPermissionGranted = false.obs;
  final notificationPermissionGranted = false.obs;

  // Profile setup
  final nameController = TextEditingController();
  final selectedGender = Rxn<String>();
  final selectedBirthDate = Rxn<DateTime>();

  // Animation controllers
  late AnimationController fadeController;
  late AnimationController slideController;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;

  // Page controller
  late PageController pageController;

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void onInit() {
    super.onInit();
    _initDependencies();
    _initAnimations();
  }

  void _initDependencies() {
    _storageService = sl<StorageService>();
    _locationService = sl<LocationService>();
    _notificationService = sl<NotificationService>();
  }

  void _initAnimations() {
    pageController = PageController();

    fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: fadeController, curve: Curves.easeIn));

    slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: slideController, curve: Curves.easeOut));

    // Start initial animations
    fadeController.forward();
    slideController.forward();
  }

  @override
  void onClose() {
    fadeController.dispose();
    slideController.dispose();
    pageController.dispose();
    nameController.dispose();
    super.onClose();
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  /// Go to next step
  Future<void> nextStep() async {
    // Animate out
    await fadeController.reverse();

    if (currentPage.value < totalPages.value - 1) {
      currentPage.value++;
      _updateStep();
      pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      await completeOnboarding();
    }

    // Animate in
    await fadeController.forward();
  }

  /// Go to previous step
  Future<void> previousStep() async {
    if (currentPage.value > 0) {
      await fadeController.reverse();
      currentPage.value--;
      _updateStep();
      pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      await fadeController.forward();
    }
  }

  /// Skip onboarding
  Future<void> skip() async {
    await completeOnboarding();
  }

  /// Update current step based on page
  void _updateStep() {
    switch (currentPage.value) {
      case 0:
        currentStep.value = OnboardingStep.welcome;
        break;
      case 1:
        currentStep.value = OnboardingStep.features;
        break;
      case 2:
        currentStep.value = OnboardingStep.family;
        break;
      case 3:
        currentStep.value = OnboardingStep.permissions;
        break;
      case 4:
        currentStep.value = OnboardingStep.profileSetup;
        break;
      case 5:
        currentStep.value = OnboardingStep.complete;
        break;
    }
  }

  // ============================================================
  // PERMISSIONS
  // ============================================================

  /// Request location permission
  Future<void> requestLocationPermission() async {
    try {
      isLoading.value = true;
      // getCurrentLocation handles permission checking internally
      await _locationService.getCurrentLocation();
      locationPermissionGranted.value = _locationService.hasLocation;
    } finally {
      isLoading.value = false;
    }
  }

  /// Request notification permission
  Future<void> requestNotificationPermission() async {
    try {
      isLoading.value = true;
      final granted = await _notificationService.requestPermissions();
      notificationPermissionGranted.value = granted;
    } finally {
      isLoading.value = false;
    }
  }

  /// Check all permissions granted
  bool get allPermissionsGranted =>
      locationPermissionGranted.value && notificationPermissionGranted.value;

  // ============================================================
  // PROFILE SETUP
  // ============================================================

  /// Set gender
  void setGender(String gender) {
    selectedGender.value = gender;
  }

  /// Set birth date
  void setBirthDate(DateTime date) {
    selectedBirthDate.value = date;
  }

  /// Validate profile
  bool get isProfileValid =>
      nameController.text.isNotEmpty && selectedGender.value != null;

  // ============================================================
  // COMPLETION
  // ============================================================

  /// Complete onboarding
  Future<void> completeOnboarding() async {
    try {
      isLoading.value = true;

      // Save onboarding completed
      await _storageService.setOnboardingCompleted();
      await _storageService.setNotFirstTime();

      // Navigate to login/home
      Get.offAllNamed('/login');
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // PAGE CONTENT
  // ============================================================

  /// Get page data for current step
  OnboardingPageData getPageData(OnboardingStep step) {
    switch (step) {
      case OnboardingStep.welcome:
        return OnboardingPageData(
          lottieAsset: 'assets/animations/welcome.json',
          titleKey: 'onboarding_title_welcome',
          subtitleKey: 'onboarding_subtitle_welcome',
          emoji: '🕌',
        );
      case OnboardingStep.features:
        return OnboardingPageData(
          lottieAsset: 'assets/animations/features.json',
          titleKey: 'onboarding_title_features',
          subtitleKey: 'onboarding_subtitle_features',
          emoji: '✅',
        );
      case OnboardingStep.family:
        return OnboardingPageData(
          lottieAsset: 'assets/animations/family.json',
          titleKey: 'onboarding_title_family',
          subtitleKey: 'onboarding_subtitle_family',
          emoji: '👨‍👩‍👧‍👦',
        );
      case OnboardingStep.permissions:
        return OnboardingPageData(
          lottieAsset: 'assets/animations/location.json',
          titleKey: 'onboarding_title_permissions',
          subtitleKey: 'onboarding_subtitle_permissions',
          emoji: '🔐',
        );
      case OnboardingStep.profileSetup:
        return OnboardingPageData(
          lottieAsset: 'assets/animations/profile.json',
          titleKey: 'onboarding_title_profile',
          subtitleKey: 'onboarding_subtitle_profile',
          emoji: '👤',
        );
      case OnboardingStep.complete:
        return OnboardingPageData(
          lottieAsset: 'assets/animations/success.json',
          titleKey: 'onboarding_title_complete',
          subtitleKey: 'onboarding_subtitle_complete',
          emoji: '🎉',
        );
    }
  }

  /// Get button text for current step
  String getButtonText() {
    final step = currentStep.value;

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

  /// Check if can skip current step
  bool get canSkip {
    final step = currentStep.value;
    return step != OnboardingStep.welcome && step != OnboardingStep.complete;
  }
}

/// Data class for onboarding page content
class OnboardingPageData {
  final String lottieAsset;
  final String titleKey;
  final String subtitleKey;
  final String emoji;

  OnboardingPageData({
    required this.lottieAsset,
    required this.titleKey,
    required this.subtitleKey,
    required this.emoji,
  });

  String getLocalizedTitle(String language) => titleKey.tr;
  String getLocalizedSubtitle(String language) => subtitleKey.tr;
}
