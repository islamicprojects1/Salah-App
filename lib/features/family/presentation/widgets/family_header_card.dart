import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/core/di/injection_container.dart';
import 'package:salah/core/routes/app_routes.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/features/auth/data/services/auth_service.dart';
import 'package:salah/features/family/controller/family_controller.dart';
import 'package:salah/features/family/data/models/family_model.dart';

/// Family header card: name, switcher, notifications, invite code, add child.
class FamilyHeaderCard extends StatelessWidget {
  final FamilyModel family;
  final FamilyController controller;
  final VoidCallback onShowFamilySwitcher;
  final VoidCallback onAddChild;
  final bool hasUnreadPulse;

  const FamilyHeaderCard({
    super.key,
    required this.family,
    required this.controller,
    required this.onShowFamilySwitcher,
    required this.onAddChild,
    this.hasUnreadPulse = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAdmin = family.isAdmin(sl<AuthService>().userId ?? '');

    return Card(
      elevation: AppDimensions.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
      ),
      color: colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMD),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onShowFamilySwitcher,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            family.name,
                            style: AppFonts.titleLarge.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (controller.myFamilies.length > 1) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 20,
                            color: colorScheme.onPrimary.withValues(alpha: 0.8),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.notifications_outlined,
                        color: colorScheme.onPrimary,
                        size: 22,
                      ),
                      onPressed: () => Get.toNamed(AppRoutes.notifications),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                    if (hasUnreadPulse)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 6,
                            minHeight: 6,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingSM),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingSM,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.onPrimary.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusSM),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${'invite_code_label'.tr}: ${family.inviteCode}',
                          style: AppFonts.bodySmall.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () {
                            Share.share(
                              'share_family_invite'.tr.replaceAll(
                                '@code',
                                family.inviteCode,
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.share,
                              color: colorScheme.onPrimary,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isAdmin) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onAddChild,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.onPrimary.withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusSM),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_add_alt_1,
                            color: colorScheme.onPrimary,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'add_child_no_phone_btn'.tr,
                            style: AppFonts.labelMedium.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
