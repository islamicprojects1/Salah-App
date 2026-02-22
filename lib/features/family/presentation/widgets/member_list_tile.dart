import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/features/family/controller/family_controller.dart';
import 'package:salah/features/family/data/models/member_model.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MEMBER LIST TILE
// المسار: lib/features/family/presentation/widgets/member_list_tile.dart
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class MemberListTile extends StatelessWidget {
  final MemberModel member;
  final bool showAdminActions;

  const MemberListTile({
    super.key,
    required this.member,
    this.showAdminActions = false,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<FamilyController>();
    final isMe = member.userId == ctrl.currentUserId;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: _Avatar(member: member),
        title: Row(
          children: [
            Flexible(
              child: Text(
                member.displayName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isMe) ...[
              const SizedBox(width: 6),
              _Tag('me'.tr, const Color(0xFF1A6B4A)),
            ],
            if (member.isAdmin && !isMe) ...[
              const SizedBox(width: 6),
              _Tag('admin'.tr, const Color(0xFFFF9800)),
            ],
            if (member.isShadow) ...[
              const SizedBox(width: 6),
              _Tag('shadow'.tr, Colors.grey),
            ],
          ],
        ),
        subtitle: Text(
          member.isAdmin ? 'group_admin'.tr : 'group_member'.tr,
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        trailing: (showAdminActions && !isMe && ctrl.isAdmin)
            ? _AdminActions(member: member)
            : null,
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final MemberModel member;
  const _Avatar({required this.member});

  @override
  Widget build(BuildContext context) {
    final color = member.isShadow
        ? Colors.grey.withOpacity(0.2)
        : const Color(0xFF1A6B4A).withOpacity(0.12);
    final textColor = member.isShadow
        ? Colors.grey[600]!
        : const Color(0xFF1A6B4A);

    return CircleAvatar(
      radius: 22,
      backgroundColor: color,
      child: Text(
        member.displayName.isNotEmpty
            ? member.displayName[0].toUpperCase()
            : '?',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AdminActions extends StatelessWidget {
  final MemberModel member;
  const _AdminActions({required this.member});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<FamilyController>();

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) async {
        switch (value) {
          case 'kick':
            if (await _confirm(
              context,
              'kick_member'.tr,
              'kick_confirm_msg'.tr,
            )) {
              ctrl.kickMember(member.userId);
            }
            break;
          case 'block':
            if (await _confirm(
              context,
              'kick_and_block'.tr,
              'block_confirm_msg'.tr,
              red: true,
            )) {
              ctrl.kickAndBlock(member.userId);
            }
            break;
          case 'make_admin':
            if (await _confirm(
              context,
              'transfer_admin'.tr,
              'transfer_admin_msg'.tr,
            )) {
              ctrl.transferAdmin(member.userId);
            }
            break;
        }
      },
      itemBuilder: (_) => [
        if (!member.isShadow)
          PopupMenuItem(
            value: 'make_admin',
            child: Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  size: 18,
                  color: Color(0xFFFF9800),
                ),
                const SizedBox(width: 8),
                Text('transfer_admin'.tr),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'kick',
          child: Row(
            children: [
              const Icon(Icons.person_remove, size: 18, color: Colors.orange),
              const SizedBox(width: 8),
              Text('kick_member'.tr),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'block',
          child: Row(
            children: [
              const Icon(Icons.block, size: 18, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                'kick_and_block'.tr,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<bool> _confirm(
    BuildContext context,
    String title,
    String msg, {
    bool red = false,
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
                  'confirm'.tr,
                  style: TextStyle(
                    color: red ? Colors.red : null,
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
