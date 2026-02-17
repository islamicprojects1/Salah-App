import 'package:flutter/material.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/core/theme/app_colors.dart';

/// Type of toast for styling and icon.
enum ToastType { success, error, warning, info }

/// Modern, theme-aware toast content widget.
///
/// Used by [ToastService] as overlay content. Single source for all in-app toasts.
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
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _backgroundColor() {
    switch (widget.type) {
      case ToastType.success:
        return AppColors.success;
      case ToastType.error:
        return AppColors.error;
      case ToastType.warning:
        return AppColors.warning;
      case ToastType.info:
        return AppColors.info;
    }
  }

  IconData _icon() {
    switch (widget.type) {
      case ToastType.success:
        return Icons.check_circle_rounded;
      case ToastType.error:
        return Icons.error_rounded;
      case ToastType.warning:
        return Icons.warning_rounded;
      case ToastType.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.of(context).padding;
    return Positioned(
      top: safePadding.top + AppDimensions.paddingMD,
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
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingMD,
                  vertical: AppDimensions.paddingSM,
                ),
                decoration: BoxDecoration(
                  color: _backgroundColor().withValues(alpha: 0.96),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMD),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      _icon(),
                      color: AppColors.white,
                      size: 28,
                    ),
                    const SizedBox(width: AppDimensions.paddingSM),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          if (widget.message != null &&
                              widget.message!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.message!,
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
