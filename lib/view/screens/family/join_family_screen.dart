import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/controller/family_controller.dart';
import 'package:salah/view/widgets/app_button.dart';
import 'package:salah/view/widgets/app_text_field.dart';

class JoinFamilyScreen extends GetView<FamilyController> {
  const JoinFamilyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'join_family_title'.tr,
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
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.connect_without_contact,
                  size: 64,
                  color: AppColors.secondary,
                ),
              ),
            ),
            
            const SizedBox(height: AppDimensions.paddingXL),

            Text(
              'enter_invite_code'.tr,
              style: AppFonts.headlineMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: AppDimensions.paddingMD),

            Text(
              'invite_code_desc'.tr,
              style: AppFonts.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppDimensions.paddingXL * 2),

            // Code Field
            AppTextField(
              controller: controller.inviteCodeController,
              label: 'invite_code_label'.tr,
              hint: 'invite_code_hint'.tr,
              prefixIcon: Icons.vpn_key_outlined,
              maxLength: 6,
              keyboardType: TextInputType.text,
            ),

            const Spacer(),

            // Action Button
            Obx(() => AppButton(
              text: 'join_family_btn'.tr,
              onPressed: () => controller.joinFamily(),
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
