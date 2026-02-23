import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/features/family/controller/family_controller.dart';
import 'package:salah/features/family/data/models/member_model.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// PRAYING NOW BANNER
// يظهر عندما يوجد أعضاء من العائلة يصلّون الآن
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class PrayingNowBanner extends GetView<FamilyController> {
  const PrayingNowBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<FamilyController>()) return const SizedBox.shrink();

    return Obx(() {
      final praying = controller.prayingNowMembers;
      if (praying.isEmpty) return const SizedBox.shrink();

      return AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppDimensions.paddingSM),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMD,
            vertical: AppDimensions.paddingSM + 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              // أيقونة نابضة
              _PulsingIcon(),
              const SizedBox(width: AppDimensions.paddingSM),
              // النص
              Expanded(
                child: Text(
                  _buildLabel(praying),
                  style: AppFonts.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // الأفاتار الصغيرة (حتى 3)
              ...praying.take(3).map((m) => _MiniAvatar(member: m)),
              if (praying.length > 3)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 4),
                  child: Text(
                    '+${praying.length - 3}',
                    style: AppFonts.labelSmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  String _buildLabel(List<MemberModel> praying) {
    final names = praying.take(2).map((m) => m.displayName.split(' ').first);
    final joined = names.join('، ');
    final prayer = _prayerAr(
      praying.first.prayingNow?['prayerName'] as String? ?? '',
    );
    if (praying.length == 1) {
      return '$joined يصلّي $prayer الآن 🤲';
    }
    final extra = praying.length > 2 ? ' و${praying.length - 2} آخرين' : '';
    return '$joined$extra يصلّون $prayer الآن 🤲';
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

// ── أيقونة نابضة ─────────────────────────────────────────────────────────────

class _PulsingIcon extends StatefulWidget {
  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Icon(
        Icons.mosque_rounded,
        size: AppDimensions.iconSM,
        color: AppColors.primary,
      ),
    );
  }
}

// ── أفاتار صغير ───────────────────────────────────────────────────────────────

class _MiniAvatar extends StatelessWidget {
  const _MiniAvatar({required this.member});
  final MemberModel member;

  @override
  Widget build(BuildContext context) {
    final initials = member.displayName.isNotEmpty
        ? member.displayName[0].toUpperCase()
        : '?';
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4),
      child: CircleAvatar(
        radius: 12,
        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
        child: Text(
          initials,
          style: AppFonts.labelSmall.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}
