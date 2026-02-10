import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:share_plus/share_plus.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/core/constants/image_assets.dart';
import 'package:salah/controller/family_controller.dart';
import 'package:salah/core/routes/app_routes.dart';
import 'package:salah/core/helpers/prayer_names.dart';
import 'package:salah/core/helpers/prayer_timing_helper.dart';
import 'package:salah/core/services/auth_service.dart';
import 'package:salah/core/services/prayer_time_service.dart';
import 'package:salah/data/models/family_model.dart';
import 'package:salah/core/helpers/date_time_helper.dart';
import 'package:salah/view/widgets/app_button.dart';
import 'package:salah/view/widgets/app_loading.dart';

class FamilyDashboardScreen extends GetView<FamilyController> {
  const FamilyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading) {
        return const AppLoading();
      }

      if (!controller.hasFamily) {
        return _buildNoFamilyView();
      }

      return _buildFamilyView(context);
    });
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
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMD,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${'invite_code_label'.tr}: ${family.inviteCode}',
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
                            SharePlus.instance.share(
                              ShareParams(
                                text: 'share_family_invite'.tr.replaceAll(
                                  '@code',
                                  family.inviteCode,
                                ),
                              ),
                            );
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
                        'add_child_no_phone_btn'.tr,
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

          // ----- Family Daily Summary -----
          _buildFamilySummaryCard(family),

          const SizedBox(height: AppDimensions.paddingMD),

          _buildPulseSection(),

          const SizedBox(height: AppDimensions.paddingXL),

          Text(
            'family_members_count'.tr.replaceAll(
              '@count',
              '${family.members.length}',
            ),
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
                      backgroundColor: AppColors.secondary.withValues(
                        alpha: 0.1,
                      ),
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
                      member.name ?? 'member_role'.tr,
                      style: AppFonts.titleMedium,
                    ),
                    subtitle: Row(
                      children: [
                        Text(
                          member.role.name == 'parent'
                              ? 'family_admin'.tr
                              : 'member_role'.tr,
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
                        if (family.isAdmin(
                              Get.find<AuthService>().userId ?? '',
                            ) &&
                            member.role == MemberRole.child) ...[
                          AppButton.small(
                            text: 'log_for_him'.tr,
                            onPressed: () => _showLogForMemberDialog(
                              context,
                              member.userId,
                              member.name ?? 'member_role'.tr,
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
                            color: _getMemberProgressColor(
                              progress,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusSM,
                            ),
                          ),
                          child: Text(
                            '$progress/5',
                            style: AppFonts.bodySmall.copyWith(
                              color: _getMemberProgressColor(progress),
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

  Widget _buildPulseSection() {
    return Obx(() {
      final events = controller.pulseEvents;
      if (events.isEmpty) return const SizedBox.shrink();
      return Card(
        elevation: AppDimensions.cardElevationLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.favorite, color: AppColors.primary, size: 20),
                  const SizedBox(width: AppDimensions.paddingSM),
                  Text(
                    'family_pulse'.tr,
                    style: AppFonts.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingMD),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: events.length > 15 ? 15 : events.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppDimensions.paddingXS),
                itemBuilder: (context, index) {
                  final e = events[index];
                  return Row(
                    children: [
                      Icon(
                        e.type == PulseEventType.encouragement
                            ? Icons.thumb_up
                            : Icons.mosque,
                        size: 18,
                        color: AppColors.primary.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          e.displayText,
                          style: AppFonts.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        _relativeTime(e.timestamp),
                        style: AppFonts.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      );
    });
  }

  /// Family daily summary card – total prayers logged across all members
  Widget _buildFamilySummaryCard(FamilyModel family) {
    return Obx(() {
      final totalMembers = family.members.length;
      final totalPossible = totalMembers * 5;
      int totalLogged = 0;
      for (final m in family.members) {
        totalLogged += (controller.memberProgress[m.userId] ?? 0);
      }
      final progress = totalPossible > 0 ? totalLogged / totalPossible : 0.0;

      return Card(
        elevation: AppDimensions.cardElevationLow,
        margin: const EdgeInsets.only(top: AppDimensions.paddingMD),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.bar_chart_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: AppDimensions.paddingSM),
                  Text(
                    'family_daily_summary'.tr,
                    style: AppFonts.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$totalLogged/$totalPossible',
                    style: AppFonts.titleLarge.copyWith(
                      color: _getMemberProgressColor(totalLogged ~/ (totalMembers > 0 ? totalMembers : 1)),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingSM),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getMemberProgressColor(totalLogged ~/ (totalMembers > 0 ? totalMembers : 1)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  /// Map member prayer count (0-5) to a descriptive color
  Color _getMemberProgressColor(int count) {
    if (count >= 5) return PrayerTimingHelper.getQualityColor(PrayerTimingQuality.veryEarly);
    if (count >= 3) return Colors.amber;
    if (count >= 1) return Colors.orange;
    return Colors.red.shade300;
  }

  String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'now_label'.tr;
    if (diff.inMinutes < 60) return '${diff.inMinutes} ${'minutes_short'.tr}';
    if (diff.inHours < 24) return '${diff.inHours} ${'hours_short'.tr}';
    return DateTimeHelper.formatTime24(time);
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
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
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
