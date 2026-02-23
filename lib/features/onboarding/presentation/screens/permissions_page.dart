import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/features/onboarding/controller/onboarding_controller.dart';
import 'package:salah/features/onboarding/presentation/widgets/onboarding_widgets.dart';

class PermissionsPage extends GetView<OnboardingController> {
  const PermissionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final data = controller.pageData;

    return OnboardingPageLayout(
      scrollable: true,
      lottieAsset: data.lottieAsset,
      iconData: data.iconData,
      title: data.localizedTitle,
      subtitle: data.localizedSubtitle,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // ── Location card (display only; CTA handles both) ──
              StaggeredFeatureItem(
                index: 0,
                child: Obx(
                  () => _PermissionCard(
                    icon: Icons.location_on_rounded,
                    gradientColors: const [
                      Color(0xFF43CBFF),
                      Color(0xFF9708CC),
                    ],
                    title: 'permission_location_title'.tr,
                    subtitle: 'permission_location_desc'.tr,
                    isGranted: controller.locationPermissionGranted.value,
                    isLoading:
                        controller.isLoading.value &&
                        !controller.locationPermissionGranted.value,
                    onTap: !controller.locationPermissionGranted.value
                        ? controller.requestLocationPermission
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── Notification card (display only) ──
              StaggeredFeatureItem(
                index: 1,
                child: Obx(
                  () => _PermissionCard(
                    icon: Icons.notifications_rounded,
                    gradientColors: const [
                      Color(0xFFFDA085),
                      Color(0xFFF6D365),
                    ],
                    title: 'permission_notification_title'.tr,
                    subtitle: 'permission_notification_desc'.tr,
                    isGranted: controller.notificationPermissionGranted.value,
                    isLoading:
                        controller.isLoading.value &&
                        !controller.notificationPermissionGranted.value,
                    onTap: !controller.notificationPermissionGranted.value
                        ? controller.requestNotificationPermission
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // ── Single CTA: one tap requests both permissions sequentially ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Obx(
            () {
              final allGranted = controller.allPermissionsGranted;
              return OnboardingButton(
                text: controller.buttonText,
                color: allGranted ? AppColors.success : AppColors.primary,
                onTap: allGranted
                    ? controller.nextStep
                    : controller.requestAllPermissionsSequentially,
                icon: allGranted
                    ? Icons.check_circle_rounded
                    : Icons.arrow_forward_rounded,
                isLoading: controller.isLoading.value && !allGranted,
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // ── Skip ──
        Center(
          child: TextButton(
            onPressed: controller.nextStep,
            child: Text(
              'skip_btn'.tr,
              style: AppFonts.bodySmall.copyWith(
                color: AppColors.textSecondary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final IconData icon;
  final List<Color> gradientColors;
  final String title;
  final String subtitle;
  final bool isGranted;
  final bool isLoading;
  final VoidCallback? onTap;

  const _PermissionCard({
    required this.icon,
    required this.gradientColors,
    required this.title,
    required this.subtitle,
    required this.isGranted,
    required this.isLoading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isGranted
              ? AppColors.success.withValues(alpha: 0.4)
              : gradientColors.first.withValues(alpha: 0.25),
          width: isGranted ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isGranted ? AppColors.success : gradientColors.first)
                .withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                // Icon with gradient background
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: isGranted
                        ? LinearGradient(
                            colors: [
                              AppColors.success,
                              AppColors.success.withValues(alpha: 0.7),
                            ],
                          )
                        : LinearGradient(
                            colors: gradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (isGranted
                                    ? AppColors.success
                                    : gradientColors.first)
                                .withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    isGranted ? Icons.check_rounded : icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppFonts.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppFonts.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Action badge
                if (isLoading)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                else if (isGranted)
                  Icon(
                    Icons.verified_rounded,
                    color: AppColors.success,
                    size: 28,
                  )
                else
                  _GrantBadge(gradient: gradientColors),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GrantBadge extends StatelessWidget {
  final List<Color> gradient;
  const _GrantBadge({required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        'grant'.tr,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
