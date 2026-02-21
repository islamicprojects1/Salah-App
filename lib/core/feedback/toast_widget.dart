import 'package:flutter/material.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/core/theme/app_colors.dart';

/// Visual type of the toast — controls colour and icon.
enum ToastType { success, error, warning, info }

/// Animated overlay toast widget.
///
/// Slides in from the top, fades in, and auto-dismisses after [duration].
/// Tapping dismisses it immediately.
///
/// Created and managed exclusively by [ToastService].
class ToastWidget extends StatefulWidget {
  const ToastWidget({
    super.key,
    required this.title,
    this.message,
    required this.type,
    this.duration = const Duration(seconds: 3),
    this.onTap,
  });

  final String title;
  final String? message;
  final ToastType type;
  final Duration duration;
  final VoidCallback? onTap;

  @override
  State<ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _bgColor => switch (widget.type) {
    ToastType.success => AppColors.success,
    ToastType.error => AppColors.error,
    ToastType.warning => AppColors.warning,
    ToastType.info => AppColors.info,
  };

  IconData get _icon => switch (widget.type) {
    ToastType.success => Icons.check_circle_rounded,
    ToastType.error => Icons.error_rounded,
    ToastType.warning => Icons.warning_rounded,
    ToastType.info => Icons.info_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;

    return Positioned(
      top: topPad + AppDimensions.paddingMD,
      left: AppDimensions.paddingMD,
      right: AppDimensions.paddingMD,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: AppDimensions.borderRadiusMD,
              child: _ToastBody(
                icon: _icon,
                bgColor: _bgColor,
                title: widget.title,
                message: widget.message,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Extracted to a private const-constructable widget for better performance.
class _ToastBody extends StatelessWidget {
  const _ToastBody({
    required this.icon,
    required this.bgColor,
    required this.title,
    this.message,
  });

  final IconData icon;
  final Color bgColor;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMD,
        vertical: AppDimensions.paddingSM,
      ),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.96),
        borderRadius: AppDimensions.borderRadiusMD,
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000), // ~15% black
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.white, size: AppDimensions.iconXXL),
          const SizedBox(width: AppDimensions.paddingSM),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                if (message case final String msg when msg.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    msg,
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
