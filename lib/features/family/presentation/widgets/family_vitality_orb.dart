import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:salah/features/family/controller/family_controller.dart';

/// A glassmorphic, animated orb that visualizes the family's collective
/// prayer vitality. It glows, pulses, and shifts color based on how many
/// family members have completed their prayers today.
///
/// States:
///  - **0%** : Dim, cool blue-grey — dormant
///  - **1‑49%** : Warm amber pulse — awakening
///  - **50‑99%** : Teal‑green breathing glow — thriving
///  - **100%** : Radiant gold "Noor" aura — perfection
class FamilyVitalityOrb extends StatefulWidget {
  const FamilyVitalityOrb({super.key});

  @override
  State<FamilyVitalityOrb> createState() => _FamilyVitalityOrbState();
}

class _FamilyVitalityOrbState extends State<FamilyVitalityOrb>
    with TickerProviderStateMixin {
  late final AnimationController _breatheController;
  late final AnimationController _shimmerController;
  late final AnimationController _glowController;
  final FamilyController _familyCtrl = Get.find<FamilyController>();

  @override
  void initState() {
    super.initState();

    // Slow breathing pulse (scale)
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    // Rotating shimmer ring
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Glow intensity
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breatheController.dispose();
    _shimmerController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  /// Compute family progress as 0.0 .. 1.0
  double _computeProgress() {
    final family = _familyCtrl.currentFamily;
    if (family == null || family.members.isEmpty) return 0.0;

    int totalLogged = 0;
    for (final m in family.members) {
      totalLogged += (_familyCtrl.memberProgress[m.userId] ?? 0);
    }
    final max = family.members.length * 5;
    return max > 0 ? (totalLogged / max).clamp(0.0, 1.0) : 0.0;
  }

  /// Palette changes based on family progress
  _OrbPalette _palette(double progress) {
    if (progress >= 1.0) {
      // ✨ Perfection — radiant gold Noor
      return _OrbPalette(
        core: const Color(0xFFFFD700),
        glow: const Color(0xFFD4AF37),
        ring: const Color(0xFFFFE082),
        label: 'noor_label'.tr,
        emoji: '✨',
      );
    } else if (progress >= 0.5) {
      // 🌿 Thriving — teal-green
      return _OrbPalette(
        core: const Color(0xFF26A69A),
        glow: const Color(0xFF00897B),
        ring: const Color(0xFF80CBC4),
        label: 'family_growing'.tr,
        emoji: '🌿',
      );
    } else if (progress > 0) {
      // 🔥 Awakening — warm amber
      return _OrbPalette(
        core: const Color(0xFFFFB74D),
        glow: const Color(0xFFF57C00),
        ring: const Color(0xFFFFCC80),
        label: 'family_awakening'.tr,
        emoji: '🔥',
      );
    } else {
      // 🌙 Dormant — cool blue-grey
      return _OrbPalette(
        core: const Color(0xFF78909C),
        glow: const Color(0xFF546E7A),
        ring: const Color(0xFFB0BEC5),
        label: 'family_resting'.tr,
        emoji: '🌙',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Obx(() {
      final progress = _computeProgress();
      final palette = _palette(progress);
      final percent = (progress * 100).toInt();

      return GestureDetector(
        onTap: () {
          // "Send Peace" haptic
          HapticFeedback.mediumImpact();
          Get.snackbar(
            'سلام عليكم 🕊️',
            'send_peace_message'.tr,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
            backgroundColor: colorScheme.primaryContainer,
            colorText: colorScheme.onPrimaryContainer,
          );
        },
        child: SizedBox(
          width: 220,
          height: 250,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ─── The Orb ───
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 1. Outer Glow
                    AnimatedBuilder(
                      animation: _glowController,
                      builder: (context, child) {
                        final glowRadius =
                            40.0 + (_glowController.value * 16.0);
                        return Container(
                          width: 170,
                          height: 170,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: palette.glow.withValues(
                                  alpha: 0.25 + (_glowController.value * 0.15),
                                ),
                                blurRadius: glowRadius,
                                spreadRadius: glowRadius * 0.3,
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // 2. Rotating shimmer ring (SVG-like via CustomPaint)
                    AnimatedBuilder(
                      animation: _shimmerController,
                      builder: (context, child) {
                        return CustomPaint(
                          size: const Size(180, 180),
                          painter: _ShimmerRingPainter(
                            rotation: _shimmerController.value * 2 * math.pi,
                            color: palette.ring,
                            progress: progress,
                          ),
                        );
                      },
                    ),

                    // 3. Glassmorphic Core Orb
                    AnimatedBuilder(
                      animation: _breatheController,
                      builder: (context, child) {
                        final scale =
                            1.0 +
                            (_breatheController.value *
                                0.04 *
                                (1.0 + progress));
                        return Transform.scale(scale: scale, child: child);
                      },
                      child: ClipOval(
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 800),
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  palette.core.withValues(alpha: 0.7),
                                  palette.core.withValues(alpha: 0.3),
                                  palette.glow.withValues(alpha: 0.1),
                                ],
                                stops: const [0.0, 0.6, 1.0],
                              ),
                              border: Border.all(
                                color: palette.ring.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    palette.emoji,
                                    style: const TextStyle(fontSize: 32),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$percent%',
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          shadows: [
                                            Shadow(
                                              color: colorScheme.shadow
                                                  .withValues(alpha: 0.5),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Label ───
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  palette.label,
                  key: ValueKey(palette.label),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: palette.core,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ─── Supporting types ─────────────────────────────────────────────

class _OrbPalette {
  final Color core;
  final Color glow;
  final Color ring;
  final String label;
  final String emoji;

  const _OrbPalette({
    required this.core,
    required this.glow,
    required this.ring,
    required this.label,
    required this.emoji,
  });
}

/// Draws a dashed arc ring that rotates, conveying "living energy."
class _ShimmerRingPainter extends CustomPainter {
  final double rotation;
  final Color color;
  final double progress;

  _ShimmerRingPainter({
    required this.rotation,
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Number of arc segments scales with progress (more = more alive)
    final segments = 6 + (progress * 10).toInt();
    final gapAngle = math.pi / (segments * 2);
    final arcAngle = (2 * math.pi / segments) - gapAngle;

    for (int i = 0; i < segments; i++) {
      final startAngle = rotation + (i * (arcAngle + gapAngle));

      // Alternate opacity for depth
      final alpha = 0.15 + (0.25 * ((i % 2 == 0) ? 1.0 : 0.5));

      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, arcAngle, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ShimmerRingPainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
        oldDelegate.progress != progress ||
        oldDelegate.color != color;
  }
}
