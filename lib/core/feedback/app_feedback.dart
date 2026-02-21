import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:salah/core/feedback/toast_service.dart';
import 'package:salah/core/theme/app_colors.dart';

/// Single entry point for all user-facing feedback: toasts, dialogs, and haptics.
///
/// Prefer this over calling [ToastService], [Get.dialog], or [Get.snackbar] directly,
/// so feedback behaviour can be updated in one place.
class AppFeedback {
  const AppFeedback._();

  // ============================================================
  // HAPTICS
  // ============================================================

  static void hapticSuccess() => HapticFeedback.lightImpact();
  static void hapticWarning() => HapticFeedback.mediumImpact();
  static void hapticError() => HapticFeedback.heavyImpact();

  // ============================================================
  // TOASTS
  // ============================================================

  static void showSuccess(String title, [String? message]) =>
      ToastService.success(title, message);

  static void showError(String title, [String? message]) =>
      ToastService.error(title, message);

  static void showWarning(String title, [String? message]) =>
      ToastService.warning(title, message);

  static void showInfo(String title, [String? message]) =>
      ToastService.info(title, message);

  /// Convenience method kept for backward compatibility.
  static void showSnackbar(
    String title, [
    String? message,
    bool isWarning = false,
  ]) => isWarning ? showWarning(title, message) : showInfo(title, message);

  // ============================================================
  // LOADING DIALOG
  // ============================================================

  /// Shows a non-dismissible loading dialog.
  /// Always pair with [hideLoading] once the operation completes.
  static void showLoading([String? message]) {
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
                  Text(message ?? 'loading'.tr),
                ],
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Closes the loading dialog opened by [showLoading].
  static void hideLoading() {
    if (Get.isDialogOpen ?? false) Get.back();
  }

  // ============================================================
  // CONFIRMATION DIALOG
  // ============================================================

  /// Shows a blocking confirmation dialog.
  ///
  /// Returns `true` if the user pressed confirm, `false` if they cancelled
  /// or dismissed the dialog.
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
            style: isDestructive
                ? TextButton.styleFrom(foregroundColor: AppColors.error)
                : null,
            child: Text(
              confirmText ?? 'confirm'.tr,
              style: isDestructive
                  ? const TextStyle(fontWeight: FontWeight.bold)
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
