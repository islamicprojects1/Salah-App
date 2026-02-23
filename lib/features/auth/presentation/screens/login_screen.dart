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

/// Login screen — header+card layout with email, password, and Google Sign-In
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
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
    final headerHeight = MediaQuery.sizeOf(context).height * 0.32;

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
                    // Gradient background
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary,
                              Color(0xFF1A6B4A),
                              AppColors.primaryDark,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Decorative circles (Islamic-inspired)
                    Positioned(
                      top: -50,
                      right: -50,
                      child: AuthDecorCircle(size: 220, opacity: 0.07),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -40,
                      child: AuthDecorCircle(size: 160, opacity: 0.05),
                    ),
                    Positioned(
                      top: topPadding + 20,
                      left: 30,
                      child: AuthDecorCircle(size: 60, opacity: 0.04),
                    ),
                    // Logo + app name centred
                    Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: topPadding),
                        child: FadeTransition(
                          opacity: _fadeAnim,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildLogo(),
                              const SizedBox(height: 14),
                              Text(
                                'app_name'.tr,
                                style: AppFonts.headlineMedium.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'app_tagline'.tr,
                                style: AppFonts.bodySmall.copyWith(
                                  color: AppColors.white70,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
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
                                'login_title'.tr,
                                style: AppFonts.headlineMedium.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppDimensions.paddingXS),
                              Text(
                                'login_subtitle'.tr,
                                style: AppFonts.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AppDimensions.paddingXL),

                              EmailTextField(
                                controller: controller.emailController,
                                onChanged: (_) => controller.clearError(),
                              ),
                              const SizedBox(height: AppDimensions.paddingMD),

                              Obx(
                                () => PasswordTextField(
                                  controller: controller.passwordController,
                                  textInputAction: TextInputAction.done,
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

                              Obx(
                                () => AppButton.fullWidth(
                                  text: 'login'.tr,
                                  onPressed: () async {
                                    FocusScope.of(context).unfocus();
                                    if (_formKey.currentState?.validate() ??
                                        false) {
                                      final success = await controller
                                          .loginWithEmail();
                                      if (success && context.mounted) {
                                        Get.offAllNamed(AppRoutes.dashboard);
                                      }
                                    }
                                  },
                                  isLoading: controller.isLoading.value,
                                ),
                              ),

                              const SizedBox(height: AppDimensions.paddingLG),
                              _OrDivider(),
                              const SizedBox(height: AppDimensions.paddingLG),

                              Obx(
                                () => GoogleSignInButton(
                                  onPressed: () async {
                                    FocusScope.of(context).unfocus();
                                    final success = await controller
                                        .loginWithGoogle();
                                    if (success && context.mounted) {
                                      if (controller.isNewGoogleUser.value) {
                                        // New user → profile setup
                                        Get.offAllNamed(AppRoutes.profileSetup);
                                      } else {
                                        // Returning user → dashboard
                                        Get.offAllNamed(AppRoutes.dashboard);
                                      }
                                    }
                                  },
                                  isLoading: controller.isGoogleLoading.value,
                                ),
                              ),

                              const SizedBox(height: AppDimensions.paddingXL),

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
                                    onPressed: controller.navigateToRegister,
                                    style: TextButton.styleFrom(
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      'sign_up_now'.tr,
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
        borderRadius: BorderRadius.circular(AppDimensions.radiusXXL),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.3),
          width: 2,
        ),
      ),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(16), // change radius here
        child: Image.asset(
          ImageAssets.appLogo,
          height: AppDimensions.sizeLogo,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) =>
              Icon(Icons.mosque_rounded, size: AppDimensions.iconHero),
        ),
      ),
    );
  }
}

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

