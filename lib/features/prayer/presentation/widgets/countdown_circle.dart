import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'dart:math' as math;
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/core/theme/app_colors.dart';

/// Countdown circle widget for prayer times
class CountdownCircle extends StatelessWidget {
  final Duration remainingTime;
  final Duration totalTime;
  final String prayerName;
  final Color? progressColor;
  final Color? backgroundColor;
  final double size;
  final bool showSeconds;

  const CountdownCircle({
    super.key,
    required this.remainingTime,
    required this.totalTime,
    required this.prayerName,
    this.progressColor,
    this.backgroundColor,
    this.size = 200,
    this.showSeconds = true,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalTime.inSeconds > 0
        ? (remainingTime.inSeconds / totalTime.inSeconds).clamp(0.0, 1.0)
        : 0.0;

    final hours = remainingTime.inHours;
    final minutes = remainingTime.inMinutes.remainder(60);
    final seconds = remainingTime.inSeconds.remainder(60);

    final effectiveProgressColor = progressColor ?? AppColors.primary;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          CustomPaint(
            size: Size(size, size),
            painter: _CirclePainter(
              progress: 1.0,
              color:
                  backgroundColor ??
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              strokeWidth: 12,
            ),
          ),

          // Progress circle
          CustomPaint(
            size: Size(size, size),
            painter: _CirclePainter(
              progress: progress,
              color: effectiveProgressColor,
              strokeWidth: 12,
            ),
          ),

          // Content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                prayerName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingSM),
              Text(
                showSeconds
                    ? '${_pad(hours)}:${_pad(minutes)}:${_pad(seconds)}'
                    : '${_pad(hours)}:${_pad(minutes)}',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'remaining'.tr,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _pad(int value) => value.toString().padLeft(2, '0');
}

/// Custom painter for circular progress
class _CirclePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _CirclePainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CirclePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Animated countdown circle that updates every second.
/// Uses [Timer.periodic] instead of recursive Future.delayed for accuracy.
class AnimatedCountdownCircle extends StatefulWidget {
  final DateTime targetTime;
  final String prayerName;
  final Color? progressColor;
  final double size;
  final VoidCallback? onComplete;

  const AnimatedCountdownCircle({
    super.key,
    required this.targetTime,
    required this.prayerName,
    this.progressColor,
    this.size = 200,
    this.onComplete,
  });

  @override
  State<AnimatedCountdownCircle> createState() =>
      _AnimatedCountdownCircleState();
}

class _AnimatedCountdownCircleState extends State<AnimatedCountdownCircle> {
  late Duration _remainingTime;
  late Duration _totalTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _calculateTime();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant AnimatedCountdownCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetTime != widget.targetTime) {
      _timer?.cancel();
      _calculateTime();
      _startTimer();
    }
  }

  void _calculateTime() {
    final now = DateTime.now();
    final remaining = widget.targetTime.difference(now);
    _remainingTime = remaining.isNegative ? Duration.zero : remaining;
    // Total time is from now back to the target — set once and fixed
    _totalTime = _remainingTime;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _timer?.cancel();
        return;
      }

      final now = DateTime.now();
      final remaining = widget.targetTime.difference(now);

      if (remaining.isNegative || remaining == Duration.zero) {
        _timer?.cancel();
        setState(() => _remainingTime = Duration.zero);
        widget.onComplete?.call();
      } else {
        setState(() => _remainingTime = remaining);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CountdownCircle(
      remainingTime: _remainingTime,
      totalTime: _totalTime,
      prayerName: widget.prayerName,
      progressColor: widget.progressColor,
      size: widget.size,
    );
  }
}
