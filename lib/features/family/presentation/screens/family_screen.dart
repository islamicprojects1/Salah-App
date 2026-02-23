import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/features/family/controller/family_controller.dart';
import 'package:salah/features/family/data/models/member_model.dart';
import 'package:salah/features/family/presentation/screens/create_group_screen.dart';
import 'package:salah/features/family/presentation/screens/join_group_screen.dart';
import 'package:salah/features/family/presentation/widgets/family_summary_card.dart';
import 'package:salah/features/family/presentation/widgets/invite_share_card.dart';
import 'package:salah/features/family/presentation/widgets/member_list_tile.dart';
import 'package:salah/features/family/presentation/widgets/add_shadow_member_sheet.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// FAMILY SCREEN
// المسار: lib/features/family/presentation/screens/family_screen.dart
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class FamilyScreen extends GetView<FamilyController> {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        switch (controller.viewState.value) {
          case FamilyViewState.initial:
          case FamilyViewState.loading:
            return const _LoadingView();
          case FamilyViewState.error:
            return _ErrorView(onRetry: controller.loadGroup);
          case FamilyViewState.noGroup:
            return const _NoGroupView();
          case FamilyViewState.hasGroup:
            return const _GroupView();
        }
      }),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// LOADING
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF1A6B4A)),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ERROR
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'load_error'.tr,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text('retry'.tr),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A6B4A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// NO GROUP — شاشة الترحيب
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _NoGroupView extends StatelessWidget {
  const _NoGroupView();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),

            // ── الأيقونة ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                const Color(0xFF1A6B4A).withValues(alpha: 0.12),
                    const Color(0xFF1A6B4A).withValues(alpha: 0.02),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Text('🕌', style: TextStyle(fontSize: 72)),
            ),
            const SizedBox(height: 32),

            Text(
              'family_welcome_title'.tr,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'family_welcome_desc'.tr,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // ── إنشاء ─────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => Get.to(() => const CreateGroupScreen()),
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  'create_group'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A6B4A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── انضمام ────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () => Get.to(() => const JoinGroupScreen()),
                icon: const Icon(Icons.login_rounded),
                label: Text(
                  'join_group'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF1A6B4A), width: 1.5),
                  foregroundColor: const Color(0xFF1A6B4A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const Expanded(child: SizedBox.shrink()),

            // ── ملاحظة خصوصية ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 18,
                    color: Color(0xFF1A6B4A),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'privacy_note'.tr,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// HAS GROUP — الشاشة الكاملة
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _GroupView extends GetView<FamilyController> {
  const _GroupView();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ── AppBar ─────────────────────────────────────────────────
        SliverAppBar(
          floating: true,
          snap: true,
          centerTitle: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          title: Obx(
            () => Text(
              controller.group.value?.name.isNotEmpty == true
                  ? controller.group.value!.name
                  : 'my_group'.tr,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          actions: [const _GroupMenu()],
        ),

        // ── المحتوى ────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FamilySummaryCard(),
              const InviteShareCard(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Text(
                      'members'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Obx(
                      () => Text(
                        '${controller.members.length}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── قائمة الأعضاء ─────────────────────────────────────────
        Obx(() {
          final list = controller.members;
          if (list.isEmpty) {
            return SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'no_members_yet'.tr,
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ),
              ),
            );
          }
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) =>
                  MemberListTile(member: list[i], showAdminActions: true),
              childCount: list.length,
            ),
          );
        }),

        // ── إضافة ظِل (مدير فقط) ────────────────────────────────
        Obx(
          () => controller.isAdmin
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: OutlinedButton.icon(
                      onPressed: AddShadowMemberSheet.show,
                      icon: const Icon(Icons.person_add_outlined, size: 18),
                      label: Text('add_shadow_member'.tr),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1A6B4A),
                        side: const BorderSide(
                          color: Color(0xFF1A6B4A),
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                )
              : const SliverToBoxAdapter(child: SizedBox.shrink()),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MENU — خيارات المجموعة
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _GroupMenu extends GetView<FamilyController> {
  const _GroupMenu();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isAdmin = controller.isAdmin; // Read observable during Obx build
      return PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onSelected: (v) async {
          if (v == 'leave') await _handleLeave(context);
          if (v == 'dissolve') await _handleDissolve(context);
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'leave',
            child: Row(
              children: [
                const Icon(
                  Icons.exit_to_app_rounded,
                  size: 18,
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                Text('leave_group'.tr),
              ],
            ),
          ),
          if (isAdmin)
            PopupMenuItem(
              value: 'dissolve',
              child: Row(
                children: [
                  const Icon(
                    Icons.delete_forever_rounded,
                    size: 18,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'dissolve_group'.tr,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }

  Future<void> _handleLeave(BuildContext context) async {
    final isAdmin = controller.isAdmin;
    final activeMembers = controller.members
        .where((m) => !m.isShadow && m.isActive)
        .toList();
    final hasOthers = activeMembers.any(
      (m) => m.userId != controller.currentUserId,
    );

    // المدير لديه أعضاء آخرون → يجب نقل الإدارة أولاً
    if (isAdmin && hasOthers) {
      _showMustTransferDialog(context);
      return;
    }

    final confirm = await _dialog(
      context,
      title: 'leave_group'.tr,
      msg: (isAdmin && !hasOthers)
          ? 'leave_last_admin_msg'.tr
          : 'leave_group_msg'.tr,
      confirmLabel: 'leave'.tr,
      confirmColor: Colors.orange,
    );
    if (!confirm) return;

    if (isAdmin && !hasOthers) {
      await controller.dissolveGroup();
    } else {
      await controller.leaveGroup();
    }
  }

  Future<void> _handleDissolve(BuildContext context) async {
    final confirm = await _dialog(
      context,
      title: 'dissolve_group'.tr,
      msg: 'dissolve_confirm_msg'.tr,
      confirmLabel: 'dissolve'.tr,
      confirmColor: Colors.red,
    );
    if (confirm) await controller.dissolveGroup();
  }

  void _showMustTransferDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('must_transfer_admin'.tr),
        content: Text('must_transfer_admin_msg'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ok'.tr),
          ),
        ],
      ),
    );
  }

  Future<bool> _dialog(
    BuildContext context, {
    required String title,
    required String msg,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(title),
            content: Text(msg),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('cancel'.tr),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  confirmLabel,
                  style: TextStyle(
                    color: confirmColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
}
