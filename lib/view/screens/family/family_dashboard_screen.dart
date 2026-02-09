import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:share_plus/share_plus.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/core/constants/image_assets.dart';
import 'package:salah/controller/family_controller.dart';
import 'package:salah/core/routes/app_routes.dart';
import 'package:salah/core/helpers/prayer_names.dart';
import 'package:salah/core/services/auth_service.dart';
import 'package:salah/core/services/prayer_time_service.dart';
import 'package:salah/data/models/family_model.dart';
import 'package:salah/view/widgets/app_button.dart';
import 'package:salah/view/widgets/app_loading.dart';

class FamilyDashboardScreen extends GetView<FamilyController> {
  const FamilyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'family'.tr,
          style: AppFonts.titleLarge.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return const AppLoading();
        }

        if (!controller.hasFamily) {
          return _buildNoFamilyView();
        }

        return _buildFamilyView(context);
      }),
    );
  }

  Widget _buildNoFamilyView() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingLG),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Lottie.asset(
            ImageAssets.familyPrayingAnimation,
            width: 150,
            height: 150,
          ),
          const SizedBox(height: AppDimensions.paddingXL),
          Text(
            'no_family_yet'.tr,
            style: AppFonts.headlineMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.paddingMD),
          Text(
            'create_or_join_family_desc'.tr,
            style: AppFonts.bodyMedium.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.paddingXL * 2),
          AppButton(
            text: 'create_family'.tr,
            onPressed: () => Get.toNamed(AppRoutes.createFamily),
            icon: Icons.add_circle_outline,
            width: double.infinity,
          ),
          const SizedBox(height: AppDimensions.paddingMD),
          AppButton(
            text: 'join_family'.tr,
            onPressed: () => Get.toNamed(AppRoutes.joinFamily),
            type: AppButtonType.outlined,
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyView(BuildContext context) {
    final family = controller.currentFamily!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card
          Card(
            elevation: AppDimensions.cardElevation,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
            ),
            color: AppColors.primary,
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingLG),
              child: Column(
                children: [
                  Text(
                    family.name,
                    style: AppFonts.headlineMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingMD),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingMD,
                      vertical: AppDimensions.paddingXS,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMD,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'كود الدعوة: ${family.inviteCode}',
                          style: AppFonts.bodyLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.paddingMD),
                        IconButton(
                          icon: const Icon(
                            Icons.share,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () {
                            SharePlus.instance.share(ShareParams(
                              text: 'انضم لعائلتي في تطبيق صلاة! كود الدعوة: ${family.inviteCode}',
                            ));
                          },
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                  if (family.isAdmin(Get.find<AuthService>().userId ?? '')) ...[
                    const SizedBox(height: AppDimensions.paddingMD),
                    TextButton.icon(
                      onPressed: () => _showAddChildDialog(context),
                      icon: const Icon(
                        Icons.person_add_alt_1,
                        color: Colors.white,
                      ),
                      label: Text(
                        'إضافة طفل (بدون هاتف)',
                        style: AppFonts.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white10,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMD,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: AppDimensions.paddingXL),

          Text(
            'أفراد العائلة (${family.members.length})',
            style: AppFonts.titleLarge.copyWith(color: AppColors.textPrimary),
          ),

          const SizedBox(height: AppDimensions.paddingMD),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: family.members.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppDimensions.paddingMD),
            itemBuilder: (context, index) {
              final member = family.members[index];
              return Obx(() {
                final progress = controller.memberProgress[member.userId] ?? 0;
                final streak = controller.memberStreaks[member.userId] ?? 0;

                return Card(
                  elevation: AppDimensions.cardElevationLow,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(
                      AppDimensions.paddingMD,
                    ),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundImage: member.photoUrl != null
                          ? NetworkImage(member.photoUrl!)
                          : null,
                      backgroundColor: AppColors.secondary.withOpacity(0.1),
                      child: member.photoUrl == null
                          ? Text(
                              (member.name ?? '?')[0].toUpperCase(),
                              style: TextStyle(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    title: Text(
                      member.name ?? 'عضو',
                      style: AppFonts.titleMedium,
                    ),
                    subtitle: Row(
                      children: [
                        Text(
                          member.role.name == 'parent' ? 'مدير العائلة' : 'عضو',
                          style: AppFonts.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (streak > 0) ...[
                          Icon(
                            Icons.local_fire_department,
                            color: Colors.orange,
                            size: 14,
                          ),
                          Text(
                            '$streak',
                            style: AppFonts.bodySmall.copyWith(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (family.isAdmin(Get.find<AuthService>().userId ?? '') &&
                            member.role == MemberRole.child) ...[
                          AppButton.small(
                            text: 'log_for_him'.tr,
                            onPressed: () => _showLogForMemberDialog(
                              context,
                              member.userId,
                              member.name ?? 'عضو',
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (progress < 5 &&
                            member.userId != Get.find<AuthService>().userId)
                          AppButton.small(
                            text: 'encourage'.tr,
                            onPressed: () => controller.pokeMember(
                              member.userId,
                              member.name ?? '',
                            ),
                          ),
                        if (progress < 5 &&
                            member.userId != Get.find<AuthService>().userId)
                          const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.paddingSM,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (progress >= 5
                                        ? AppColors.success
                                        : AppColors.primary)
                                    .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusSM,
                            ),
                          ),
                          child: Text(
                            '$progress/5',
                            style: AppFonts.bodySmall.copyWith(
                              color: progress >= 5
                                  ? AppColors.success
                                  : AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              });
            },
          ),
        ],
      ),
    );
  }

  void _showLogForMemberDialog(
    BuildContext context,
    String memberId,
    String memberName,
  ) {
    final prayers = Get.find<PrayerTimeService>()
        .getTodayPrayers()
        .where((p) => p.prayerType != PrayerName.sunrise)
        .toList();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('select_prayer_to_log'.tr),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: prayers
                .map(
                  (p) => ListTile(
                    title: Text(
                      PrayerNames.displayName(p.prayerType ?? PrayerName.fajr),
                    ),
                    subtitle: Text(
                      '${p.dateTime.hour.toString().padLeft(2, '0')}:${p.dateTime.minute.toString().padLeft(2, '0')}',
                    ),
                    onTap: () {
                      Get.back();
                      final pt = p.prayerType ?? PrayerName.fajr;
                      controller.logPrayerForMember(
                        memberId: memberId,
                        prayerName: pt.name,
                        adhanTime: p.dateTime,
                      );
                    },
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
        ],
      ),
    );
  }

  void _showAddChildDialog(BuildContext context) {
    final nameController = TextEditingController();
    String gender = 'male';
    DateTime birthDate = DateTime(2015);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('add_child'.tr, style: AppFonts.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'child_name'.tr),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: gender,
              items: [
                DropdownMenuItem(value: 'male', child: Text('male'.tr)),
                DropdownMenuItem(value: 'female', child: Text('female'.tr)),
              ],
              onChanged: (v) => gender = v ?? 'male',
              decoration: InputDecoration(labelText: 'gender'.tr),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          ElevatedButton(
            onPressed: () =>
                controller.addChild(nameController.text, birthDate, gender),
            child: Text('add'.tr),
          ),
        ],
      ),
    );
  }
}
