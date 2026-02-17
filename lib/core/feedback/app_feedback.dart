import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:salah/core/feedback/toast_service.dart';
import 'package:salah/core/theme/app_colors.dart';

/// Single entry point for user feedback: toasts and dialogs.
///
/// Use this everywhere instead of Get.snackbar / Get.dialog.
/// - Success/error/info/warning → modern overlay toasts via [ToastService].
/// - Loading and confirmation → dialogs.
class AppFeedback {
  AppFeedback._();

  /// Trigger haptic feedback for success.
  static void hapticSuccess() {
    HapticFeedback.lightImpact();
  }

  /// Show an error toast (overlay-based, theme-aware).
  static void showError(String title, [String? message]) {
    ToastService.error(title, message);
  }

  /// Show a success toast.
  static void showSuccess(String title, [String? message]) {
    ToastService.success(title, message);
  }

  /// Show info or warning toast. [isWarning] true → warning style.
  static void showSnackbar(
    String title, [
    String? message,
    bool isWarning = false,
  ]) {
    if (isWarning) {
      ToastService.warning(title, message);
    } else {
      ToastService.info(title, message);
    }
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
