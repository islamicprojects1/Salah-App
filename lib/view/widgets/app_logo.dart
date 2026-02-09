import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:salah/core/theme/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showShadow;

  const AppLogo({
    super.key,
    this.size = 120,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: showShadow
          ? BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: size * 0.2,
                  spreadRadius: size * 0.05,
                ),
              ],
            )
          : null,
      child: CustomPaint(
        size: Size(size, size),
        painter: _LogoPainter(),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Background Circle with Emerald Gradient
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primary,
          AppColors.primary.withValues(alpha: 0.8),
        ],
        center: const Alignment(-0.2, -0.2),
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    
    canvas.drawCircle(center, radius, bgPaint);

    // 2. Decorative Outer Ring (Islamic Pattern)
    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.02;
    canvas.drawCircle(center, radius * 0.85, ringPaint);

    // 3. Rub el Hizb (8-pointed star)
    final starPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFFFD700), // Gold
          const Color(0xFFDAA520), // Darker Gold
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.6));

    _drawRubElHizb(canvas, center, radius * 0.5, starPaint);

    // 4. Central Mosque Dome Silhouette
    final domePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    
    final domePath = Path();
    final domeWidth = radius * 0.35;
    final domeHeight = radius * 0.45;
    
    // Move to bottom center of the dome area
    domePath.moveTo(center.dx - domeWidth / 2, center.dy + domeHeight / 4);
    
    // Bottom line
    domePath.lineTo(center.dx + domeWidth / 2, center.dy + domeHeight / 4);
    
    // Right wall
    domePath.lineTo(center.dx + domeWidth / 2, center.dy - domeHeight / 6);
    
    // Dome curve
    domePath.quadraticBezierTo(
      center.dx, center.dy - domeHeight, 
      center.dx - domeWidth / 2, center.dy - domeHeight / 6
    );
    
    domePath.close();
    canvas.drawPath(domePath, domePaint);

    // 5. Crescent
    final crescentPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final crescentCenter = Offset(center.dx, center.dy - domeHeight * 0.7);
    final crescentRadius = radius * 0.08;
    
    final crescentPath = Path.combine(
      PathOperation.difference,
      Path() ..addOval(Rect.fromCircle(center: crescentCenter, radius: crescentRadius)),
      Path() ..addOval(Rect.fromCircle(center: Offset(crescentCenter.dx + crescentRadius * 0.5, crescentCenter.dy), radius: crescentRadius)),
    );
    
    canvas.drawPath(crescentPath, crescentPaint);

    // 6. Glassmorphism Highlight (Lens Flare Effect)
    final highlightPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.4),
          Colors.white.withValues(alpha: 0.0),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    
    canvas.drawCircle(center, radius, highlightPaint);
  }

  void _drawRubElHizb(Canvas canvas, Offset center, double radius, Paint paint) {
    final path1 = _getSquarePath(center, radius);
    final path2 = _getSquarePath(center, radius, angle: math.pi / 4);
    
    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
  }

  Path _getSquarePath(Offset center, double radius, {double angle = 0}) {
    final path = Path();
    for (int i = 0; i < 4; i++) {
        double currentAngle = angle + (i * math.pi / 2);
        double x = center.dx + radius * math.cos(currentAngle);
        double y = center.dy + radius * math.sin(currentAngle);
        if (i == 0) path.moveTo(x, y);
        else path.lineTo(x, y);
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
