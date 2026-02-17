import 'package:flutter/material.dart';
import 'package:salah/core/helpers/image_helper.dart';

/// A member avatar wrapped in a pulsing "synchronicity glow" ring.
///
/// When [isInPrayerWindow] is true, the avatar shows a soft, breathing light
/// ring to indicate this family member's prayer window is currently active.
class SynchronicityAvatar extends StatefulWidget {
  final String? photoUrl;
  final String initial;
  final bool isInPrayerWindow;
  final Color? statusColor;
  final bool showXBadge;
  final double radius;

  const SynchronicityAvatar({
    super.key,
    this.photoUrl,
    required this.initial,
    this.isInPrayerWindow = false,
    this.statusColor,
    this.showXBadge = false,
    this.radius = 24,
  });

  @override
  State<SynchronicityAvatar> createState() => _SynchronicityAvatarState();
}

class _SynchronicityAvatarState extends State<SynchronicityAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (widget.isInPrayerWindow) _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(SynchronicityAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isInPrayerWindow && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isInPrayerWindow && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.value = 0.0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final baseRingColor = widget.statusColor ?? 
        (widget.isInPrayerWindow ? colorScheme.primary : Colors.transparent);

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final isPulsing = widget.isInPrayerWindow;
        final glowAlpha = isPulsing
            ? 0.15 + (_pulseController.value * 0.25)
            : (widget.statusColor != null ? 0.2 : 0.0);
        final ringWidth = isPulsing
            ? 2.5 + (_pulseController.value * 1.5)
            : (widget.statusColor != null ? 3.0 : 0.0);

        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(ringWidth > 0 ? 3 : 0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: ringWidth > 0
                    ? [
                        BoxShadow(
                          color: baseRingColor.withValues(alpha: glowAlpha),
                          blurRadius: isPulsing 
                              ? 12 + (_pulseController.value * 6)
                              : 8,
                          spreadRadius: isPulsing ? 2 : 1,
                        ),
                      ]
                    : null,
                border: ringWidth > 0
                    ? Border.all(
                        color: baseRingColor.withValues(alpha: 0.8),
                        width: ringWidth,
                      )
                    : null,
              ),
              child: child,
            ),
            if (widget.showXBadge)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade700,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.surface, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        );
      },
      child: CircleAvatar(
        radius: widget.radius,
        backgroundImage: ImageHelper.getImageProvider(widget.photoUrl),
        backgroundColor: colorScheme.secondaryContainer,
        child: widget.photoUrl == null
            ? Text(
                widget.initial,
                style: TextStyle(
                  color: colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: widget.radius * 0.7,
                ),
              )
            : null,
      ),
    );
  }
}
