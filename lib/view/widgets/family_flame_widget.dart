import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/controller/family_controller.dart';
import 'package:salah/core/theme/app_colors.dart';

/// A shared flame that only stays alive if **everyone** in the family
/// logs their prayers. It flickers when someone is behind.
class FamilyFlameWidget extends StatefulWidget {
  const FamilyFlameWidget({super.key});

  @override
  State<FamilyFlameWidget> createState() => _FamilyFlameWidgetState();
}

class _FamilyFlameWidgetState extends State<FamilyFlameWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flickerController;
  final FamilyController _familyCtrl = Get.find<FamilyController>();

  @override
  void initState() {
    super.initState();
    _flickerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _flickerController.dispose();
    super.dispose();
  }

  /// Check if everyone has completed all 5
  bool _isEveryoneComplete() {
    final family = _familyCtrl.currentFamily;
    if (family == null || family.members.isEmpty) return false;
    return family.members.every(
      (m) => (_familyCtrl.memberProgress[m.userId] ?? 0) >= 5,
    );
  }

  /// Check if anyone has 0
  bool _isSomeoneBehind() {
    final family = _familyCtrl.currentFamily;
    if (family == null || family.members.isEmpty) return true;
    return family.members.any(
      (m) => (_familyCtrl.memberProgress[m.userId] ?? 0) == 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Obx(() {
      final everyoneComplete = _isEveryoneComplete();
      final someoneBehind = _isSomeoneBehind();
      final family = _familyCtrl.currentFamily;
      if (family == null) return const SizedBox.shrink();

      // Calculate "family flame" streak count
      // For now, use average progress as a visual proxy
      int totalLogged = 0;
      for (final m in family.members) {
        totalLogged += (_familyCtrl.memberProgress[m.userId] ?? 0);
      }
      final avgProgress =
          family.members.isNotEmpty ? totalLogged / family.members.length : 0.0;

      final Color flameColor;
      final double flameSize;
      final String flameLabel;

      if (everyoneComplete) {
        flameColor = const Color(0xFFFFD700);
        flameSize = 40;
        flameLabel = 'flame_perfection'.tr;
      } else if (someoneBehind) {
        flameColor = AppColors.orange.withValues(alpha: 0.5);
        flameSize = 28;
        flameLabel = 'flame_flickering'.tr;
      } else {
        flameColor = AppColors.orange;
        flameSize = 34;
        flameLabel = 'flame_burning'.tr;
      }

      return AnimatedBuilder(
        animation: _flickerController,
        builder: (context, child) {
          // Flickering is more intense when someone is behind
          final flickerIntensity = someoneBehind ? 0.25 : 0.08;
          final scale =
              1.0 + (_flickerController.value * flickerIntensity);
          final rotation = someoneBehind
              ? math.sin(_flickerController.value * math.pi) * 0.05
              : 0.0;

          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: flameColor.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: flameColor.withValues(alpha: 0.1),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: scale,
                  child: Transform.rotate(
                    angle: rotation,
                    child: Text(
                      '🔥',
                      style: TextStyle(fontSize: flameSize),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'family_flame'.tr,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      flameLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: flameColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // Average progress badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: flameColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${avgProgress.toStringAsFixed(1)}/5',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: flameColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }
}
