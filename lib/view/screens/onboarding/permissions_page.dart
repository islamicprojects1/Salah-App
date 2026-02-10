import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:salah/controller/onboarding_controller.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/theme/app_colors.dart';

/// Permissions setup page
class PermissionsPage extends GetView<OnboardingController> {
  const PermissionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pageData = controller.getPageData(OnboardingStep.permissions);
    final isArabic = Get.locale?.languageCode == 'ar';

    return SafeArea(
      child: Column(
        children: [
          const Spacer(flex: 1),

          // Animation
          SizedBox(
            height: 200,
            child: Lottie.asset(
              pageData.lottieAsset,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.security_rounded,
                  size: 120,
                  color: AppColors.primary,
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Title
          Text(
            isArabic ? pageData.title : pageData.titleEn,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            isArabic ? pageData.subtitle : pageData.subtitleEn,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),

          const Spacer(flex: 1),

          // Permission Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _buildPermissionCard(
                  icon: Icons.location_on_rounded,
                  title: isArabic ? 'الموقع' : 'Location',
                  subtitle: isArabic
                      ? 'لمعرفة أوقات الصلاة واتجاه القبلة'
                      : 'For prayer times and Qibla direction',
                  isGranted: controller.locationPermissionGranted,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    controller.requestLocationPermission();
                  },
                ),

                const SizedBox(height: 16),

                _buildPermissionCard(
                  icon: Icons.notifications_rounded,
                  title: isArabic ? 'الإشعارات' : 'Notifications',
                  subtitle: isArabic
                      ? 'للتذكير بأوقات الصلاة'
                      : 'For prayer time reminders',
                  isGranted: controller.notificationPermissionGranted,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    controller.requestNotificationPermission();
                  },
                ),
              ],
            ),
          ),

          const Spacer(flex: 2),

          // Continue Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Obx(
              () => _buildContinueButton(
                isArabic: isArabic,
                allGranted: controller.allPermissionsGranted,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Skip for now
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              controller.nextStep();
            },
            child: Text(
              isArabic ? 'تخطي الآن' : 'Skip for now',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required RxBool isGranted,
    required VoidCallback onTap,
  }) {
    return Obx(() {
      final granted = isGranted.value;

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: granted ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: granted
                  ? AppColors.success.withValues(alpha: 0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: granted
                    ? AppColors.success
                    : AppColors.textSecondary.withValues(alpha: 0.2),
                width: granted ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: granted
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: granted ? AppColors.success : AppColors.primary,
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: granted
                      ? Icon(
                          Icons.check_circle,
                          key: const ValueKey('granted'),
                          color: AppColors.success,
                          size: 28,
                        )
                      : Container(
                          key: const ValueKey('request'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            Get.locale?.languageCode == 'ar' ? 'منح' : 'Grant',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildContinueButton({
    required bool isArabic,
    required bool allGranted,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          controller.nextStep();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: allGranted
                  ? [
                      AppColors.success,
                      AppColors.success.withValues(alpha: 0.8),
                    ]
                  : [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.8),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (allGranted ? AppColors.success : AppColors.primary)
                    .withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (allGranted)
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                if (allGranted) const SizedBox(width: 8),
                Text(
                  allGranted
                      ? (isArabic ? 'متابعة' : 'Continue')
                      : (isArabic ? 'التالي' : 'Next'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
