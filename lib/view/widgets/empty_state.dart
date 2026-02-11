import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/image_assets.dart';

/// Empty state widget for when there's no data
class EmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? imagePath;
  final IconData? icon;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.imagePath,
    this.icon,
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
            // Image or Icon
            if (imagePath != null)
              Image.asset(
                imagePath!,
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              )
            else if (icon != null)
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingLG),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: AppDimensions.iconXXL,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),

            const SizedBox(height: AppDimensions.paddingLG),

            // Title
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            // Subtitle
            if (subtitle != null) ...[
              const SizedBox(height: AppDimensions.paddingSM),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // Action button
            if (action != null) ...[
              const SizedBox(height: AppDimensions.paddingXL),
              action!,
            ],
          ],
        ),
      ),
    );
  }

  /// Empty prayers state
  factory EmptyState.prayers({Widget? action}) {
    return EmptyState(
      title: 'no_prayers_logged'.tr,
      subtitle: 'log_first_prayer'.tr,
      imagePath: ImageAssets.emptyPrayers,
      action: action,
    );
  }

  /// Empty community state
  factory EmptyState.community({Widget? action}) {
    return EmptyState(
      title: 'no_groups'.tr,
      subtitle: 'create_or_join_family_btn'.tr,
      imagePath: ImageAssets.emptyCommunity,
      action: action,
    );
  }

  /// Error state
  factory EmptyState.error({String? message, VoidCallback? onRetry}) {
    return EmptyState(
      title: 'error_occurred'.tr,
      subtitle: message ?? 'please_try_again'.tr,
      icon: Icons.error_outline,
      action: onRetry != null
          ? TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text('retry'.tr),
            )
          : null,
    );
  }

  /// No internet state
  factory EmptyState.noInternet({VoidCallback? onRetry}) {
    return EmptyState(
      title: 'no_internet'.tr,
      subtitle: 'check_connection'.tr,
      icon: Icons.wifi_off,
      action: onRetry != null
          ? TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text('retry'.tr),
            )
          : null,
    );
  }
}
