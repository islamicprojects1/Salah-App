import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/core/di/injection_container.dart';
import 'package:salah/core/services/location_service.dart';
import 'package:salah/core/widgets/app_loading.dart';
import 'package:salah/features/prayer/controller/qibla_controller.dart';

class QiblaScreen extends GetView<QiblaController> {
  const QiblaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.primary;
    return Scaffold(
      backgroundColor: bgColor,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const _QiblaLoadingState();
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return _buildErrorState();
        }

        return Semantics(
          label: 'qibla_direction'.tr,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background — theme-aware
              _QiblaBackground(isDark: isDark),

              // Main content
              SafeArea(
                child: Column(
                  children: [
                    _buildTopBar(context),
                    Obx(() {
                      if (!controller.isUsingDefaultLocation.value) {
                        return const SizedBox.shrink();
                      }
                      return _buildMeccaFallbackBanner(context);
                    }),
                    Expanded(child: _buildCompassView(context)),
                    _buildBottomInfo(context),
                  ],
                ),
              ),

              // Accuracy badge
              Positioned(
                top: MediaQuery.of(context).padding.top + 60,
                left: AppDimensions.paddingMD,
                child: Obx(() => _buildAccuracyBadge()),
              ),

              // Calibration overlay
              if (controller.showCalibration.value) _buildCalibrationOverlay(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final onBg = AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: onBg.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: onBg.withValues(alpha: 0.2)),
              ),
              child: Icon(
                Icons.close_rounded,
                color: onBg,
                size: 18,
              ),
            ),
            onPressed: () => Get.back(),
          ),
          Expanded(
            child: Text(
              'qibla_direction'.tr,
              textAlign: TextAlign.center,
              style: AppFonts.titleMedium.copyWith(
                color: onBg,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildMeccaFallbackBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_off_rounded, color: Colors.amber, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'qibla_mecca_notice'.tr,
              style: AppFonts.bodySmall.copyWith(
                color: Colors.amber.shade200,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => sl<LocationService>().openAppSettings(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'grant_permission'.tr,
                style: AppFonts.labelSmall.copyWith(
                  color: Colors.amber.shade100,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final bgColor = Get.isDarkMode ? AppColors.darkBackground : AppColors.primary;
    final onBg = AppColors.textPrimary;
    return Container(
      color: bgColor,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingXL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_off_outlined,
                    size: 56,
                    color: AppColors.error.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingLG),
                Text(
                  controller.errorMessage.value,
                  style: AppFonts.bodyMedium.copyWith(
                    color: onBg.withValues(alpha: 0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.paddingLG),
                ElevatedButton.icon(
                  onPressed: () => controller.refreshQibla(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text('retry'.tr),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.primaryDark,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMD,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompassView(BuildContext context) {
    final onBg = AppColors.textPrimary;
    final onBgMuted = AppColors.textSecondary;
    return Obx(() {
      final qiblaAngle = controller.qiblaDirection.value ?? 0;
      final headingAngle = controller.heading.value ?? 0;
      final isFacing = controller.isFacingQibla.value;
      final needleAngle = (qiblaAngle - headingAngle) * (math.pi / 180);
      final qiblaColor = isFacing ? AppColors.success : AppColors.gold;

      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Facing indicator chip
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: isFacing
                  ? AppColors.success.withValues(alpha: 0.20)
                  : onBg.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isFacing
                    ? AppColors.success.withValues(alpha: 0.50)
                    : onBg.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isFacing
                      ? Icons.check_circle_rounded
                      : Icons.navigation_rounded,
                  size: 16,
                  color: isFacing ? AppColors.success : onBgMuted,
                ),
                const SizedBox(width: 8),
                Text(
                  isFacing ? 'أنت تواجه القبلة' : 'حرّك الجهاز نحو القبلة',
                  style: AppFonts.labelMedium.copyWith(
                    color: isFacing ? AppColors.success : onBgMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Compass
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer decorative ring
              SizedBox(
                width: 300,
                height: 300,
                child: CustomPaint(
                  painter: _OuterRingPainter(
                    isDark: Theme.of(context).brightness == Brightness.dark,
                  ),
                ),
              ),
              // Compass ring
              SizedBox(
                width: 260,
                height: 260,
                child: CustomPaint(
                  painter: _CompassRingPainter(
                    isDark: Theme.of(context).brightness == Brightness.dark,
                  ),
                ),
              ),
              // Cardinal labels
              SizedBox(
                width: 260,
                height: 260,
                child: CustomPaint(
                  painter: _CardinalLabelsPainter(
                    isDark: Theme.of(context).brightness == Brightness.dark,
                  ),
                ),
              ),
              // Needle
              SizedBox(
                width: 160,
                height: 160,
                child: Transform.rotate(
                  angle: needleAngle,
                  child: CustomPaint(
                    painter: _QiblaArrowPainter(
                      color: qiblaColor,
                      isFacing: isFacing,
                      isDark: Theme.of(context).brightness == Brightness.dark,
                    ),
                  ),
                ),
              ),
              // Center gem
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: qiblaColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: qiblaColor.withValues(alpha: 0.6),
                      blurRadius: 14,
                      spreadRadius: 3,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Heading degrees
          Text(
            '${controller.heading.value?.toStringAsFixed(0) ?? "--"}°',
            style: AppFonts.displayLarge.copyWith(
              color: onBg,
              fontWeight: FontWeight.w300,
              letterSpacing: -2,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            controller.locationAndBearing,
            style: AppFonts.bodyMedium.copyWith(
              color: onBgMuted,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildBottomInfo(BuildContext context) {
    return Obx(() {
      if (controller.distanceToKaaba.value <= 0)
        return const SizedBox(height: 32);

      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.textPrimary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mosque_rounded, size: 18, color: AppColors.gold),
              const SizedBox(width: 10),
              Text(
                'المسافة إلى الكعبة',
                style: AppFonts.labelMedium.copyWith(color: AppColors.textSecondary),
              ),
              const Spacer(),
              Text(
                '${controller.distanceToKaaba.value.toStringAsFixed(0)} ${'kilometers'.tr}',
                style: AppFonts.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildAccuracyBadge() {
    final accuracy = controller.compassAccuracy.value;
    if (accuracy == 3) return const SizedBox.shrink();

    final Color color;
    final bool animate;

    switch (accuracy) {
      case 2:
        color = AppColors.warning;
        animate = false;
        break;
      default:
        color = AppColors.error;
        animate = true;
    }

    return GestureDetector(
      onTap: () => controller.showCalibration.value = true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.40)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (animate)
              _PulsingIcon(icon: Icons.priority_high_rounded, color: color)
            else
              Icon(Icons.warning_amber_rounded, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              'compass_accuracy'.tr,
              style: AppFonts.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalibrationOverlay() {
    final accuracy = controller.compassAccuracy.value;

    final String accuracyText;
    final Color accuracyColor;

    switch (accuracy) {
      case 3:
        accuracyText = 'accuracy_high'.tr;
        accuracyColor = AppColors.success;
        break;
      case 2:
        accuracyText = 'accuracy_medium'.tr;
        accuracyColor = AppColors.warning;
        break;
      case 1:
        accuracyText = 'accuracy_low'.tr;
        accuracyColor = AppColors.warning;
        break;
      default:
        accuracyText = 'accuracy_unreliable'.tr;
        accuracyColor = AppColors.error;
    }

    return Container(
      color: Colors.black.withValues(alpha: 0.92),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingXL),
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.topEnd,
                child: IconButton(
                  onPressed: () => controller.showCalibration.value = false,
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.paddingLG),
              Text(
                'improve_accuracy'.tr,
                style: AppFonts.headlineMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.4),
                    width: 2,
                  ),
                  gradient: RadialGradient(
                    colors: [
                      AppColors.gold.withValues(alpha: 0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: AnimatedRotation(
                  turns: 1,
                  duration: const Duration(seconds: 2),
                  child: Icon(
                    Icons.sync_rounded,
                    size: 80,
                    color: AppColors.gold,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.paddingXL),
              Text(
                'calibration_instruction'.tr,
                style: AppFonts.bodyLarge.copyWith(
                  color: Colors.white.withValues(alpha: 0.80),
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingLG),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: accuracyColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'compass_accuracy'.tr,
                      style: AppFonts.bodyMedium.copyWith(
                        color: Colors.white60,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      accuracyText,
                      style: AppFonts.titleSmall.copyWith(
                        color: accuracyColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.paddingXL),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => controller.showCalibration.value = false,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.primaryDark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMD,
                      ),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'done'.tr,
                    style: AppFonts.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────

class _QiblaLoadingState extends StatelessWidget {
  const _QiblaLoadingState();

  @override
  Widget build(BuildContext context) {
    final bg = Get.isDarkMode ? AppColors.darkBackground : AppColors.primary;
    return Container(color: bg, child: const AppLoading());
  }
}

class _QiblaBackground extends StatelessWidget {
  final bool isDark;

  const _QiblaBackground({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _BackgroundPainter(isDark: isDark));
  }
}

// ─────────────────────────────────────────────
// Custom Painters
// ─────────────────────────────────────────────

class _BackgroundPainter extends CustomPainter {
  final bool isDark;

  _BackgroundPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final baseColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final centerPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.1),
        radius: 0.85,
        colors: [
          AppColors.primary.withValues(alpha: isDark ? 0.60 : 0.35),
          baseColor,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), centerPaint);

    final dotColor = isDark ? 0.15 : 0.08;
    final dotPaint = Paint()
      ..color = (isDark ? AppColors.white : AppColors.black).withValues(alpha: dotColor);
    final rng = math.Random(42);
    for (int i = 0; i < 60; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height * 0.5;
      final r = rng.nextDouble() * 1.2 + 0.4;
      canvas.drawCircle(Offset(x, y), r, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

class _OuterRingPainter extends CustomPainter {
  final bool isDark;

  _OuterRingPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeColor = (isDark ? AppColors.white : AppColors.black).withValues(alpha: 0.08);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = strokeColor;

    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(center, radius - 8, paint);

    // Decorative dots on outer ring
    final dotPaint = Paint()..color = AppColors.gold.withValues(alpha: 0.35);
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45 - 90) * math.pi / 180;
      final x = center.dx + (radius - 4) * math.cos(angle);
      final y = center.dy + (radius - 4) * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _OuterRingPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

class _CompassRingPainter extends CustomPainter {
  final bool isDark;

  _CompassRingPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final onBg = (isDark ? AppColors.white : AppColors.black);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = onBg.withValues(alpha: 0.12);
    canvas.drawCircle(center, radius, trackPaint);

    for (int i = 0; i < 360; i += 5) {
      final angle = (i - 90) * math.pi / 180;
      final isCardinal = i % 90 == 0;
      final isMajor = i % 30 == 0;
      final tickLength = isCardinal ? 16.0 : (isMajor ? 9.0 : 4.0);

      final start = Offset(
        center.dx + (radius - tickLength) * math.cos(angle),
        center.dy + (radius - tickLength) * math.sin(angle),
      );
      final end = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      final tickPaint = Paint()
        ..strokeWidth = isCardinal ? 2.5 : (isMajor ? 1.5 : 0.8)
        ..color = isCardinal
            ? AppColors.gold.withValues(alpha: 0.70)
            : onBg.withValues(alpha: isMajor ? 0.25 : 0.12)
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(start, end, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CompassRingPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

class _CardinalLabelsPainter extends CustomPainter {
  final bool isDark;

  _CardinalLabelsPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 30;
    final labels = ['N', 'E', 'S', 'W'];
    final onBgMuted = (isDark ? AppColors.white : AppColors.black).withValues(alpha: 0.40);

    for (int i = 0; i < 4; i++) {
      final angle = (i * 90 - 90) * math.pi / 180;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: i == 0
                ? AppColors.gold.withValues(alpha: 0.90)
                : onBgMuted,
            fontSize: i == 0 ? 13 : 11,
            fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w400,
            fontFamily: 'Cairo',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CardinalLabelsPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

class _QiblaArrowPainter extends CustomPainter {
  final Color color;
  final bool isFacing;
  final bool isDark;

  const _QiblaArrowPainter({
    required this.color,
    required this.isFacing,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Arrow head (pointing up)
    final arrowPath = Path()
      ..moveTo(cx, 0)
      ..lineTo(cx + 14, cy * 0.55)
      ..lineTo(cx + 5, cy * 0.45)
      ..lineTo(cx + 5, cy)
      ..lineTo(cx - 5, cy)
      ..lineTo(cx - 5, cy * 0.45)
      ..lineTo(cx - 14, cy * 0.55)
      ..close();

    // Tail
    final tailPath = Path()
      ..moveTo(cx - 5, cy)
      ..lineTo(cx - 10, size.height)
      ..lineTo(cx + 10, size.height)
      ..lineTo(cx + 5, cy)
      ..close();

    final arrowPaint = Paint()
      ..isAntiAlias = true
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color, color.withValues(alpha: 0.7)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final tailColor = (isDark ? AppColors.white : AppColors.black).withValues(alpha: 0.20);
    final tailPaint = Paint()
      ..color = tailColor
      ..isAntiAlias = true;

    // Glow
    if (isFacing) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawPath(arrowPath, glowPaint);
    }

    canvas.drawShadow(arrowPath, Colors.black.withValues(alpha: 0.40), 6, true);
    canvas.drawPath(tailPath, tailPaint);
    canvas.drawPath(arrowPath, arrowPaint);

    // Mosque icon at tip (small dot)
    final tipColor = isDark ? AppColors.white : AppColors.black;
    final tipPaint = Paint()..color = tipColor;
    canvas.drawCircle(Offset(cx, 6), 3, tipPaint);
  }

  @override
  bool shouldRepaint(covariant _QiblaArrowPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.isFacing != isFacing ||
      oldDelegate.isDark != isDark;
}

// ─────────────────────────────────────────────
// Pulsing icon (same as before, kept here)
// ─────────────────────────────────────────────

class _PulsingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  const _PulsingIcon({required this.icon, required this.color});

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 0.85,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Icon(widget.icon, color: widget.color, size: 16),
    );
  }
}
