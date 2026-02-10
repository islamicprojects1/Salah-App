import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/routes/app_routes.dart';
import 'package:salah/core/services/storage_service.dart';

/// Middleware to handle onboarding navigation logic.
///
/// Ensures that:
/// 1. Users who have completed onboarding cannot access the onboarding screen again.
/// 2. Users who have NOT completed onboarding are redirected to it if they try to access the dashboard.
class OnboardingMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    // Ensure StorageService is initialized
    if (!Get.isRegistered<StorageService>()) {
      return null;
    }

    final storage = Get.find<StorageService>();
    final isCompleted = storage.isOnboardingCompleted();

    // Case 1: Trying to access Onboarding but already completed -> Redirect to Dashboard
    if (route == AppRoutes.onboarding && isCompleted) {
      return const RouteSettings(name: AppRoutes.dashboard);
    }

    // Case 2: Trying to access Dashboard but NOT completed -> Redirect to Onboarding
    // Note: We only guard the dashboard, not other routes like Login/Register which might be part of the flow
    if (route == AppRoutes.dashboard && !isCompleted) {
      return const RouteSettings(name: AppRoutes.onboarding);
    }

    // Allow navigation
    return null;
  }
}
