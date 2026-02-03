import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/controller/qibla_controller.dart';

class QiblaScreen extends GetView<QiblaController> {
  const QiblaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'القبلة',
          style: AppFonts.titleLarge.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Text(
              controller.errorMessage.value,
              style: AppFonts.bodyMedium.copyWith(color: AppColors.error),
            ),
          );
        }

        final heading = controller.heading.value ?? 0;
        final qibla = controller.qiblaDirection.value ?? 0;
        
        // Final rotation angle: (Qibla - Heading)
        final angle = ((qibla - heading) * (math.pi / 180.0)) * -1;

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingXL),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Compass background
                    Transform.rotate(
                      angle: (heading * -1) * (math.pi / 180.0),
                      child: Icon(
                        Icons.explore,
                        size: 250,
                        color: AppColors.primary.withOpacity(0.05),
                      ),
                    ),
                    // Qibla needle
                    Transform.rotate(
                      angle: angle,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.navigation,
                            size: 180,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                    // Center point
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.paddingXL * 2),
              Text(
                'اتجاه القبلة',
                style: AppFonts.headlineSmall.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppDimensions.paddingMD),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingXL),
                child: Text(
                  'ضع الهاتف على سطح مستوِ وحرك الهاتف للمعايرة إذا لزم الأمر',
                  style: AppFonts.bodySmall.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
