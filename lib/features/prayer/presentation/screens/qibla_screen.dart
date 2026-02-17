import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/core/widgets/app_loading.dart';
import 'package:salah/features/prayer/controller/qibla_controller.dart';

class QiblaScreen extends GetView<QiblaController> {
  const QiblaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        actions: [],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const AppLoading();
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return _buildErrorState();
        }

        return Semantics(
          label: 'qibla_direction'.tr,
          child: Stack(
            alignment: Alignment
                .topCenter, // Align non-positioned children to Top Center
            children: [
              _buildCompassView(), // This takes full width and starts from top
              // Top Left Accuracy Indicator (Floating)
              Positioned(
                top:
                    AppDimensions.paddingXL +
                    20, // Push down to avoid status bar/notch overlap cleanly
                right: AppDimensions.paddingMD, // Moved to Right side
                child: _buildAccuracyBadge(),
              ),
              // Bottom Center Distance Pill (Floating)
              if (controller.distanceToKaaba.value > 0)
                Positioned(
                  bottom: AppDimensions.paddingXL * 2, // More space from bottom
                  left: 0,
                  right: 0,
                  child: Center(child: _buildDistancePill()),
                ),
              if (controller.showCalibration.value) _buildCalibrationOverlay(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_outlined,
              size: 80,
              color: AppColors.error.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppDimensions.paddingLG),
            Text(
              controller.errorMessage.value,
              style: AppFonts.bodyMedium.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.paddingLG),
            ElevatedButton.icon(
              onPressed: () => controller.refreshQibla(),
              icon: const Icon(Icons.refresh),
              label: Text('retry'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalibrationOverlay() {
    final accuracy = controller.compassAccuracy.value;
    String accuracyText;
    Color accuracyColor;

    switch (accuracy) {
      case 3:
        accuracyText = 'accuracy_high'.tr;
        accuracyColor = AppColors.success;
        break;
      case 2:
        accuracyText = 'accuracy_medium'.tr;
        accuracyColor = AppColors.success;
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
      color: Colors.black.withValues(alpha: 0.9),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingXL),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  onPressed: () => controller.showCalibration.value = false,
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                ),
              ),

              const SizedBox(height: AppDimensions.paddingXL),

              Text(
                'improve_accuracy'.tr,
                style: AppFonts.headlineSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const Spacer(),

              // Figure 8 animation placeholder
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 3),
                ),
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 2 * math.pi),
                    duration: const Duration(seconds: 2),
                    builder: (context, value, child) {
                      return Transform.rotate(
                        angle: value,
                        child: Icon(
                          Icons.sync,
                          size: 80,
                          color: AppColors.success,
                        ),
                      );
                    },
                    onEnd: () {},
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.paddingXL),

              Text(
                'calibration_instruction'.tr,
                style: AppFonts.bodyLarge.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Accuracy indicator
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingLG),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: accuracyColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'compass_accuracy'.tr,
                          style: AppFonts.bodyMedium.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      accuracyText,
                      style: AppFonts.titleLarge.copyWith(
                        color: accuracyColor,
                        fontWeight: FontWeight.bold,
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
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMD,
                      ),
                    ),
                  ),
                  child: Text(
                    'close'.tr,
                    style: AppFonts.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.paddingLG),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompassView() {
    final heading = controller.heading.value ?? 0;
    final qibla = controller.qiblaDirection.value ?? 0;

    // Qibla angle relative to phone (for external Kaaba indicator)
    final qiblaAngle = (qibla - heading) * (math.pi / 180.0);

    // Use controller's hysteresis-based facing state (smoother, no flickering)
    final isFacingQibla = controller.isFacingQibla.value;

    // Haptic only when first entering Qibla zone
    // (handled by controller state change, not here)

    // Compass size - smaller to fit screen with Kaaba
    const compassSize = 250.0;
    const kaabaOrbitRadius = compassSize / 2 + 35; // Kaaba closer to compass

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.paddingHuge,
        ),
        child: SizedBox(
          width: double.infinity, // Force full width for horizontal centering
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start, // Align to top
            crossAxisAlignment:
                CrossAxisAlignment.center, // Center horizontally
            children: [
              const SizedBox(
                height: AppDimensions.paddingHuge,
              ), // Initial Top space
              // Compass container with external Kaaba
              SizedBox(
                width: compassSize + 90,
                height: compassSize + 90,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Main compass circle
                    Container(
                      width: compassSize,
                      height: compassSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surface,
                        boxShadow: [
                          BoxShadow(
                            color: isFacingQibla
                                ? AppColors.success.withValues(alpha: 0.4)
                                : Colors.black.withValues(alpha: 0.1),
                            blurRadius: isFacingQibla ? 25 : 12,
                            spreadRadius: isFacingQibla ? 8 : 0,
                          ),
                        ],
                        border: Border.all(
                          color: isFacingQibla
                              ? AppColors.success
                              : AppColors.primary,
                          width: isFacingQibla ? 3 : 0,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Compass ring with tick marks
                          CustomPaint(
                            size: Size(compassSize - 20, compassSize - 20),
                            painter: _CompassRingPainter(),
                          ),

                          // Phone direction - prettier arrow with gradient
                          Transform.rotate(
                            angle: -qiblaAngle,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Realistic Arrow
                                CustomPaint(
                                  size: const Size(40, 100),
                                  painter: _RealisticArrowPainter(
                                    color: isFacingQibla
                                        ? AppColors.success
                                        : AppColors.secondary,
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
                          ),

                          // Center point
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: AppColors.textPrimary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // EXTERNAL Kaaba indicator - orbits around compass
                    Transform.rotate(
                      angle: qiblaAngle,
                      child: Transform.translate(
                        offset: Offset(0, -kaabaOrbitRadius),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (isFacingQibla
                                            ? AppColors.success
                                            : AppColors.primary)
                                        .withValues(alpha: 0.6),
                                blurRadius: isFacingQibla ? 25 : 15,
                                spreadRadius: isFacingQibla ? 8 : 3,
                              ),
                            ],
                            border: Border.all(
                              color: isFacingQibla
                                  ? AppColors.success
                                  : AppColors.primary,
                              width: 3,
                            ),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/kaaba.png',
                              width: 50,
                              height: 50,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.paddingMD),

              // Current Heading Display (Big Number)
              Obx(
                () => Text(
                  '${controller.heading.value?.toStringAsFixed(0) ?? "--"}°',
                  style: AppFonts.displayLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 8),

              // City and Bearing (e.g. "Amman 160°")
              Text(
                controller.locationAndBearing,
                style: AppFonts.titleLarge.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppDimensions.paddingLG),

              const SizedBox(
                height: AppDimensions.paddingXL * 3,
              ), // Extra space to avoid overlap with bottom pill
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccuracyBadge() {
    final accuracy = controller.compassAccuracy.value;

    // Define styles based on accuracy
    Color color;
    IconData icon;
    bool animate = false;

    switch (accuracy) {
      case 3: // High (Correct)
        // User requested to HIDE it when good. Only show if there is a problem.
        return const SizedBox.shrink(); // Hide if good

      case 2: // Medium
        color = AppColors.warning;
        icon = Icons.warning_amber_rounded;
        break;

      case 0: // Unreliable
      case 1: // Low
      default:
        color = AppColors.error;
        icon = Icons.priority_high_rounded;
        animate = true;
        break;
    }

    return GestureDetector(
      onTap: () => controller.showCalibration.value = true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (animate)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.2),
                duration: const Duration(seconds: 1),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
                onEnd: () {}, // Loop? For now simple pulse
                child: Icon(icon, color: color, size: 20),
              )
            else
              Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              'compass_accuracy'.tr,
              style: AppFonts.labelMedium.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistancePill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.mosque, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            '${controller.distanceToKaaba.value.toStringAsFixed(0)} ${'kilometers'.tr}',
            style: AppFonts.labelLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Compass ring painter
class _CompassRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.divider;

    // Draw tick marks
    for (int i = 0; i < 360; i += 10) {
      final angle = (i - 90) * math.pi / 180;
      final isCardinal = i % 90 == 0;
      final isMajor = i % 30 == 0;
      final tickLength = isCardinal ? 18.0 : (isMajor ? 10.0 : 5.0);

      final start = Offset(
        center.dx + (radius - tickLength) * math.cos(angle),
        center.dy + (radius - tickLength) * math.sin(angle),
      );
      final end = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      paint.strokeWidth = isCardinal ? 3 : (isMajor ? 2 : 1);
      paint.color = isCardinal ? AppColors.primary : AppColors.divider;
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Realistic Arrow Painter
class _RealisticArrowPainter extends CustomPainter {
  final Color color;

  _RealisticArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final path = Path();
    // Arrow Head
    path.moveTo(size.width / 2, 0); // Tip
    path.lineTo(size.width, size.height * 0.4); // Right wing
    path.lineTo(size.width / 2, size.height * 0.25); // Inner notch
    path.lineTo(0, size.height * 0.4); // Left wing
    path.close();

    // Arrow Shaft
    final shaftPath = Path();
    shaftPath.moveTo(size.width / 2 - 4, size.height * 0.25);
    shaftPath.lineTo(size.width / 2 + 4, size.height * 0.25);
    shaftPath.lineTo(size.width / 2 + 4, size.height);
    shaftPath.lineTo(size.width / 2 - 4, size.height);
    shaftPath.close();

    // Gradient for 3D effect
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color,
        color.withValues(alpha: 0.7),
        color.withValues(alpha: 0.4),
      ],
      stops: const [0.0, 0.6, 1.0],
    );

    paint.shader = gradient.createShader(
      Rect.fromLTWH(0, 0, size.width, size.height),
    );

    // Shadow
    final shadowPath = Path.from(path)..addPath(shaftPath, Offset.zero);
    canvas.drawShadow(shadowPath, Colors.black.withValues(alpha: 0.3), 4, true);

    canvas.drawPath(path, paint);
    canvas.drawPath(shaftPath, paint);
  }

  @override
  bool shouldRepaint(covariant _RealisticArrowPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
