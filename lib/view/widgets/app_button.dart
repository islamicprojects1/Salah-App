import 'package:flutter/material.dart';
import 'package:salah/core/constants/app_dimensions.dart';

/// Button types
enum AppButtonType { primary, outlined, text }

/// Custom button widget with multiple types
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.width,
    this.height,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final buttonHeight = height ?? AppDimensions.buttonHeightLG;
    final isEnabled = !isDisabled && !isLoading && onPressed != null;

    Widget content = isLoading
        ? Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  type == AppButtonType.primary
                      ? (Theme.of(context).colorScheme.onPrimary)
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppDimensions.iconMD),
                const SizedBox(width: AppDimensions.paddingSM),
              ],
              Text(
                text,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          );

    switch (type) {
      case AppButtonType.primary:
        return SizedBox(
          width: width,
          height: buttonHeight,
          child: ElevatedButton(
            onPressed: isEnabled ? onPressed : null,
            style: ElevatedButton.styleFrom(
              padding:
                  padding ??
                  const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingLG,
                  ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              ),
            ),
            child: content,
          ),
        );

      case AppButtonType.outlined:
        return SizedBox(
          width: width,
          height: buttonHeight,
          child: OutlinedButton(
            onPressed: isEnabled ? onPressed : null,
            style: OutlinedButton.styleFrom(
              padding:
                  padding ??
                  const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingLG,
                  ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              ),
            ),
            child: content,
          ),
        );

      case AppButtonType.text:
        return TextButton(
          onPressed: isEnabled ? onPressed : null,
          style: TextButton.styleFrom(
            padding:
                padding ??
                const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMD),
          ),
          child: content,
        );
    }
  }

  /// Full width primary button
  factory AppButton.fullWidth({
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
  }) {
    return AppButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      width: double.infinity,
    );
  }

  /// Small outlined button
  factory AppButton.small({
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
  }) {
    return AppButton(
      text: text,
      onPressed: onPressed,
      type: AppButtonType.outlined,
      icon: icon,
      height: AppDimensions.buttonHeightSM,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMD),
    );
  }
}
