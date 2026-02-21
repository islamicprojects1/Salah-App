import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';

// ─────────────────────────────────────────────
// Page Layout
// ─────────────────────────────────────────────
class OnboardingPageLayout extends StatelessWidget {
  final Widget? lottie;
  final String? lottieAsset;
  final IconData? iconData;
  final String title;
  final String subtitle;
  final String? emoji;
  final List<Widget> children;
  final Widget? navigationRow;
  final bool scrollable;

  const OnboardingPageLayout({
    super.key,
    this.lottie,
    this.lottieAsset,
    this.iconData,
    required this.title,
    required this.subtitle,
    this.emoji,
    required this.children,
    this.navigationRow,
    this.scrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    Widget content = Column(
      mainAxisSize: scrollable ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Illustration ──
        _buildIllustration(size),
        const SizedBox(height: 20),

        // ── Title + Subtitle ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              if (emoji != null) ...[
                _EmojiChip(emoji: emoji!),
                const SizedBox(height: 12),
              ],
              OnboardingGradientTitle(title: title),
              const SizedBox(height: 10),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppFonts.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // ── Page-specific content ──
        ...children,

        // ── Navigation Row ──
        if (navigationRow != null) ...[
          scrollable ? const SizedBox(height: 32) : const Spacer(flex: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: navigationRow!,
          ),
          const SizedBox(height: 20),
        ],
      ],
    );

    if (scrollable) {
      content = SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: content,
      );
    }

    return SafeArea(child: content);
  }

  Widget _buildIllustration(Size size) {
    final height = size.height * 0.26;

    if (lottie != null || lottieAsset != null) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child:
            lottie ??
            Lottie.asset(
              lottieAsset!,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  _PlaceholderIcon(iconData: iconData ?? Icons.mosque_rounded),
            ),
      );
    }

    if (iconData != null) {
      return SizedBox(
        height: height,
        child: _AnimatedIconDisplay(icon: iconData!),
      );
    }

    return SizedBox(height: height);
  }
}

// ─────────────────────────────────────────────
// Animated icon with glow ring
// ─────────────────────────────────────────────
class _AnimatedIconDisplay extends StatefulWidget {
  final IconData icon;
  const _AnimatedIconDisplay({required this.icon});

  @override
  State<_AnimatedIconDisplay> createState() => _AnimatedIconDisplayState();
}

class _AnimatedIconDisplayState extends State<_AnimatedIconDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, __) {
          return Container(
            width: 110 + _pulse.value * 12,
            height: 110 + _pulse.value * 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(
                    alpha: 0.15 + _pulse.value * 0.05,
                  ),
                  AppColors.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
            child: Center(
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(widget.icon, size: 44, color: AppColors.primary),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PlaceholderIcon extends StatelessWidget {
  final IconData iconData;
  const _PlaceholderIcon({required this.iconData});

  @override
  Widget build(BuildContext context) {
    return Center(child: Icon(iconData, size: 80, color: AppColors.primary));
  }
}

// ─────────────────────────────────────────────
// Emoji chip
// ─────────────────────────────────────────────
class _EmojiChip extends StatelessWidget {
  final String emoji;
  const _EmojiChip({required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 22)),
    );
  }
}

// ─────────────────────────────────────────────
// Gradient title
// ─────────────────────────────────────────────
class OnboardingGradientTitle extends StatelessWidget {
  final String title;
  final double fontSize;

  const OnboardingGradientTitle({
    super.key,
    required this.title,
    this.fontSize = 26,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [AppColors.primary, AppColors.secondary],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(bounds),
      child: Text(
        title,
        style: AppFonts.headlineMedium.copyWith(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: AppColors.white,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Primary CTA Button
// ─────────────────────────────────────────────
class OnboardingButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? color;
  final bool fullWidth;
  final bool isLoading;

  const OnboardingButton({
    super.key,
    required this.text,
    required this.onTap,
    this.icon,
    this.color,
    this.fullWidth = true,
    this.isLoading = false,
  });

  @override
  State<OnboardingButton> createState() => _OnboardingButtonState();
}

class _OnboardingButtonState extends State<OnboardingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = _scaleCtrl;
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ?? AppColors.primary;

    return GestureDetector(
      onTapDown: (_) => _scaleCtrl.reverse(),
      onTapUp: (_) {
        _scaleCtrl.forward();
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      onTapCancel: () => _scaleCtrl.forward(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: Container(
          width: widget.fullWidth ? double.infinity : null,
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [effectiveColor, effectiveColor.withValues(alpha: 0.78)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: effectiveColor.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: -2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              else ...[
                Text(
                  widget.text,
                  style: AppFonts.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                if (widget.icon != null) ...[
                  const SizedBox(width: 8),
                  Icon(widget.icon, color: AppColors.white, size: 20),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Secondary back button
// ─────────────────────────────────────────────
class OnboardingSecondaryButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const OnboardingSecondaryButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.textSecondary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.textSecondary.withValues(alpha: 0.15),
          ),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 22),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Feature / Info Card
// ─────────────────────────────────────────────
class OnboardingCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final bool hasBorder;
  final EdgeInsets? padding;

  const OnboardingCard({
    super.key,
    required this.child,
    this.color,
    this.hasBorder = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;

    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: hasBorder
            ? Border.all(
                color: effectiveColor.withValues(alpha: 0.18),
                width: 1,
              )
            : null,
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────
// Staggered feature row (appears with animation)
// ─────────────────────────────────────────────
class StaggeredFeatureItem extends StatefulWidget {
  final Widget child;
  final int index;

  const StaggeredFeatureItem({
    super.key,
    required this.child,
    required this.index,
  });

  @override
  State<StaggeredFeatureItem> createState() => _StaggeredFeatureItemState();
}

class _StaggeredFeatureItemState extends State<StaggeredFeatureItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: 80 * widget.index), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ─────────────────────────────────────────────
// Decorative star/dot background painter
// ─────────────────────────────────────────────
class StarFieldPainter extends CustomPainter {
  final double progress;
  final Color color;

  StarFieldPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final paint = Paint()..color = color;

    for (int i = 0; i < 32; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final radius = rng.nextDouble() * 2 + 0.5;
      final opacity =
          (rng.nextDouble() * 0.5 + 0.1) *
          (0.5 + 0.5 * math.sin(progress * 2 * math.pi + i));
      canvas.drawCircle(
        Offset(x, y),
        radius,
        paint..color = color.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(StarFieldPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────
// Animated progress dots
// ─────────────────────────────────────────────
class OnboardingProgressDots extends StatelessWidget {
  final int current;
  final int total;

  const OnboardingProgressDots({
    super.key,
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
