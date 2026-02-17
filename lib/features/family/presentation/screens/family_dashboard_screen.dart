import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/di/injection_container.dart';
import 'package:salah/core/feedback/app_feedback.dart';
import 'package:salah/core/helpers/date_time_helper.dart';
import 'package:salah/core/helpers/prayer_names.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/core/widgets/app_loading.dart';
import 'package:salah/features/auth/data/services/auth_service.dart';
import 'package:salah/features/family/controller/family_controller.dart';
import 'package:salah/features/family/presentation/widgets/family_flame_widget.dart';
import 'package:salah/features/family/presentation/widgets/family_header_card.dart';
import 'package:salah/features/family/presentation/widgets/family_member_card.dart';
import 'package:salah/features/family/presentation/widgets/family_pulse_section.dart';
import 'package:salah/features/family/presentation/widgets/family_summary_card.dart';
import 'package:salah/features/family/presentation/widgets/family_vitality_orb.dart';
import 'package:salah/features/family/presentation/widgets/no_family_empty_state.dart';
import 'package:salah/core/routes/app_routes.dart';
import 'package:salah/features/prayer/data/services/prayer_time_service.dart';

class FamilyDashboardScreen extends StatefulWidget {
  const FamilyDashboardScreen({super.key});

  @override
  State<FamilyDashboardScreen> createState() => _FamilyDashboardScreenState();
}

class _FamilyDashboardScreenState extends State<FamilyDashboardScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final controller = Get.find<FamilyController>();

    return Obx(() {
      if (controller.isLoading) {
        return const AppLoading();
      }

      if (!controller.hasFamily) {
        return const NoFamilyEmptyState();
      }

      return _buildFamilyView(context, controller);
    });
  }

  Widget _buildFamilyView(BuildContext context, FamilyController controller) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final family = controller.currentFamily!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FamilyHeaderCard(
            family: family,
            controller: controller,
            onShowFamilySwitcher: () => _showFamilySwitcher(context, controller),
            onAddChild: () => _showAddChildDialog(context, controller),
            hasUnreadPulse: controller.pulseEvents.isNotEmpty,
          ),

          const SizedBox(height: AppDimensions.paddingLG),
          const Center(child: FamilyVitalityOrb()),
          const SizedBox(height: AppDimensions.paddingLG),
          const Center(child: FamilyFlameWidget()),
          const SizedBox(height: AppDimensions.paddingLG),

          FamilySummaryCard(family: family, controller: controller),
          const SizedBox(height: AppDimensions.paddingLG),

          FamilyPulseSection(controller: controller),
          const SizedBox(height: AppDimensions.paddingXL),

          Text(
            'family_members_count'.tr.replaceAll(
              '@count',
              '${family.members.length}',
            ),
            style: AppFonts.titleLarge.copyWith(color: colorScheme.onSurface),
          ),
          const SizedBox(height: AppDimensions.paddingMD),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: family.members.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppDimensions.paddingMD),
            itemBuilder: (context, index) {
              final member = family.members[index];
              return FamilyMemberCard(
                member: member,
                family: family,
                controller: controller,
                onLogForMember: family.isAdmin(sl<AuthService>().userId ?? '') &&
                        member.role == MemberRole.child
                    ? () => _showLogForMemberDialog(
                          context,
                          controller,
                          member.userId,
                          member.name ?? '',
                        )
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }

  void _showLogForMemberDialog(
    BuildContext context,
    FamilyController controller,
    String memberId,
    String memberName,
  ) {
    final now = DateTime.now();
    final prayers = sl<PrayerTimeService>()
        .getTodayPrayers()
        .where(
          (p) =>
              p.prayerType != PrayerName.sunrise && p.dateTime.isBefore(now),
        )
        .toList();

    if (prayers.isEmpty) {
      AppFeedback.showSnackbar('alert'.tr, 'no_past_prayers_yet'.tr);
      return;
    }

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
                      PrayerNames.displayName(
                        p.prayerType ?? PrayerName.fajr,
                      ),
                    ),
                    subtitle: Text(DateTimeHelper.formatTime12(p.dateTime)),
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

  void _showAddChildDialog(
    BuildContext context,
    FamilyController controller,
  ) {
    final nameController = TextEditingController();
    String gender = 'male';
    DateTime birthDate = DateTime(2015);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
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
                  initialValue: gender,
                  items: [
                    DropdownMenuItem(value: 'male', child: Text('male'.tr)),
                    DropdownMenuItem(value: 'female', child: Text('female'.tr)),
                  ],
                  onChanged: (v) => setState(() => gender = v ?? 'male'),
                  decoration: InputDecoration(labelText: 'gender'.tr),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
              ElevatedButton(
                onPressed: () => controller.addChild(
                  nameController.text,
                  birthDate,
                  gender,
                ),
                child: Text('add'.tr),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showFamilySwitcher(
    BuildContext context,
    FamilyController controller,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(AppDimensions.paddingLG),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'switch_family'.tr,
              style: AppFonts.titleLarge.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.paddingLG),
            Flexible(
              child: Obx(
                () => ListView.separated(
                  shrinkWrap: true,
                  itemCount: controller.myFamilies.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final family = controller.myFamilies[index];
                    final isSelected =
                        family.id == controller.currentFamily?.id;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isSelected
                            ? colorScheme.primary
                            : colorScheme.secondaryContainer,
                        child: Icon(
                          Icons.group,
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSecondaryContainer,
                        ),
                      ),
                      title: Text(
                        family.name,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check, color: colorScheme.primary)
                          : null,
                      onTap: () {
                        controller.selectFamily(family);
                        Get.back();
                      },
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingLG),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Get.back();
                      Get.toNamed(AppRoutes.createFamily);
                    },
                    icon: const Icon(Icons.add),
                    label: Text('create_family'.tr),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Get.back();
                      Get.toNamed(AppRoutes.joinFamily);
                    },
                    icon: const Icon(Icons.login),
                    label: Text('join_family'.tr),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingMD),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }
}
