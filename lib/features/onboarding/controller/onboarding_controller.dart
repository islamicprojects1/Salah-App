import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/services/storage_service.dart';
import 'package:salah/core/services/location_service.dart';
import 'package:salah/core/di/injection_container.dart';
import 'package:salah/features/prayer/data/services/notification_service.dart';
import 'package:salah/features/settings/data/services/localization_service.dart';
import 'package:salah/core/error/app_logger.dart';
import 'package:salah/core/routes/app_routes.dart';
import 'package:salah/features/onboarding/controller/onboarding_data.dart';

/// Controller for the onboarding flow
class OnboardingController extends GetxController
    with GetTickerProviderStateMixin {
  // ============================================================
  // DEPENDENCIES
  // ============================================================
  late final StorageService _storageService;
  late final LocationService _locationService;
  late final NotificationService _notificationService;
  late final LocalizationService _localizationService;

  // ============================================================
  // STATE
  // ============================================================
  final currentPage = 0.obs;
  static const int totalPages = 5;

  final isLoading = false.obs;
  final locationPermissionGranted = false.obs;
  final notificationPermissionGranted = false.obs;

  // Profile form
  final nameController = TextEditingController();
  final name = ''.obs;
  final selectedGender = Rxn<String>();
  final selectedBirthDate = Rxn<DateTime>();

  // ============================================================
  // ANIMATIONS
  // ============================================================
  late AnimationController fadeController;
  late AnimationController slideController;
  late AnimationController bgController;

  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;
  late Animation<double> bgAnimation;

  late PageController pageController;

  // ============================================================
  // DERIVED
  // ============================================================
  OnboardingStep get currentStep => _stepForPage(currentPage.value);

  bool get allPermissionsGranted =>
      locationPermissionGranted.value && notificationPermissionGranted.value;

  bool get isProfileValid =>
      name.value.trim().isNotEmpty && selectedGender.value != null;

  bool get canSkip =>
      currentStep != OnboardingStep.welcome &&
      currentStep != OnboardingStep.complete;

  bool get isFirstPage => currentPage.value == 0;
  bool get isLastPage => currentPage.value == totalPages - 1;

  OnboardingPageData get pageData =>
      OnboardingDataFactory.getPageData(currentStep);

  String get buttonText =>
      OnboardingDataFactory.getButtonText(currentStep, allPermissionsGranted);

  // ============================================================
  // LIFECYCLE
  // ============================================================
  @override
  void onInit() {
    super.onInit();
    _initDependencies();
    _initAnimations();
    nameController.addListener(() => name.value = nameController.text);
    _checkPermissionsStatus();
  }

  void _initDependencies() {
    _storageService = sl<StorageService>();
    _locationService = sl<LocationService>();
    _notificationService = sl<NotificationService>();
    _localizationService = sl<LocalizationService>();
  }

  void _initAnimations() {
    pageController = PageController();

    fadeController = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );
    slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    bgController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    fadeAnimation = CurvedAnimation(
      parent: fadeController,
      curve: Curves.easeInOut,
    );
    slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(parent: slideController, curve: Curves.easeOutCubic),
        );
    bgAnimation = CurvedAnimation(
      parent: bgController,
      curve: Curves.easeInOut,
    );

    // Play entry animations
    _playEntryAnimation();
  }

  Future<void> _playEntryAnimation() async {
    await Future.delayed(const Duration(milliseconds: 100));
    fadeController.forward();
    slideController.forward();
    bgController.forward();
  }

  Future<void> _playTransitionAnimation() async {
    // Fade out
    await Future.wait([fadeController.reverse(), slideController.reverse()]);
    // Fade in
    slideController.reset();
    // Slide from right on forward, left on back
    await Future.wait([fadeController.forward(), slideController.forward()]);
  }

  @override
  void onClose() {
    fadeController.dispose();
    slideController.dispose();
    bgController.dispose();
    pageController.dispose();
    nameController.dispose();
    super.onClose();
  }

  // ============================================================
  // NAVIGATION
  // ============================================================
  Future<void> nextStep() async {
    HapticFeedback.lightImpact();

    if (currentPage.value >= totalPages - 1) {
      await completeOnboarding();
      return;
    }

    // Recheck permissions when moving to permissions page
    if (currentStep == OnboardingStep.family) {
      await _checkPermissionsStatus();
    }

    // Animate out
    await fadeController.reverse();

    currentPage.value++;
    pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );

    // Reset slide direction (from right)
    slideController.reset();

    // Animate in
    await Future.wait([fadeController.forward(), slideController.forward()]);
  }

  Future<void> previousStep() async {
    if (currentPage.value <= 0) return;
    HapticFeedback.lightImpact();

    await fadeController.reverse();

    currentPage.value--;
    pageController.previousPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );

    slideController.reset();
    await Future.wait([fadeController.forward(), slideController.forward()]);
  }

  Future<void> skip() async => completeOnboarding();

  // ============================================================
  // PERMISSIONS
  // ============================================================
  Future<void> _checkPermissionsStatus() async {
    try {
      locationPermissionGranted.value = _locationService.hasLocation;
    } catch (e) {
      AppLogger.debug('Onboarding: check permissions failed', e);
    }
  }

  Future<void> requestLocationPermission() async {
    if (locationPermissionGranted.value) return;
    try {
      isLoading.value = true;
      HapticFeedback.mediumImpact();
      await _locationService.getCurrentLocation();
      locationPermissionGranted.value = _locationService.hasLocation;
      if (locationPermissionGranted.value) HapticFeedback.heavyImpact();
    } catch (e) {
      AppLogger.debug('Onboarding: location permission failed', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> requestNotificationPermission() async {
    if (notificationPermissionGranted.value) return;
    try {
      isLoading.value = true;
      HapticFeedback.mediumImpact();
      notificationPermissionGranted.value = await _notificationService
          .requestPermissions();
      if (notificationPermissionGranted.value) HapticFeedback.heavyImpact();
    } catch (e) {
      AppLogger.debug('Onboarding: notification permission failed', e);
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // LOCALIZATION
  // ============================================================
  Future<void> switchLanguage(String languageCode) async {
    HapticFeedback.selectionClick();
    final language = AppLanguage.fromCode(languageCode);
    await _localizationService.changeLanguage(language);
    update(); // Rebuild to reflect new locale
  }

  // ============================================================
  // PROFILE
  // ============================================================
  void setGender(String gender) {
    HapticFeedback.selectionClick();
    selectedGender.value = gender;
  }

  void setBirthDate(DateTime date) => selectedBirthDate.value = date;

  // ============================================================
  // COMPLETE
  // ============================================================
  Future<void> completeOnboarding() async {
    try {
      isLoading.value = true;
      HapticFeedback.heavyImpact();
      await _storageService.setOnboardingCompleted();
      await _storageService.setNotFirstTime();
      Get.offAllNamed(AppRoutes.login);
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================
  static OnboardingStep _stepForPage(int page) {
    const steps = [
      OnboardingStep.welcome,
      OnboardingStep.features,
      OnboardingStep.family,
      OnboardingStep.permissions,
      OnboardingStep.profileSetup,
    ];
    if (page < 0 || page >= steps.length) return OnboardingStep.welcome;
    return steps[page];
  }
}
