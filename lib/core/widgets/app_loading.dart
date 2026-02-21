import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:salah/core/constants/image_assets.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';

/// Full loading widget with Lottie animation + optional message
class AppLoading extends StatelessWidget {
  final double? size;
  final String? message;

  const AppLoading({super.key, this.size, this.message});

  @override
  Widget build(BuildContext context) {
    final loadingSize = size ?? 120.0;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Lottie.asset(
            ImageAssets.loadingAnimation,
            width: loadingSize,
            height: loadingSize,
            fit: BoxFit.contain,
          ),
          if (message != null) ...[
            const SizedBox(height: AppDimensions.paddingMD),
            Text(
              message!,
              style: AppFonts.bodyMedium.withColor(AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  /// Full-screen dark overlay with loading animation
  static Widget overlay({String? message}) {
    return Container(
      color: AppColors.black.withValues(alpha: 0.5),
      child: AppLoading(size: 100, message: message),
    );
  }

  /// Small inline loading (e.g. inside a card or list)
  static Widget inline({double size = 48}) {
    return AppLoading(size: size);
  }
}

/// Lightweight circular progress indicator (for buttons, appbars, etc.)
class AppLoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const AppLoadingIndicator({
    super.key,
    this.size = 24,
    this.color,
    this.strokeWidth = 2.5,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// Shimmer-style skeleton placeholder for list items
class AppSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const AppSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  /// Full-width skeleton line
  const AppSkeleton.line({super.key, this.height = 16, this.borderRadius = 8})
    : width = double.infinity;

  /// Circle skeleton (e.g. avatar)
  const AppSkeleton.circle({super.key, double size = 48})
    : width = size,
      height = size,
      borderRadius = 999;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Opacity(
        opacity: _animation.value,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColors.grey300,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        ),
      ),
    );
  }
}
