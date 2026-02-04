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
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const AppLoading();
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return _buildErrorState();
        }

        return _buildCompassView();
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

  Widget _buildCompassView() {
    final heading = controller.heading.value ?? 0;
    final qibla = controller.qiblaDirection.value ?? 0;
    
    // Final rotation angle: (Qibla - Heading)
    final angle = ((qibla - heading) * (math.pi / 180.0)) * -1;
    
    // Check if facing Qibla (within 5 degrees)
    final angleDiff = ((qibla - heading) % 360).abs();
    final isFacingQibla = angleDiff <= 5 || angleDiff >= 355;
    
    // Trigger haptic feedback when facing Qibla
    if (isFacingQibla) {
      HapticFeedback.mediumImpact();
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLG),
        child: Column(
          children: [
            // Compass Widget
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingXL),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: isFacingQibla 
                        ? AppColors.success.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: isFacingQibla ? 5 : 0,
                  ),
                ],
                border: Border.all(
                  color: isFacingQibla ? AppColors.success : AppColors.primary.withValues(alpha: 0.2),
                  width: isFacingQibla ? 3 : 2,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ring with cardinal directions
                  _buildCompassRing(heading),
                  
                  // Qibla needle
                  Transform.rotate(
                    angle: angle,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Kaaba icon at the top of needle
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.secondary.withValues(alpha: 0.4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.mosque,
                            size: 24,
                            color: Colors.white,
                          ),
                        ),
                        // Needle line
                        Container(
                          width: 3,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.secondary,
                                AppColors.secondary.withValues(alpha: 0.3),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Center point
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppDimensions.paddingXL),
            
            // Facing Qibla indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingLG,
                vertical: AppDimensions.paddingSM,
              ),
              decoration: BoxDecoration(
                color: isFacingQibla ? AppColors.success : Colors.transparent,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isFacingQibla) ...[
                    const Icon(Icons.check_circle, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    isFacingQibla ? 'facing_qibla'.tr : 'qibla_direction'.tr,
                    style: AppFonts.titleMedium.copyWith(
                      color: isFacingQibla ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppDimensions.paddingLG),
            
            // Distance to Kaaba (if available)
            if (controller.distanceToKaaba.value > 0)
              _buildInfoCard(
                icon: Icons.straighten,
                title: 'distance_to_kaaba'.tr,
                value: '${controller.distanceToKaaba.value.toStringAsFixed(0)} ${'kilometers'.tr}',
              ),
            
            const SizedBox(height: AppDimensions.paddingMD),
            
            // Qibla direction degrees
            _buildInfoCard(
              icon: Icons.explore,
              title: 'qibla_direction'.tr,
              value: '${qibla.toStringAsFixed(1)}°',
            ),
            
            const SizedBox(height: AppDimensions.paddingXL),
            
            // Calibration tip
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingMD),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info, size: 24),
                  const SizedBox(width: AppDimensions.paddingMD),
                  Expanded(
                    child: Text(
                      'calibrate_compass'.tr,
                      style: AppFonts.bodySmall.copyWith(color: AppColors.info),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompassRing(double heading) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Transform.rotate(
        angle: (heading * -1) * (math.pi / 180.0),
        child: CustomPaint(
          painter: _CompassPainter(),
        ),
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
                  style: AppFonts.bodySmall.copyWith(color: AppColors.textSecondary),
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

// Custom painter for compass ring
class _CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.divider;
    
    // Draw outer circle
    canvas.drawCircle(center, radius, paint);
    
    // Draw tick marks
    for (int i = 0; i < 360; i += 30) {
      final angle = i * math.pi / 180;
      final isCardinal = i % 90 == 0;
      final tickLength = isCardinal ? 15.0 : 8.0;
      
      final start = Offset(
        center.dx + (radius - tickLength) * math.sin(angle),
        center.dy - (radius - tickLength) * math.cos(angle),
      );
      final end = Offset(
        center.dx + radius * math.sin(angle),
        center.dy - radius * math.cos(angle),
      );
      
      paint.strokeWidth = isCardinal ? 2 : 1;
      paint.color = isCardinal ? AppColors.primary : AppColors.divider;
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
