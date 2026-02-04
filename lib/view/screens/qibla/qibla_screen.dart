import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/controller/qibla_controller.dart';
import 'package:salah/view/widgets/app_loading.dart';

class QiblaScreen extends GetView<QiblaController> {
  const QiblaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'qibla'.tr,
          style: AppFonts.titleLarge.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Obx(
            () => IconButton(
              onPressed: () => controller.showCalibration.value = true,
              icon: Icon(
                Icons.tune,
                color: controller.compassAccuracy.value < 2
                    ? AppColors.warning
                    : AppColors.textSecondary,
              ),
              tooltip: 'calibration'.tr,
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const AppLoading();
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return _buildErrorState();
        }

        return Stack(
          children: [
            _buildCompassView(),
            if (controller.showCalibration.value) _buildCalibrationOverlay(),
          ],
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
        padding: const EdgeInsets.all(AppDimensions.paddingLG),
        child: Column(
          children: [
            const SizedBox(height: AppDimensions.paddingSM),

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
                        width: isFacingQibla ? 4 : 3,
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
                              // Arrow with gradient effect
                              Container(
                                width: 10,
                                height: 85,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      AppColors.secondary,
                                      AppColors.secondary.withValues(
                                        alpha: 0.6,
                                      ),
                                    ],
                                  ),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(5),
                                    topRight: Radius.circular(5),
                                    bottomLeft: Radius.circular(3),
                                    bottomRight: Radius.circular(3),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.secondary.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
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

            const SizedBox(height: AppDimensions.paddingLG),

            // Status message
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingXL,
                vertical: AppDimensions.paddingMD,
              ),
              decoration: BoxDecoration(
                color: isFacingQibla ? AppColors.success : AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                boxShadow: [
                  BoxShadow(
                    color: isFacingQibla
                        ? AppColors.success.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isFacingQibla ? Icons.check_circle : Icons.explore,
                    color: isFacingQibla ? Colors.white : AppColors.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isFacingQibla ? 'facing_qibla'.tr : 'follow_arrow'.tr,
                    style: AppFonts.titleMedium.copyWith(
                      color: isFacingQibla
                          ? Colors.white
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.paddingXL),

            // Distance to Kaaba
            if (controller.distanceToKaaba.value > 0)
              _buildInfoCard(
                icon: Icons.straighten,
                title: 'distance_to_kaaba'.tr,
                value:
                    '${controller.distanceToKaaba.value.toStringAsFixed(0)} ${'kilometers'.tr}',
              ),

            const SizedBox(height: AppDimensions.paddingMD),

            // Compass accuracy
            GestureDetector(
              onTap: () => controller.showCalibration.value = true,
              child: _buildAccuracyCard(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccuracyCard() {
    final accuracy = controller.compassAccuracy.value;
    Color accuracyColor;
    String accuracyText;

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
      padding: const EdgeInsets.all(AppDimensions.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: accuracyColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accuracyColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
            ),
            child: Icon(Icons.sensors, color: accuracyColor),
          ),
          const SizedBox(width: AppDimensions.paddingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'compass_accuracy'.tr,
                  style: AppFonts.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: accuracyColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      accuracyText,
                      style: AppFonts.titleMedium.copyWith(
                        color: accuracyColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_left, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: AppDimensions.paddingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: AppFonts.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
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

// Arrow tip painter for phone direction
class _ArrowTipPainter extends CustomPainter {
  final Color color;

  _ArrowTipPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0) // Top center
      ..lineTo(0, size.height) // Bottom left
      ..lineTo(size.width, size.height) // Bottom right
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
