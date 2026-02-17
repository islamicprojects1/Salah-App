import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/constants/image_assets.dart';
import 'package:salah/core/feedback/toast_service.dart';

/// Custom dialog utilities for the app
/// Use these instead of default Flutter/GetX dialogs
class AppDialogs {
  AppDialogs._();

  // ============================================================
  // SIMPLE DIALOG
  // ============================================================

  /// Show a simple dialog with title, message, and actions
  static Future<T?> show<T>({
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool barrierDismissible = true,
    Widget? icon,
  }) async {
    return Get.dialog<T>(
      _AppDialogWidget(
        title: title,
        message: message,
        confirmText: confirmText ?? 'ok'.tr,
        cancelText: cancelText,
        onConfirm: onConfirm,
        onCancel: onCancel,
        icon: icon,
      ),
      barrierDismissible: barrierDismissible,
    );
  }

  // ============================================================
  // CONFIRM DIALOG
  // ============================================================

  /// Show a confirmation dialog
  static Future<bool> confirm({
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    bool isDestructive = false,
  }) async {
    final result = await Get.dialog<bool>(
      _AppDialogWidget(
        title: title,
        message: message,
        confirmText: confirmText ?? 'yes'.tr,
        cancelText: cancelText ?? 'no'.tr,
        isDestructive: isDestructive,
        onConfirm: () => Get.back(result: true),
        onCancel: () => Get.back(result: false),
        icon: Icon(
          isDestructive ? Icons.warning_amber_rounded : Icons.help_outline_rounded,
          color: isDestructive ? AppColors.error : AppColors.primary,
          size: 48,
        ),
      ),
      barrierDismissible: false,
    );
    return result ?? false;
  }

  // ============================================================
  // SUCCESS DIALOG
  // ============================================================

  /// Show a success dialog with Lottie animation
  static Future<void> success({
    required String title,
    String? message,
    String? buttonText,
    VoidCallback? onDismiss,
    bool autoDismiss = true,
    Duration autoDismissDuration = const Duration(seconds: 2),
  }) async {
    Get.dialog(
      _SuccessDialogWidget(
        title: title,
        message: message,
        buttonText: buttonText ?? 'done'.tr,
        onDismiss: onDismiss,
        autoDismiss: autoDismiss,
        autoDismissDuration: autoDismissDuration,
      ),
      barrierDismissible: false,
    );
  }

  // ============================================================
  // LOADING DIALOG
  // ============================================================

  /// Show a loading dialog
  static void showLoading({String? message}) {
    Get.dialog(
      PopScope(
        canPop: false,
        child: _LoadingDialogWidget(message: message ?? 'loading'.tr),
      ),
      barrierDismissible: false,
    );
  }

  /// Hide loading dialog
  static void hideLoading() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }

  // ============================================================
  // ERROR DIALOG
  // ============================================================

  /// Show an error dialog
  static Future<void> error({
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onRetry,
  }) async {
    await Get.dialog(
      _AppDialogWidget(
        title: title,
        message: message,
        confirmText: onRetry != null ? 'retry'.tr : (buttonText ?? 'ok'.tr),
        onConfirm: () {
          Get.back();
          onRetry?.call();
        },
        icon: const Icon(
          Icons.error_outline_rounded,
          color: AppColors.error,
          size: 48,
        ),
      ),
    );
  }

  // ============================================================
  // SNACKBAR / TOAST (delegates to ToastService for consistency)
  // ============================================================

  /// Show a toast. Prefer [AppFeedback.showSuccess] / [AppFeedback.showError] for clarity.
  static void snackbar({
    required String title,
    required String message,
    SnackbarType type = SnackbarType.info,
    Duration duration = const Duration(seconds: 3),
    SnackPosition position = SnackPosition.TOP,
  }) {
    switch (type) {
      case SnackbarType.success:
        ToastService.success(title, message);
        break;
      case SnackbarType.error:
        ToastService.error(title, message);
        break;
      case SnackbarType.warning:
        ToastService.warning(title, message);
        break;
      case SnackbarType.info:
        ToastService.info(title, message);
        break;
    }
  }

  // ============================================================
  // BOTTOM SHEET
  // ============================================================

  /// Show a custom bottom sheet
  static Future<T?> bottomSheet<T>({
    required Widget child,
    String? title,
    bool isDismissible = true,
    bool enableDrag = true,
  }) async {
    return Get.bottomSheet<T>(
      Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusXL),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: AppDimensions.paddingMD),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            if (title != null)
              Padding(
                padding: const EdgeInsets.only(
                  left: AppDimensions.paddingLG,
                  right: AppDimensions.paddingLG,
                  bottom: AppDimensions.paddingMD,
                ),
                child: Text(
                  title,
                  style: AppFonts.titleLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            // Content
            Flexible(child: child),
            // Bottom safe area padding
            SizedBox(height: Get.mediaQuery.padding.bottom + AppDimensions.paddingMD),
          ],
        ),
      ),
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: true,
    );
  }
}

// ============================================================
// DIALOG WIDGETS
// ============================================================

class _AppDialogWidget extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final Widget? icon;
  final bool isDestructive;

  const _AppDialogWidget({
    required this.title,
    required this.message,
    required this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.icon,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            if (icon != null) ...[
              icon!,
              const SizedBox(height: AppDimensions.paddingMD),
            ],

            // Title
            Text(
              title,
              style: AppFonts.titleLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppDimensions.paddingSM),

            // Message
            Text(
              message,
              style: AppFonts.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppDimensions.paddingXL),

            // Buttons
            Row(
              children: [
                // Cancel button
                if (cancelText != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancel ?? () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: BorderSide(color: AppColors.divider),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppDimensions.paddingMD,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                        ),
                      ),
                      child: Text(cancelText!),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingMD),
                ],

                // Confirm button
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm ?? () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDestructive ? AppColors.error : AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimensions.paddingMD,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                      ),
                    ),
                    child: Text(confirmText),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessDialogWidget extends StatefulWidget {
  final String title;
  final String? message;
  final String buttonText;
  final VoidCallback? onDismiss;
  final bool autoDismiss;
  final Duration autoDismissDuration;

  const _SuccessDialogWidget({
    required this.title,
    this.message,
    required this.buttonText,
    this.onDismiss,
    required this.autoDismiss,
    required this.autoDismissDuration,
  });

  @override
  State<_SuccessDialogWidget> createState() => _SuccessDialogWidgetState();
}

class _SuccessDialogWidgetState extends State<_SuccessDialogWidget> {
  @override
  void initState() {
    super.initState();
    if (widget.autoDismiss) {
      Future.delayed(widget.autoDismissDuration, () {
        if (mounted && (Get.isDialogOpen ?? false)) {
          Get.back();
          widget.onDismiss?.call();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success animation
            Lottie.asset(
              ImageAssets.successAnimation,
              width: 120,
              height: 120,
              repeat: false,
            ),

            const SizedBox(height: AppDimensions.paddingMD),

            // Title
            Text(
              widget.title,
              style: AppFonts.titleLarge.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            // Message
            if (widget.message != null) ...[
              const SizedBox(height: AppDimensions.paddingSM),
              Text(
                widget.message!,
                style: AppFonts.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            if (!widget.autoDismiss) ...[
              const SizedBox(height: AppDimensions.paddingXL),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back();
                    widget.onDismiss?.call();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.paddingMD,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                    ),
                  ),
                  child: Text(widget.buttonText),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LoadingDialogWidget extends StatelessWidget {
  final String message;

  const _LoadingDialogWidget({required this.message});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Loading animation
            Lottie.asset(
              ImageAssets.loadingAnimation,
              width: 100,
              height: 100,
            ),

            const SizedBox(height: AppDimensions.paddingMD),

            // Message
            Text(
              message,
              style: AppFonts.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
