import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:salah/controller/dashboard_controller.dart';
import 'package:salah/core/helpers/prayer_names.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:intl/intl.dart' as intl;
import 'package:salah/core/constants/enums.dart';

class SmartPrayerCircle extends StatefulWidget {
  const SmartPrayerCircle({super.key});

  @override
  State<SmartPrayerCircle> createState() => _SmartPrayerCircleState();
}

class _SmartPrayerCircleState extends State<SmartPrayerCircle>
    with TickerProviderStateMixin {
  late final Ticker _ticker;
  late final AnimationController _pulseController;
  DateTime _currentTime = DateTime.now();
  final DashboardController controller = Get.find<DashboardController>();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      final now = DateTime.now();
      if (now.second != _currentTime.second) {
        setState(() {
          _currentTime = now;
        });
      }
    });
    _ticker.start();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final nextPrayer = controller.nextPrayer.value;
      final currentPrayer = controller.currentPrayer.value;

      // Determine if the current prayer (that has started) is already logged
      bool isLogged = false;
      if (currentPrayer != null) {
        isLogged = PrayerNames.isPrayerLogged(
          controller.todayLogs,
          currentPrayer.name,
          currentPrayer.prayerType,
        );
      }

      final bool isPrayerTime = currentPrayer != null && !isLogged;

      return Center(
        child: GestureDetector(
          onTap: isPrayerTime && !isLogged
              ? () => controller.logPrayer(currentPrayer)
              : null,
          child: SizedBox(
            width: 320,
            height: 320,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. Adaptive Living Background Glow & Depth
                AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface,
                    boxShadow: [
                      // Main Ambient Glow
                      BoxShadow(
                        color: isLogged
                            ? AppColors.success.withValues(alpha: 0.15)
                            : isPrayerTime
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : AppColors.black.withValues(alpha: 0.05),
                        blurRadius: 40,
                        spreadRadius: 2,
                      ),
                      // Subtle depth shadow
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        spreadRadius: -5,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                ),

                // 2. Real Analog Clock Face (Integrative)
                SizedBox(
                  width: 300,
                  height: 300,
                  child: CustomPaint(
                    painter: _RealClockPainter(
                      currentTime: _currentTime,
                      // Adaptive contrast
                      textColor: AppColors.textPrimary,
                      handColor: AppColors.textPrimary,
                      secondHandColor: AppColors.primary,
                    ),
                  ),
                ),

                // 3. Status Info at Cardinal Positions (Top/Bottom)

                // --- TOP (12:00 Position): Time Capsule ---
                Positioned(
                  top: 55,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Text(
                          intl.DateFormat('h:mm a').format(_currentTime),
                          style: AppFonts.labelSmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // --- BOTTOM (6:00 Position): Contextual Info ---
                Positioned(
                  bottom: 50,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isLogged) ...[
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.success,
                                size: 24,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'god_accept_prayers'.tr,
                                style: AppFonts.labelLarge.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'prayer_logged_success'.trParams({
                                  'prayer': currentPrayer?.name ?? '',
                                }),
                                style: AppFonts.labelSmall.copyWith(fontSize: 9),
                              ),
                            ] else if (isPrayerTime) ...[
                              // Pulsing Call to Action
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 1.0, end: 1.2),
                                duration: const Duration(seconds: 1),
                                curve: Curves.easeInOut,
                                builder: (context, value, child) =>
                                    Transform.scale(scale: value, child: child),
                                child: const Icon(
                                  Icons.touch_app_rounded,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'it_is_now'.tr,
                                style: AppFonts.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                currentPrayer.name,
                                style: AppFonts.titleSmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ] else ...[
                              // Next Prayer Info
                              Text(
                                'next_prayer_at'.trParams({
                                  'prayer': nextPrayer?.name ?? '',
                                }),
                                style: AppFonts.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  controller.timeUntilNextPrayer.value,
                                  style: AppFonts.labelMedium.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 4. Progress Arcs
                IgnorePointer(
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _PrayerProgressPainter(
                            currentTime: _currentTime,
                            sunriseTime: controller.todayPrayers.firstWhereOrNull((p) => p.prayerType == PrayerName.sunrise)?.dateTime,
                            nextPrayerTime: nextPrayer?.dateTime,
                            pulseValue: _pulseController.value,
                          ),
                        );
                      }
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _RealClockPainter extends CustomPainter {
  final DateTime currentTime;
  final Color textColor;
  final Color handColor;
  final Color secondHandColor;

  _RealClockPainter({
    required this.currentTime,
    required this.textColor,
    required this.handColor,
    required this.secondHandColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Draw Numbers (12, 1, 2... 11)
    final textPainter = TextPainter(
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
    );

    for (int i = 1; i <= 12; i++) {
      final angle = (i * 30 - 90) * (math.pi / 180);
      final padding = 25.0; // Padding from edge
      final x = center.dx + (radius - padding) * math.cos(angle);
      final y = center.dy + (radius - padding) * math.sin(angle);

      // Highlight 12, 3, 6, 9
      final isMain = i % 3 == 0;

      textPainter.text = TextSpan(
        text: '$i',
        style: AppFonts.bodyMedium.copyWith(
          color: isMain ? textColor : textColor.withValues(alpha: 0.6),
          fontWeight: isMain ? FontWeight.bold : FontWeight.normal,
          fontSize: isMain ? 18 : 14,
        ),
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }

    // 2. Ticks for Minutes (small dots)
    final tickPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..color = textColor.withValues(alpha: 0.2);

    for (int i = 0; i < 60; i++) {
      if (i % 5 != 0) {
        // Don't draw where numbers are
        final angle = (i * 6 - 90) * (math.pi / 180);
        final r1 = radius - 10;

        final x1 = center.dx + r1 * math.cos(angle);
        final y1 = center.dy + r1 * math.sin(angle);

        // Just small dots at the very edge
        canvas.drawCircle(Offset(x1, y1), 1.5, tickPaint);
      }
    }

    // 3. Draw Hands with Drop Shadow for realism

    // Hour
    double hour = currentTime.hour % 12 + currentTime.minute / 60.0;
    double hourAngle = (hour * 30 - 90) * (math.pi / 180);
    _drawDetailedHand(canvas, center, radius * 0.5, hourAngle, handColor, 5.0);

    // Minute
    double minute = currentTime.minute + currentTime.second / 60.0;
    double minuteAngle = (minute * 6 - 90) * (math.pi / 180);
    _drawDetailedHand(
      canvas,
      center,
      radius * 0.75,
      minuteAngle,
      handColor,
      3.0,
    );

    // Second
    double second = currentTime.second.toDouble();
    double secondAngle = (second * 6 - 90) * (math.pi / 180);
    _drawDetailedHand(
      canvas,
      center,
      radius * 0.85,
      secondAngle,
      secondHandColor,
      1.5,
      isSecondHand: true,
    );

    // Center Hub
    final hubPaint = Paint()..color = handColor;
    canvas.drawCircle(center, 5.0, hubPaint);
    canvas.drawCircle(center, 2.0, Paint()..color = secondHandColor);
  }

  void _drawDetailedHand(
    Canvas canvas,
    Offset center,
    double length,
    double angle,
    Color color,
    double width, {
    bool isSecondHand = false,
  }) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;

    // Shadow
    final shadowPaint = Paint()
      ..color = AppColors.black.withValues(alpha: 0.2)
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(ui.BlurStyle.normal, 2);

    final endX = center.dx + length * math.cos(angle);
    final endY = center.dy + length * math.sin(angle);

    // Tail (slight extension opposite to hand)
    final tailLen = isSecondHand ? 20.0 : 10.0;
    final startX = center.dx - tailLen * math.cos(angle);
    final startY = center.dy - tailLen * math.sin(angle);

    // Draw shadow first
    canvas.drawLine(
      Offset(startX + 2, startY + 2),
      Offset(endX + 2, endY + 2),
      shadowPaint,
    );

    // Draw hand
    canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);

    // If second hand, draw a clearly visible circle at the end or near tip?
    // Maybe unnecessary for clean look.
  }

  @override
  bool shouldRepaint(covariant _RealClockPainter oldDelegate) {
    return oldDelegate.currentTime != currentTime;
  }
}

class _PrayerProgressPainter extends CustomPainter {
  final DateTime currentTime;
  final DateTime? sunriseTime;
  final DateTime? nextPrayerTime;
  final double pulseValue;

  _PrayerProgressPainter({
    required this.currentTime,
    this.sunriseTime,
    this.nextPrayerTime,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12; // Slightly inside the edge

    final backgroundPaint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;

    // Draw background ring
    canvas.drawCircle(center, radius, backgroundPaint);

    final rect = Rect.fromCircle(center: center, radius: radius);

    // 1. Elapsed Arc (Sunrise to Current) - SOFT YELLOW GRADIENT
    if (sunriseTime != null) {
      final startAngle = _getTimeAngle(sunriseTime!);
      final endAngle = _getTimeAngle(currentTime);
      
      double sweepAngle = endAngle - startAngle;
      if (sweepAngle < 0) sweepAngle += 2 * math.pi;

      final elapsedPaint = Paint()
        ..shader = ui.Gradient.sweep(
          center,
          [
            AppColors.secondaryLight.withValues(alpha: 0.1),
            AppColors.secondaryLight.withValues(alpha: 0.5),
          ],
          [0.0, 1.0],
          TileMode.clamp,
          startAngle,
          startAngle + sweepAngle,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, sweepAngle, false, elapsedPaint);
    }

    // 2. Remaining Arc (Current to Next Prayer) - VIBRANT GLOW GRADIENT
    if (nextPrayerTime != null) {
      final startAngle = _getTimeAngle(currentTime);
      final endAngle = _getTimeAngle(nextPrayerTime!);
      
      double sweepAngle = endAngle - startAngle;
      if (sweepAngle < 0) sweepAngle += 2 * math.pi;

      // Outer Glow shadow
      final glowPaint = Paint()
        ..color = AppColors.secondary.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);

      final remainingPaint = Paint()
        ..shader = ui.Gradient.sweep(
          center,
          [
            AppColors.secondary.withValues(alpha: 0.8),
            AppColors.secondaryLight,
          ],
          [0.0, 1.0],
          TileMode.clamp,
          startAngle,
          startAngle + sweepAngle,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, sweepAngle, false, remainingPaint);

      // 3. PULSING "NOW" MARKER
      final markerAngle = startAngle;
      final markerCenter = Offset(
        center.dx + radius * math.cos(markerAngle),
        center.dy + radius * math.sin(markerAngle),
      );

      // Neon Pulse
      final pulseRadius = 8.0 + (pulseValue * 12.0);
      final pulsePaint = Paint()
        ..color = AppColors.secondary.withValues(alpha: 0.3 * (1.0 - pulseValue))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(markerCenter, pulseRadius, pulsePaint);

      // Core Dot
      final corePaint = Paint()
        ..color = AppColors.white
        ..style = PaintingStyle.fill
        ..shadowLayer(4, 0, 0, AppColors.secondary);
      canvas.drawCircle(markerCenter, 5, corePaint);
    }
  }

  double _getTimeAngle(DateTime time) {
    double hour = time.hour % 12 + time.minute / 60.0 + time.second / 3600.0;
    return (hour * 30 - 90) * (math.pi / 180);
  }

  @override
  bool shouldRepaint(covariant _PrayerProgressPainter oldDelegate) {
    return oldDelegate.currentTime != currentTime ||
        oldDelegate.sunriseTime != sunriseTime ||
        oldDelegate.nextPrayerTime != nextPrayerTime ||
        oldDelegate.pulseValue != pulseValue;
  }
}

extension PaintExtension on Paint {
  void shadowLayer(double blur, double x, double y, Color color) {
    maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
  }
}
