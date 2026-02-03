import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/image_assets.dart';
import '../../../controller/auth_controller.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

/// Login screen
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppDimensions.paddingXL),

              // Logo
              Center(
                child: Image.asset(
                  ImageAssets.appIcon,
                  height: AppDimensions.sizeLogo,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: AppDimensions.sizeLogo,
                      width: AppDimensions.sizeLogo,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mosque,
                        size: AppDimensions.iconLogo,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: AppDimensions.paddingLG),

              // Title
              Text(
                'مرحباً بك',
                style: AppFonts.headlineLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppDimensions.paddingSM),

              Text(
                'سجّل دخولك للمتابعة',
                style: AppFonts.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppDimensions.paddingXL * 2),

              // Email field
              EmailTextField(
                controller: controller.emailController,
                label: 'البريد الإلكتروني',
              ),

              const SizedBox(height: AppDimensions.paddingMD),

              // Password field
              PasswordTextField(
                controller: controller.passwordController,
                label: 'كلمة المرور',
              ),

              const SizedBox(height: AppDimensions.paddingXL),

              // Error message
              Obx(() {
                if (controller.errorMessage.value.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppDimensions.paddingMD),
                    child: Text(
                      controller.errorMessage.value,
                      style: AppFonts.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),

              // Login button
              Obx(() => AppButton(
                text: 'تسجيل الدخول',
                onPressed: () async {
                  final success = await controller.loginWithEmail();
                  if (success) {
                    Get.offAllNamed('/dashboard');
                  }
                },
                isLoading: controller.isLoading.value,
                width: double.infinity,
              )),

              const SizedBox(height: AppDimensions.paddingMD),

              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: AppColors.divider)),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingMD,
                    ),
                    child: Text(
                      'أو',
                      style: AppFonts.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: AppColors.divider)),
                ],
              ),

              const SizedBox(height: AppDimensions.paddingMD),

              // Google sign in
              Obx(() => AppButton(
                text: 'المتابعة مع Google',
                onPressed: () async {
                  final success = await controller.loginWithGoogle();
                  if (success) {
                    Get.offAllNamed('/dashboard');
                  }
                },
                type: AppButtonType.outlined,
                isLoading: controller.isLoading.value,
                width: double.infinity,
                icon: Icons.g_mobiledata,
              )),

              const SizedBox(height: AppDimensions.paddingXL),

              // Register link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ليس لديك حساب؟',
                    style: AppFonts.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Get.toNamed('/register'),
                    child: Text(
                      'إنشاء حساب',
                      style: AppFonts.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
