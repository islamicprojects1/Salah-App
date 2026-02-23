import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/core/widgets/app_button.dart' show AppButton;
import 'package:salah/core/widgets/app_text_field.dart';
import 'package:salah/features/auth/controller/auth_controller.dart';

// ─────────────────────────────────────────────
// Google Sign-In Button with proper branding
// ─────────────────────────────────────────────
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

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
          elevation: 1,
          shadowColor: AppColors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            side: BorderSide(color: AppColors.divider.withValues(alpha: 0.6)),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingLG,
          ),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isLoading
                ? SizedBox(
                    key: const ValueKey('loading'),
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  )
                : Row(
                    key: const ValueKey('content'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _GoogleLogo(),
                      const SizedBox(width: AppDimensions.paddingMD),
                      Flexible(
                        child: Text(
                          'continue_with_google'.tr,
                          style: AppFonts.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Minimal Google "G" logo using colored segments
class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Red
    canvas.drawArc(
      rect,
      -0.52,
      1.57,
      true,
      Paint()..color = const Color(0xFFEA4335),
    );
    // Blue
    canvas.drawArc(
      rect,
      1.05,
      1.57,
      true,
      Paint()..color = const Color(0xFF4285F4),
    );
    // Yellow
    canvas.drawArc(
      rect,
      2.62,
      0.79,
      true,
      Paint()..color = const Color(0xFFFBBC05),
    );
    // Green
    canvas.drawArc(
      rect,
      3.40,
      0.82,
      true,
      Paint()..color = const Color(0xFF34A853),
    );

    // White inner circle
    canvas.drawCircle(center, radius * 0.62, Paint()..color = Colors.white);

    // Blue horizontal bar for the "G" notch
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = radius * 0.36
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx, center.dy),
      Offset(center.dx + radius * 0.88, center.dy),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────
// Reusable error banner
// ─────────────────────────────────────────────
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingMD),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMD,
        vertical: AppDimensions.paddingSM,
      ),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 16),
          const SizedBox(width: AppDimensions.paddingXS),
          Expanded(
            child: Text(
              message,
              style: AppFonts.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Email Sign-In Section (Expandable) — kept for legacy use
// ─────────────────────────────────────────────
class EmailSignInSection extends StatefulWidget {
  const EmailSignInSection({super.key, required this.controller});

  final AuthController controller;

  @override
  State<EmailSignInSection> createState() => _EmailSignInSectionState();
}

class _EmailSignInSectionState extends State<EmailSignInSection>
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
                  EmailTextField(
                    controller: widget.controller.emailController,
                    label: 'email_label'.tr,
                  ),
                  const SizedBox(height: AppDimensions.paddingMD),
                  Obx(
                    () => PasswordTextField(
                      controller: widget.controller.passwordController,
                      label: 'password_label'.tr,
                      obscureText: !widget.controller.isPasswordVisible.value,
                      suffixIcon: IconButton(
                        icon: Icon(
                          widget.controller.isPasswordVisible.value
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        onPressed: widget.controller.togglePasswordVisibility,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingLG),
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

/// Decorative translucent circle used in auth screen headers
class AuthDecorCircle extends StatelessWidget {
  final double size;
  final double opacity;
  const AuthDecorCircle({super.key, required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.white.withValues(alpha: opacity * 3),
          width: 1.5,
        ),
        color: AppColors.white.withValues(alpha: opacity),
      ),
    );
  }
}
