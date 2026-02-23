import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/enums.dart' hide GroupType;
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/features/family/controller/family_controller.dart';
import 'package:salah/features/family/data/models/member_model.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// WAITING ROOM SECTION
// يظهر أعضاء ينتظرون الصلاة معاً + زر "أنا مستعد"
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class WaitingRoomSection extends GetView<FamilyController> {
  const WaitingRoomSection({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<FamilyController>()) return const SizedBox.shrink();

    return Obx(() {
      final byPrayer = controller.waitingByPrayer;
      if (byPrayer.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Text(
              'ينتظرون الصلاة معاً',
              style: AppFonts.labelMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...byPrayer.entries.map(
            (entry) => _WaitingCard(
              prayerName: entry.key,
              waiters: entry.value,
              selfWaiting: controller.selfWaitingFor == entry.key,
              onReady: () => _handleReady(entry.key),
              onCancel: () => controller.setWaitingFor(null),
            ),
          ),
        ],
      );
    });
  }

  void _handleReady(String prayerName) {
    // تحويل String إلى PrayerName enum
    try {
      final prayer = PrayerName.values.firstWhere(
        (p) => p.name == prayerName.toLowerCase(),
      );
      controller.setWaitingFor(prayer);
    } catch (_) {}
  }
}

// ── بطاقة الانتظار لصلاة واحدة ───────────────────────────────────────────────

class _WaitingCard extends StatelessWidget {
  const _WaitingCard({
    required this.prayerName,
    required this.waiters,
    required this.selfWaiting,
    required this.onReady,
    required this.onCancel,
  });

  final String prayerName;
  final List<MemberModel> waiters;
  final bool selfWaiting;
  final VoidCallback onReady;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final prayer = _prayerAr(prayerName);
    final names = waiters.take(2).map((m) => m.displayName.split(' ').first);
    final label = waiters.length == 1
        ? '${names.first} ينتظر $prayer'
        : '${names.join('، ')}${waiters.length > 2 ? ' و${waiters.length - 2} آخرين' : ''} ينتظرون $prayer';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.all(AppDimensions.paddingMD),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFF8E1),
            const Color(0xFFFFF3CD),
          ],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          // أيقونة الصلاة
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD54F).withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Text('🕌', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: AppDimensions.paddingSM),
          // النص
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppFonts.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5D4037),
                  ),
                ),
                Text(
                  'صلّ معهم الآن',
                  style: AppFonts.labelSmall.copyWith(
                    color: const Color(0xFF8D6E63),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.paddingSM),
          // الزر
          selfWaiting
              ? _CancelButton(onPressed: onCancel)
              : _ReadyButton(onPressed: onReady),
        ],
      ),
    );
  }

  String _prayerAr(String name) {
    const map = {
      'fajr': 'الفجر',
      'dhuhr': 'الظهر',
      'asr': 'العصر',
      'maghrib': 'المغرب',
      'isha': 'العشاء',
    };
    return map[name.toLowerCase()] ?? name;
  }
}

// ── زر "أنا مستعد" ────────────────────────────────────────────────────────────

class _ReadyButton extends StatelessWidget {
  const _ReadyButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text('أنا مستعد', style: AppFonts.labelSmall.copyWith(color: Colors.white)),
    );
  }
}

// ── زر "إلغاء الانتظار" ───────────────────────────────────────────────────────

class _CancelButton extends StatelessWidget {
  const _CancelButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFF8D6E63)),
        foregroundColor: const Color(0xFF8D6E63),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text('إلغاء', style: AppFonts.labelSmall),
    );
  }
}
