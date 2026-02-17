import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/core/constants/image_assets.dart';
import 'package:salah/core/routes/app_routes.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/core/widgets/app_button.dart';
import 'package:salah/core/constants/enums.dart';

/// Empty state when user has no family.
/// Shows illustration, message, and create/join actions.
class NoFamilyEmptyState extends StatelessWidget {
  const NoFamilyEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingLG),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Lottie.asset(
            ImageAssets.familyPrayingAnimation,
            width: 150,
            height: 150,
          ),
          const SizedBox(height: AppDimensions.paddingXL),
          Text(
            'no_family_yet'.tr,
            style: AppFonts.headlineMedium.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.paddingMD),
          Text(
            'create_or_join_family_desc'.tr,
            style: AppFonts.bodyMedium.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.paddingXL * 2),
          AppButton(
            text: 'create_family'.tr,
            onPressed: () => Get.toNamed(AppRoutes.createFamily),
            icon: Icons.add_circle_outline,
            width: double.infinity,
          ),
          const SizedBox(height: AppDimensions.paddingMD),
          AppButton(
            text: 'join_family'.tr,
            onPressed: () => Get.toNamed(AppRoutes.joinFamily),
            type: AppButtonType.outlined,
            width: double.infinity,
          ),
        ],
      ),
    );
  }
}
