import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:salah/features/family/controller/family_controller.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// INVITE SHARE CARD
// المسار: lib/features/family/presentation/widgets/invite_share_card.dart
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class InviteShareCard extends GetView<FamilyController> {
  const InviteShareCard({super.key});

  void _showSnack(String msg) {
    Get.rawSnackbar(
      message: msg,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.black87,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      messageText: Text(
        msg,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final code = controller.group.value?.inviteCode ?? '';
      final link = controller.inviteLink ?? '';

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.12)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'invite_members'.tr,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),

              // ── كود الدعوة ───────────────────────────────────
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: code));
                  _showSnack('code_copied'.tr);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A6B4A).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF1A6B4A).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          code,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const Icon(
                        Icons.copy_rounded,
                        size: 18,
                        color: Color(0xFF1A6B4A),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── الأزرار ──────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _Btn(
                      icon: Icons.share_rounded,
                      label: 'share_link'.tr,
                      onTap: () => Share.share(
                        '${'invite_text'.tr}\n$link',
                        subject: 'join_group_subject'.tr,
                      ),
                    ),
                  ),
                  if (controller.isAdmin) ...[
                    const SizedBox(width: 8),
                    _Btn(
                      icon: Icons.refresh_rounded,
                      label: 'renew_code'.tr,
                      onTap: () async {
                        final newCode = await controller.renewInviteCode();
                        if (newCode != null) _showSnack('code_renewed'.tr);
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Btn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}
