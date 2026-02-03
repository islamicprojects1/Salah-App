import 'package:flutter/material.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/image_assets.dart';
import '../../core/theme/app_colors.dart';

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
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Subtitle
            if (subtitle != null) ...[
              const SizedBox(height: AppDimensions.paddingSM),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
      title: 'لا توجد صلوات مسجلة',
      subtitle: 'سجّل صلاتك الأولى اليوم',
      imagePath: ImageAssets.emptyPrayers,
      action: action,
    );
  }

  /// Empty community state
  factory EmptyState.community({Widget? action}) {
    return EmptyState(
      title: 'لا توجد مجموعات',
      subtitle: 'أنشئ مجموعة أو انضم لعائلتك',
      imagePath: ImageAssets.emptyCommunity,
      action: action,
    );
  }

  /// Error state
  factory EmptyState.error({
    String? message,
    VoidCallback? onRetry,
  }) {
    return EmptyState(
      title: 'حدث خطأ',
      subtitle: message ?? 'يرجى المحاولة مرة أخرى',
      icon: Icons.error_outline,
      action: onRetry != null
          ? TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            )
          : null,
    );
  }

  /// No internet state
  factory EmptyState.noInternet({VoidCallback? onRetry}) {
    return EmptyState(
      title: 'لا يوجد اتصال بالإنترنت',
      subtitle: 'تحقق من اتصالك وحاول مرة أخرى',
      icon: Icons.wifi_off,
      action: onRetry != null
          ? TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            )
          : null,
    );
  }
}
