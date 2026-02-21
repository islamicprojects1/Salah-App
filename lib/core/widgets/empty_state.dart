import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/core/constants/image_assets.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';

/// Empty / error / no-internet state widget
class EmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? imagePath;
  final IconData? icon;
  final Color? iconColor;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.imagePath,
    this.icon,
    this.iconColor,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Visual
            _buildVisual(context),

            const SizedBox(height: AppDimensions.paddingLG),

            // Title
            Text(
              title,
              style: AppFonts.titleLarge
                  .withColor(AppColors.textPrimary)
                  .copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            // Subtitle
            if (subtitle != null) ...[
              const SizedBox(height: AppDimensions.paddingSM),
              Text(
                subtitle!,
                style: AppFonts.bodyMedium.withColor(AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],

            // Action
            if (action != null) ...[
              const SizedBox(height: AppDimensions.paddingXL),
              action!,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVisual(BuildContext context) {
    if (imagePath != null) {
      return Image.asset(
        imagePath!,
        width: 180,
        height: 180,
        fit: BoxFit.contain,
      );
    }
    if (icon != null) {
      return Container(
        padding: const EdgeInsets.all(AppDimensions.paddingLG),
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: AppDimensions.iconXXL,
          color: iconColor ?? AppColors.primary,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  // ── FACTORIES ──────────────────────────────────────────────────────────────

  /// No prayers logged yet
  factory EmptyState.prayers({Widget? action}) => EmptyState(
    title: 'no_prayers_logged'.tr,
    subtitle: 'log_first_prayer'.tr,
    imagePath: ImageAssets.emptyPrayers,
    action: action,
  );

  /// No family / community yet
  factory EmptyState.community({Widget? action}) => EmptyState(
    title: 'no_groups'.tr,
    subtitle: 'create_or_join_family_btn'.tr,
    imagePath: ImageAssets.emptyCommunity,
    action: action,
  );

  /// No family members
  factory EmptyState.noMembers({Widget? action}) => EmptyState(
    title: 'no_members'.tr,
    subtitle: 'invite_family_hint'.tr,
    icon: Icons.group_add_outlined,
    iconColor: AppColors.primary,
    action: action,
  );

  /// General error
  factory EmptyState.error({String? message, VoidCallback? onRetry}) =>
      EmptyState(
        title: 'error_occurred'.tr,
        subtitle: message ?? 'please_try_again'.tr,
        icon: Icons.error_outline_rounded,
        iconColor: AppColors.error,
        action: onRetry != null ? _RetryButton(onRetry: onRetry) : null,
      );

  /// No internet connection
  factory EmptyState.noInternet({VoidCallback? onRetry}) => EmptyState(
    title: 'no_internet'.tr,
    subtitle: 'check_connection'.tr,
    icon: Icons.wifi_off_rounded,
    iconColor: AppColors.warning,
    action: onRetry != null ? _RetryButton(onRetry: onRetry) : null,
  );

  /// No search results
  factory EmptyState.noResults({String? query}) => EmptyState(
    title: 'no_results'.tr,
    subtitle: query != null
        ? 'no_results_for'.trParams({'query': query})
        : 'try_different_search'.tr,
    icon: Icons.search_off_rounded,
    iconColor: AppColors.textSecondary,
  );

  /// Qada: all prayers are complete
  factory EmptyState.allPrayersDone() => EmptyState(
    title: 'all_prayers_done'.tr,
    subtitle: 'keep_it_up'.tr,
    icon: Icons.check_circle_outline_rounded,
    iconColor: AppColors.success,
  );
}

class _RetryButton extends StatelessWidget {
  final VoidCallback onRetry;

  const _RetryButton({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh_rounded),
      label: Text('retry'.tr),
    );
  }
}
