import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/core/routes/app_routes.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/features/prayer/controller/dashboard_controller.dart';
import 'package:salah/features/prayer/presentation/screens/qibla_screen.dart';

class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DashboardAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    return Obx(() {
      final isDefaultLocation =
          controller.currentCity.value == 'makkah_fallback_label'.tr;
      return AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        bottom: isDefaultLocation
            ? PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  color: AppColors.error.withValues(alpha: 0.2),
                  height: 1,
                ),
              )
            : null,
        leading: IconButton(
          icon: Icon(Icons.menu, color: AppColors.textPrimary),
          onPressed: () => controller.scaffoldKey.currentState?.openDrawer(),
        ),
        title: InkWell(
          onTap: () => Get.toNamed(AppRoutes.selectCity),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(
                () => Icon(
                  controller.currentCity.value == 'makkah_fallback_label'.tr
                      ? Icons.location_off_outlined
                      : Icons.edit_location_outlined,
                  size: AppDimensions.iconMD,
                  color:
                      controller.currentCity.value == 'makkah_fallback_label'.tr
                      ? AppColors.error
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingXS),
              Flexible(
                child: Obx(
                  () => Text(
                    controller.currentCity.value.split(',').first,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: AppFonts.titleMedium.copyWith(
                      color:
                          controller.currentCity.value ==
                              'makkah_fallback_label'.tr
                          ? AppColors.error
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.explore_outlined, color: AppColors.textPrimary),
            onPressed: () => Get.to(
              () => const QiblaScreen(),
              transition: Transition.downToUp,
              fullscreenDialog: true,
            ),
            tooltip: 'qibla'.tr,
          ),
        ],
      );
    });
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
