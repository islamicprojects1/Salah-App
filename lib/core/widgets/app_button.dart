import 'package:flutter/material.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'app_loading.dart';

/// Unified app button — primary, outlined, text, destructive
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
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;

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
    this.backgroundColor,
    this.textColor,
    this.borderColor,
  });

  bool get _isEnabled => !isDisabled && !isLoading && onPressed != null;

  Widget _buildContent(Color indicatorColor) {
    if (isLoading) {
      return AppLoadingIndicator(size: 22, color: indicatorColor);
    }
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: AppDimensions.iconMD),
          const SizedBox(width: AppDimensions.paddingSM),
          Text(text),
        ],
      );
    }
    return Text(text);
  }

  @override
  Widget build(BuildContext context) {
    final buttonHeight = height ?? AppDimensions.buttonHeightLG;
    final buttonPadding =
        padding ??
        const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLG);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
    );

    switch (type) {
      // ── PRIMARY ──────────────────────────────────────────────
      case AppButtonType.primary:
        return SizedBox(
          width: width,
          height: buttonHeight,
          child: ElevatedButton(
            onPressed: _isEnabled ? onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor ?? AppColors.primary,
              foregroundColor: textColor ?? AppColors.white,
              disabledBackgroundColor: AppColors.grey300,
              disabledForegroundColor: AppColors.grey500,
              padding: buttonPadding,
              shape: shape,
              textStyle: AppFonts.labelLarge,
              elevation: _isEnabled ? 2 : 0,
            ),
            child: _buildContent(textColor ?? AppColors.white),
          ),
        );

      // ── OUTLINED ─────────────────────────────────────────────
      case AppButtonType.outlined:
        return SizedBox(
          width: width,
          height: buttonHeight,
          child: OutlinedButton(
            onPressed: _isEnabled ? onPressed : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: textColor ?? AppColors.primary,
              disabledForegroundColor: AppColors.grey400,
              side: BorderSide(
                color: _isEnabled
                    ? (borderColor ?? AppColors.primary)
                    : AppColors.grey300,
              ),
              padding: buttonPadding,
              shape: shape,
              textStyle: AppFonts.labelLarge,
            ),
            child: _buildContent(textColor ?? AppColors.primary),
          ),
        );

      // ── TEXT ─────────────────────────────────────────────────
      case AppButtonType.text:
        return TextButton(
          onPressed: _isEnabled ? onPressed : null,
          style: TextButton.styleFrom(
            foregroundColor: textColor ?? AppColors.primary,
            disabledForegroundColor: AppColors.grey400,
            padding:
                padding ??
                const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMD),
            textStyle: AppFonts.labelLarge,
          ),
          child: _buildContent(textColor ?? AppColors.primary),
        );
    }
  }

  // ── FACTORIES ────────────────────────────────────────────────

  /// Full-width primary button
  factory AppButton.fullWidth({
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    bool isDisabled = false,
    IconData? icon,
    Color? backgroundColor,
  }) => AppButton(
    text: text,
    onPressed: onPressed,
    isLoading: isLoading,
    isDisabled: isDisabled,
    icon: icon,
    width: double.infinity,
    backgroundColor: backgroundColor,
  );

  /// Small outlined button (tags, chips, quick actions)
  factory AppButton.small({
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
    Color? color,
  }) => AppButton(
    text: text,
    onPressed: onPressed,
    type: AppButtonType.outlined,
    icon: icon,
    height: AppDimensions.buttonHeightSM,
    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMD),
    textColor: color,
    borderColor: color,
  );

  /// Destructive action (delete, leave family, etc.)
  factory AppButton.destructive({
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
    double? width,
  }) => AppButton(
    text: text,
    onPressed: onPressed,
    isLoading: isLoading,
    icon: icon,
    width: width,
    backgroundColor: AppColors.error,
    textColor: AppColors.white,
  );

  /// Icon-only round button (e.g. encourage in family)
  static Widget iconButton({
    required IconData icon,
    required VoidCallback? onPressed,
    Color? color,
    Color? backgroundColor,
    double size = 40,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor ?? AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: size * 0.5,
            color: color ?? AppColors.primary,
          ),
        ),
      ),
    );
  }
}
