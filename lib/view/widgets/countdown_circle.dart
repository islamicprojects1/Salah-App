import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_colors.dart';

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
        ? remainingTime.inSeconds / totalTime.inSeconds
        : 0.0;

    final hours = remainingTime.inHours;
    final minutes = remainingTime.inMinutes.remainder(60);
    final seconds = remainingTime.inSeconds.remainder(60);

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
              color: backgroundColor ?? 
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              strokeWidth: 12,
            ),
          ),
          
          // Progress circle
          CustomPaint(
            size: Size(size, size),
            painter: _CirclePainter(
              progress: progress.clamp(0.0, 1.0),
              color: progressColor ?? AppColors.primary,
              strokeWidth: 12,
            ),
          ),
          
          // Content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Prayer name
              Text(
                prayerName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              
              const SizedBox(height: AppDimensions.paddingSM),
              
              // Time remaining
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
              
              // Label
              Text(
                'متبقي',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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

    // Draw arc from top (-90 degrees = -π/2)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      2 * math.pi * progress, // Sweep angle
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

/// Animated countdown circle that updates every second
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
  State<AnimatedCountdownCircle> createState() => _AnimatedCountdownCircleState();
}

class _AnimatedCountdownCircleState extends State<AnimatedCountdownCircle> {
  late Duration _remainingTime;
  late Duration _totalTime;

  @override
  void initState() {
    super.initState();
    _calculateTime();
    _startTimer();
  }

  void _calculateTime() {
    final now = DateTime.now();
    _remainingTime = widget.targetTime.difference(now);
    _totalTime = _remainingTime; // Initial total time for progress calculation
    
    if (_remainingTime.isNegative) {
      _remainingTime = Duration.zero;
    }
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      
      final now = DateTime.now();
      final remaining = widget.targetTime.difference(now);
      
      if (remaining.isNegative) {
        setState(() {
          _remainingTime = Duration.zero;
        });
        widget.onComplete?.call();
      } else {
        setState(() {
          _remainingTime = remaining;
        });
        _startTimer();
      }
    });
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
