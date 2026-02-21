import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/core/constants/image_assets.dart';
import 'package:salah/core/routes/app_routes.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/core/widgets/app_button.dart';
import 'package:salah/core/widgets/app_text_field.dart';
import 'package:salah/features/auth/controller/auth_controller.dart';
import 'package:salah/features/auth/presentation/widgets/login_widgets.dart';

/// Register screen — same header+card layout as Login, with Google Sign-In
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<AuthController>()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed(AppRoutes.login);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final controller = Get.find<AuthController>();
    final topPadding = MediaQuery.paddingOf(context).top;
    final headerHeight = MediaQuery.sizeOf(context).height * 0.28;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // ─── Header ───
              SizedBox(
                height: headerHeight + topPadding,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [AppColors.primary, AppColors.primaryDark],
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: topPadding),
                        child: FadeTransition(
                          opacity: _fadeAnim,
                          child: _buildLogo(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Body card ───
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppDimensions.radiusXXL),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black26,
                            blurRadius: 20,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.fromLTRB(
                          AppDimensions.screenPaddingH(context),
                          AppDimensions.paddingXL,
                          AppDimensions.screenPaddingH(context),
                          MediaQuery.paddingOf(context).bottom +
                              AppDimensions.paddingXL,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'register_title'.tr,
                                style: AppFonts.headlineMedium.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppDimensions.paddingXS),
                              Text(
                                'register_subtitle'.tr,
                                style: AppFonts.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AppDimensions.paddingXL),

                              NameTextField(
                                controller: controller.nameController,
                                onChanged: (_) => controller.clearError(),
                              ),
                              const SizedBox(height: AppDimensions.paddingMD),

                              EmailTextField(
                                controller: controller.emailController,
                                onChanged: (_) => controller.clearError(),
                              ),
                              const SizedBox(height: AppDimensions.paddingMD),

                              // Password with toggle
                              Obx(
                                () => PasswordTextField(
                                  controller: controller.passwordController,
                                  textInputAction: TextInputAction.next,
                                  obscureText:
                                      !controller.isPasswordVisible.value,
                                  onChanged: (_) => controller.clearError(),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      controller.isPasswordVisible.value
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppColors.textSecondary,
                                      size: 20,
                                    ),
                                    onPressed:
                                        controller.togglePasswordVisibility,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppDimensions.paddingMD),

                              // Confirm password with toggle
                              Obx(
                                () => AppTextField(
                                  controller:
                                      controller.confirmPasswordController,
                                  label: 'confirm_password_label'.tr,
                                  obscureText: !controller
                                      .isConfirmPasswordVisible
                                      .value,
                                  prefixIcon: Icons.lock_outlined,
                                  textInputAction: TextInputAction.done,
                                  onChanged: (_) => controller.clearError(),
                                  suffix: IconButton(
                                    icon: Icon(
                                      controller.isConfirmPasswordVisible.value
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppColors.textSecondary,
                                      size: 20,
                                    ),
                                    onPressed: controller
                                        .toggleConfirmPasswordVisibility,
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'enter_password'.tr;
                                    }
                                    if (v !=
                                        controller.passwordController.text) {
                                      return 'passwords_dont_match'.tr;
                                    }
                                    return null;
                                  },
                                ),
                              ),

                              // Error message
                              Obx(() {
                                final msg = controller.errorMessage.value;
                                if (msg.isEmpty) return const SizedBox.shrink();
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(
                                    top: AppDimensions.paddingMD,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppDimensions.paddingMD,
                                    vertical: AppDimensions.paddingSM,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusSM,
                                    ),
                                    border: Border.all(
                                      color: AppColors.error.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: AppColors.error,
                                        size: 16,
                                      ),
                                      const SizedBox(
                                        width: AppDimensions.paddingXS,
                                      ),
                                      Expanded(
                                        child: Text(
                                          msg,
                                          style: AppFonts.bodySmall.copyWith(
                                            color: AppColors.error,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),

                              const SizedBox(height: AppDimensions.paddingLG),

                              // Register button
                              Obx(
                                () => AppButton.fullWidth(
                                  text: 'register'.tr,
                                  onPressed: () async {
                                    FocusScope.of(context).unfocus();
                                    if (_formKey.currentState?.validate() ??
                                        false) {
                                      final success = await controller
                                          .registerWithEmail();
                                      if (success && context.mounted) {
                                        Get.offAllNamed(AppRoutes.profileSetup);
                                      }
                                    }
                                  },
                                  isLoading: controller.isLoading.value,
                                ),
                              ),

                              const SizedBox(height: AppDimensions.paddingLG),
                              _OrDivider(),
                              const SizedBox(height: AppDimensions.paddingLG),

                              // Google Sign-In
                              Obx(
                                () => GoogleSignInButton(
                                  onPressed: () async {
                                    FocusScope.of(context).unfocus();
                                    final success = await controller
                                        .loginWithGoogle();
                                    if (success && context.mounted) {
                                      Get.offAllNamed(AppRoutes.dashboard);
                                    }
                                  },
                                  isLoading: controller.isGoogleLoading.value,
                                ),
                              ),

                              const SizedBox(height: AppDimensions.paddingXL),

                              // Login link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'have_account'.tr,
                                    style: AppFonts.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: controller.navigateToLogin,
                                    style: TextButton.styleFrom(
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      'sign_in_now'.tr,
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
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLG),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Image.asset(
        ImageAssets.appLogo,
        height: AppDimensions.sizeLogo,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, _, _) => Icon(
          Icons.mosque_rounded,
          size: AppDimensions.iconHero,
          color: AppColors.white,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Shared OR Divider
// ─────────────────────────────────────────────
class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingLG,
          ),
          child: Text(
            'or'.tr,
            style: AppFonts.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ),
        Expanded(child: Divider(color: AppColors.divider)),
      ],
    );
  }
}
