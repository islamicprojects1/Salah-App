import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/core/constants/image_assets.dart';
import 'package:salah/core/routes/app_routes.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/core/widgets/app_button.dart' show AppButton;
import 'package:salah/core/widgets/app_text_field.dart';
import 'package:salah/features/auth/controller/auth_controller.dart';

/// Login screen with Google as primary sign-in option
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
              const SizedBox(height: AppDimensions.paddingXL * 2),

              // Logo
              Center(
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingLG),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withValues(alpha: 0.1),
                        AppColors.secondary.withValues(alpha: 0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    ImageAssets.appLogo,
                    height: AppDimensions.sizeLogo,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: AppDimensions.sizeLogo,
                        width: AppDimensions.sizeLogo,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.primary, AppColors.primaryLight],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.mosque,
                          size: AppDimensions.iconLogo,
                          color: AppColors.white,
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.paddingXL),

              // Title
              Text(
                'welcome_title'.tr,
                style: AppFonts.headlineLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppDimensions.paddingSM),

              Text(
                'welcome_subtitle'.tr,
                style: AppFonts.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppDimensions.paddingXL * 2),

              // Error message
              Obx(() {
                if (controller.errorMessage.value.isNotEmpty) {
                  return Container(
                    margin: const EdgeInsets.only(
                      bottom: AppDimensions.paddingMD,
                    ),
                    padding: const EdgeInsets.all(AppDimensions.paddingMD),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMD,
                      ),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: AppDimensions.paddingSM),
                        Expanded(
                          child: Text(
                            controller.errorMessage.value,
                            style: AppFonts.bodySmall.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),

              // Google Sign In (Primary)
              Obx(
                () => _GoogleSignInButton(
                  onPressed: () async {
                    final success = await controller.loginWithGoogle();
                    if (success) {
                      Get.offAllNamed('/dashboard');
                    }
                  },
                  isLoading: controller.isLoading.value,
                ),
              ),

              const SizedBox(height: AppDimensions.paddingMD),

              // Divider
              Row(
                children: [
                  Expanded(
                    child: Divider(color: AppColors.divider, thickness: 1),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingLG,
                    ),
                    child: Text(
                      'or'.tr,
                      style: AppFonts.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: AppColors.divider, thickness: 1),
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.paddingMD),

              // Email Option (Expandable)
              _EmailSignInSection(controller: controller),

              const SizedBox(height: AppDimensions.paddingXL),

              // Register link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'no_account'.tr,
                    style: AppFonts.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Get.toNamed(AppRoutes.register),
                    child: Text(
                      'create_account'.tr,
                      style: AppFonts.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.paddingXL),
            ],
          ),
        ),
      ),
    );
  }
}

/// Google Sign-In Button with proper branding
class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const _GoogleSignInButton({required this.onPressed, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppDimensions.buttonHeightLG + 4,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.black87,
          elevation: 2,
          shadowColor: AppColors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            side: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingLG,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google Icon
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        'G',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.googleRed,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingMD),
                  Text(
                    'continue_with_google'.tr,
                    style: AppFonts.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.black87,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Email Sign-In Section (Expandable)
class _EmailSignInSection extends StatefulWidget {
  final AuthController controller;

  const _EmailSignInSection({required this.controller});

  @override
  State<_EmailSignInSection> createState() => _EmailSignInSectionState();
}

class _EmailSignInSectionState extends State<_EmailSignInSection>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Email toggle button
        TextButton(
          onPressed: _toggleExpand,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.paddingMD,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.email_outlined,
                size: 20,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppDimensions.paddingSM),
              Text(
                'continue_with_email'.tr,
                style: AppFonts.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingSM),
              AnimatedRotation(
                turns: _isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // Expandable email form
        SizeTransition(
          sizeFactor: _expandAnimation,
          child: FadeTransition(
            opacity: _expandAnimation,
            child: Container(
              margin: const EdgeInsets.only(top: AppDimensions.paddingMD),
              padding: const EdgeInsets.all(AppDimensions.paddingLG),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                border: Border.all(
                  color: AppColors.divider.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                children: [
                  // Email field
                  EmailTextField(
                    controller: widget.controller.emailController,
                    label: 'البريد الإلكتروني',
                  ),

                  const SizedBox(height: AppDimensions.paddingMD),

                  // Password field
                  PasswordTextField(
                    controller: widget.controller.passwordController,
                    label: 'كلمة المرور',
                  ),

                  const SizedBox(height: AppDimensions.paddingLG),

                  // Login button
                  Obx(
                    () => AppButton(
                      text: 'login'.tr,
                      onPressed: () async {
                        final success = await widget.controller
                            .loginWithEmail();
                        if (success) {
                          Get.offAllNamed('/dashboard');
                        }
                      },
                      isLoading: widget.controller.isLoading.value,
                      width: double.infinity,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
