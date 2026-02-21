import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/helpers/image_helper.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/features/settings/controller/settings_controller.dart';

/// Profile header card for settings screen
class SettingsProfileSection extends StatelessWidget {
  const SettingsProfileSection({
    super.key,
    required this.controller,
  });

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = controller.userModel.value;
      final authUser = controller.currentUser.value;

      if (user == null && authUser == null) return const SizedBox();

      final displayName = user?.name ?? authUser?.displayName ?? 'guest'.tr;
      final photoUrl = user?.photoUrl ?? authUser?.photoURL;
      final email = user?.email ?? authUser?.email;
      final colorScheme = Theme.of(context).colorScheme;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                GestureDetector(
                  onTap: controller.updateProfilePhoto,
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage: ImageHelper.getImageProvider(photoUrl),
                    child: photoUrl == null
                        ? const Icon(
                            Icons.person,
                            size: 32,
                            color: AppColors.primary,
                          )
                        : null,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: controller.updateProfilePhoto,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: 14,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: AppFonts.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () =>
                            _showEditNameDialog(context, displayName),
                        splashRadius: 20,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                      ),
                    ],
                  ),
                  if (email != null)
                    Text(
                      email,
                      style: AppFonts.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  void _showEditNameDialog(BuildContext context, String? currentName) {
    final nameController = TextEditingController(text: currentName);
    Get.dialog(
      AlertDialog(
        title: Text('edit_profile'.tr),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'name'.tr,
            hintText: 'enter_your_name'.tr,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                controller.updateDisplayName(nameController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text('save'.tr),
          ),
        ],
      ),
    );
  }
}
