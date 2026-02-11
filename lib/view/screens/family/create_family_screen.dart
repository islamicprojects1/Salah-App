import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/controller/family_controller.dart';
import 'package:salah/view/widgets/app_button.dart';
import 'package:salah/view/widgets/app_text_field.dart';

class CreateFamilyScreen extends GetView<FamilyController> {
  const CreateFamilyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'create_family_title'.tr,
          style: AppFonts.titleLarge.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppDimensions.paddingXL),
            
            // Icon
            Center(
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.paddingXL),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.family_restroom,
                  size: 64, // Using hero size equivalent
                  color: AppColors.primary,
                ),
              ),
            ),
            
            const SizedBox(height: AppDimensions.paddingXL),

            Text(
              'create_family_subtitle'.tr,
              style: AppFonts.headlineMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: AppDimensions.paddingMD),

            Text(
              'create_family_desc'.tr,
              style: AppFonts.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppDimensions.paddingXL * 2),

            // Name Field
            AppTextField(
              controller: controller.familyNameController,
              label: 'family_name_label'.tr,
              hint: 'family_name_hint'.tr,
              prefixIcon: Icons.group_outlined,
            ),

            const Spacer(),

            // Action Button
            Obx(() => AppButton(
              text: 'create_family_btn'.tr,
              onPressed: () => controller.createFamily(),
              isLoading: controller.isLoading,
              width: double.infinity,
            )),
            
            const SizedBox(height: AppDimensions.paddingLG),
          ],
        ),
      ),
    );
  }
}
