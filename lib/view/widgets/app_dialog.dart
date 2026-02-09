import 'package:flutter/material.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_colors.dart';

/// App dialog widget with consistent styling
class AppDialog extends StatelessWidget {
  final String? title;
  final String? message;
  final Widget? content;
  final List<Widget>? actions;
  final bool barrierDismissible;

  const AppDialog({
    super.key,
    this.title,
    this.message,
    this.content,
    this.actions,
    this.barrierDismissible = true,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
      ),
      title: title != null
          ? Text(
              title!,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            )
          : null,
      content:
          content ??
          (message != null
              ? Text(
                  message!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                )
              : null),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.only(
        bottom: AppDimensions.paddingMD,
        left: AppDimensions.paddingMD,
        right: AppDimensions.paddingMD,
      ),
      actions: actions,
    );
  }

  /// Show dialog helper
  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    String? message,
    Widget? content,
    List<Widget>? actions,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => AppDialog(
        title: title,
        message: message,
        content: content,
        actions: actions,
        barrierDismissible: barrierDismissible,
      ),
    );
  }

  /// Confirmation dialog
  static Future<bool?> confirm({
    required BuildContext context,
    required String title,
    String? message,
    String confirmText = 'تأكيد',
    String cancelText = 'إلغاء',
    Color? confirmColor,
  }) {
    return show<bool>(
      context: context,
      title: title,
      message: message,
      barrierDismissible: false,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: confirmColor != null
              ? ElevatedButton.styleFrom(backgroundColor: confirmColor)
              : null,
          child: Text(confirmText),
        ),
      ],
    );
  }

  /// Success dialog
  static Future<void> success({
    required BuildContext context,
    required String title,
    String? message,
    String buttonText = 'حسناً',
  }) {
    return show(
      context: context,
      title: title,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 64),
          if (message != null) ...[
            const SizedBox(height: AppDimensions.paddingMD),
            Text(message, textAlign: TextAlign.center),
          ],
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: Text(buttonText),
        ),
      ],
    );
  }

  /// Error dialog
  static Future<void> error({
    required BuildContext context,
    required String title,
    String? message,
    String buttonText = 'حسناً',
  }) {
    return show(
      context: context,
      title: title,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 64),
          if (message != null) ...[
            const SizedBox(height: AppDimensions.paddingMD),
            Text(message, textAlign: TextAlign.center),
          ],
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: Text(buttonText),
        ),
      ],
    );
  }

  /// Loading dialog (non-dismissible)
  static Future<void> loading({
    required BuildContext context,
    String message = 'جاري التحميل...',
  }) {
    return show(
      context: context,
      barrierDismissible: false,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppDimensions.paddingMD),
          Text(message),
        ],
      ),
    );
  }
}
