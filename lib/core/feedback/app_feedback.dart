import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/theme/app_colors.dart';

/// Global user feedback using GetX.
///
/// Centralizes Get.snackbar and Get.dialog for consistent UX and easy
/// replacement. All controllers and repositories should use this instead
/// of raw Get.snackbar/Get.dialog to respect app theme and i18n.
class AppFeedback {
  AppFeedback._();

  /// Show an error message via GetX snackbar.
  /// Use for validation errors, network errors, or any user-facing failure.
  static void showError(String title, [String? message]) {
    Get.snackbar(
      title,
      message ?? '',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.error.withValues(alpha: 0.95),
      colorText: AppColors.white,
      icon: Icon(Icons.error_outline, color: AppColors.white, size: 28),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 4),
    );
  }

  /// Show a success message via GetX snackbar.
  static void showSuccess(String title, [String? message]) {
    Get.snackbar(
      title,
      message ?? '',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primary.withValues(alpha: 0.95),
      colorText: AppColors.white,
      icon: Icon(Icons.check_circle_outline, color: AppColors.white, size: 28),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    );
  }

  /// Show a neutral snackbar (info/warning).
  static void showSnackbar(
    String title, [
    String? message,
    bool isWarning = false,
  ]) {
    Get.snackbar(
      title,
      message ?? '',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isWarning
          ? AppColors.orange.withValues(alpha: 0.95)
          : AppColors.textSecondary.withValues(alpha: 0.95),
      colorText: AppColors.white,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    );
  }

  /// Show a loading dialog. Call [hideLoading] to close.
  static void showLoading([String? message]) {
    final msg = message ?? 'loading'.tr;
    Get.dialog(
      PopScope(
        canPop: false,
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(msg),
                ],
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Hide the current dialog (e.g. loading).
  static void hideLoading() {
    if (Get.isDialogOpen ?? false) Get.back();
  }

  /// Show a confirmation dialog. Returns true if user confirmed.
  static Future<bool> confirm({
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    bool isDestructive = false,
  }) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(cancelText ?? 'cancel'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(
              confirmText ?? 'confirm'.tr,
              style: isDestructive
                  ? TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                    )
                  : null,
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    return result ?? false;
  }
}
