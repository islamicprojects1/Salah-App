import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/controller/dashboard_controller.dart';

/// Premium GitHub-style prayer heatmap with glassmorphism and soft edge fades.
class PrayerHeatmap extends StatelessWidget {
  const PrayerHeatmap({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();

    return Obx(() {
      final data = controller.dailyPrayerCounts;
      if (data.isEmpty) return const SizedBox.shrink();

      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.white.withValues(alpha: 0.15)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                
                // Adaptive Grid with Fade Effect
                ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        AppColors.black.withValues(alpha: 0.05),
                        AppColors.black,
                        AppColors.black,
                        AppColors.black.withValues(alpha: 0.05),
                      ],
                      stops: const [0.0, 0.05, 0.95, 1.0],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true, // Show latest days (right) first
                    physics: const BouncingScrollPhysics(),
                    child: _buildGrid(context, data),
                  ),
                ),
                
                const SizedBox(height: 16),
                _buildLegend(),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.calendar_view_week_rounded, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'prayer_heatmap'.tr,
              style: AppFonts.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        Text(
          'last_6_months'.tr, // Optional: add this key or just use '6 months'
          style: AppFonts.labelSmall.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildGrid(BuildContext context, Map<DateTime, int> data) {
    final today = DateTime.now();
    // Start from 24 weeks ago
    final startDate = today.subtract(const Duration(days: 168));
    
    List<Widget> columns = [];
    DateTime currentDate = startDate;

    // Adjust to start of week (e.g., Sunday or Saturday)
    // We'll iterate to create columns of 7 days
    while (currentDate.isBefore(today) || currentDate.isAtSameMomentAs(today)) {
      List<Widget> weekCells = [];
      for (int i = 0; i < 7; i++) {
        final date = DateTime(currentDate.year, currentDate.month, currentDate.day);
        
        if (date.isAfter(today)) {
          weekCells.add(_buildCell(null, date));
        } else {
          final count = data[date] ?? 0;
          weekCells.add(_buildCell(count, date));
        }
        currentDate = currentDate.add(const Duration(days: 1));
      }
      
      columns.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(children: weekCells),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: columns,
    );
  }

  Widget _buildCell(int? count, DateTime date) {
    if (count == null) {
      return SizedBox(width: 14, height: 14, child: Center(child: SizedBox(width: 2, height: 2, child: DecoratedBox(decoration: BoxDecoration(color: AppColors.white10)))));
    }

    final isFull = count == 5;
    
    return Tooltip(
      message: '${date.day}/${date.month}: $count/5',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        width: 14,
        height: 14,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          gradient: _getGradient(count),
          boxShadow: isFull ? [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 4,
              spreadRadius: 0.5,
            )
          ] : null,
          border: Border.all(
            color: AppColors.white.withValues(alpha: count == 0 ? 0.05 : 0.1),
            width: 0.5,
          ),
        ),
      ),
    );
  }

  LinearGradient _getGradient(int count) {
    if (count == 0) {
      return LinearGradient(
        colors: [AppColors.white.withValues(alpha: 0.05), AppColors.white.withValues(alpha: 0.08)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      );
    }
    
    final base = AppColors.primary;
    final opacity = 0.2 + (count * 0.16); // 0.2 to 1.0 (approx)
    
    return LinearGradient(
      colors: [
        base.withValues(alpha: opacity),
        base.withValues(alpha: (opacity + 0.1).clamp(0.0, 1.0)),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          'heatmap_less'.tr, // Specific keys to avoid conflict
          style: AppFonts.labelSmall.copyWith(fontSize: 9, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 6),
        Row(
          children: List.generate(6, (i) {
            return Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: _getGradient(i),
              ),
            );
          }),
        ),
        const SizedBox(width: 6),
        Text(
          'heatmap_more'.tr,
          style: AppFonts.labelSmall.copyWith(fontSize: 9, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
