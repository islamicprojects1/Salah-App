import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../core/constants/image_assets.dart';
import '../../core/constants/app_dimensions.dart';

/// Loading widget with Lottie animation
class AppLoading extends StatelessWidget {
  final double? size;
  final String? message;

  const AppLoading({
    super.key,
    this.size,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final loadingSize = size ?? AppDimensions.iconXXL * 2;
    
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  /// Show as overlay on entire screen
  static Widget overlay({String? message}) {
    return Container(
      color: Colors.black54,
      child: AppLoading(message: message),
    );
  }

  /// Show as small inline loading
  static Widget small() {
    return const AppLoading(size: 40);
  }
}

/// Simple circular loading indicator
class AppLoadingIndicator extends StatelessWidget {
  final double? size;
  final Color? color;

  const AppLoadingIndicator({
    super.key,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size ?? 24,
        height: size ?? 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
