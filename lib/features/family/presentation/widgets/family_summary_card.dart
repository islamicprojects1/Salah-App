import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/features/family/controller/family_controller.dart';
import 'package:salah/features/family/data/models/group_model.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// FAMILY SUMMARY CARD
// المسار: lib/features/family/presentation/widgets/family_summary_card.dart
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class FamilySummaryCard extends GetView<FamilyController> {
  const FamilySummaryCard({super.key});

  Color _color(double ratio) {
    if (ratio >= 1.0) return const Color(0xFF4CAF50);
    if (ratio >= 0.6) return const Color(0xFFFF9800);
    if (ratio >= 0.3) return const Color(0xFFFF5722);
    return const Color(0xFF9E9E9E);
  }

  String _emoji(double ratio) {
    if (ratio >= 1.0) return '🌟';
    if (ratio >= 0.6) return '🔥';
    if (ratio >= 0.3) return '✨';
    return '🕌';
  }

  String _typeLabel(GroupType type) {
    switch (type) {
      case GroupType.family:
        return 'family_type'.tr;
      case GroupType.guided:
        return 'guided_type'.tr;
      case GroupType.friends:
        return 'friends_type'.tr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final g = controller.group.value;
      final s = controller.summary.value;
      final ratio = s?.completionRatio ?? 0.0;
      final color = _color(ratio);

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.12), color.withOpacity(0.03)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.25), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── رأس البطاقة ──────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          g?.name.isNotEmpty == true ? g!.name : 'my_group'.tr,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (g != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            _typeLabel(g.type),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _emoji(ratio),
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── العداد X/Y ───────────────────────────────────
              Center(
                child: Column(
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${s?.prayedCount ?? 0}',
                            style: TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.w800,
                              color: color,
                              height: 1,
                            ),
                          ),
                          TextSpan(
                            text: '/${s?.totalMembers ?? g?.memberCount ?? 0}',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey[500],
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'prayed_today'.tr,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── شريط التقدم ──────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  backgroundColor: Colors.grey.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),

              // ── رسالة اكتمال ─────────────────────────────────
              if (s?.isAllPrayed == true) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF4CAF50),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'all_prayed_today'.tr,
                        style: const TextStyle(
                          color: Color(0xFF4CAF50),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
}
