import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/controller/dashboard_controller.dart';

/// GitHub-style prayer heatmap showing daily prayer completion over the last 6 months.
/// Each cell represents a day, colored by how many of the 5 daily prayers were logged.
class PrayerHeatmap extends StatelessWidget {
  const PrayerHeatmap({super.key});

  static const int _weeksToShow = 26; // ~6 months
  static const double _cellSize = 12.0;
  static const double _cellGap = 2.0;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();

    return Obx(() {
      final data = controller.dailyPrayerCounts;
      if (data.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: const EdgeInsets.all(AppDimensions.paddingMD),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.grid_on_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'prayer_heatmap'.tr,
                  style: AppFonts.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Heatmap grid
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true, // Start from latest (right side)
              child: _buildGrid(context, data),
            ),

            const SizedBox(height: 8),

            // Legend
            _buildLegend(),
          ],
        ),
      );
    });
  }

  Widget _buildGrid(BuildContext context, Map<DateTime, int> data) {
    // 1. Calculate dates
    final today = DateTime.now();
    // Start from 6 months ago, aligned to the start of that week
    final startDate = today.subtract(const Duration(days: 180));
    // Adjust start date to previous Saturday (or Sunday depending on locale, let's stick to Saturday for simple grid)
    // weekday: 1=Mon, ... 6=Sat, 7=Sun
    // We want to start column from Saturday (6)
    // Offset to subtract: (weekday % 7) + 1  <- approximate logic for fixed 7-row grid starting Sun/Sat

    // Simpler approach:
    // Rows = 7 (Sat, Sun, Mon, Tue, Wed, Thu, Fri)
    // Columns = Number of weeks needed to cover ~6 months

    List<Widget> columns = [];
    DateTime currentDate = startDate;

    // We need to keep adding weeks until we pass 'today'
    while (currentDate.isBefore(today) || currentDate.isAtSameMomentAs(today)) {
      List<Widget> weekCells = [];

      for (int i = 0; i < 7; i++) {
        // Normalize date to ignore time
        final date = DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
        );

        if (date.isAfter(today)) {
          // Future placeholder
          weekCells.add(_buildCell(null, date));
        } else {
          final count = data[date] ?? 0;
          weekCells.add(_buildCell(count, date));
        }

        currentDate = currentDate.add(const Duration(days: 1));
      }

      columns.add(
        Padding(
          padding: const EdgeInsets.only(left: 3),
          child: Column(children: weekCells),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true, // Always start from end (latest date)
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: columns,
      ),
    );
  }

  Widget _buildCell(int? count, DateTime date) {
    if (count == null) {
      return Container(
        width: 12, height: 12,
        margin: const EdgeInsets.only(bottom: 3),
      );
    }

    return Tooltip(
      message: '${date.day}/${date.month}: $count/5',
      child: Container(
        width: 12,
        height: 12,
        margin: const EdgeInsets.only(bottom: 3),
        decoration: BoxDecoration(
          color: _getColor(count),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Color _getColor(int count) {
    // Dynamic theme-based colors
    final base = AppColors.primary;
    if (count == 0) return AppColors.textSecondary.withValues(alpha: 0.1);
    if (count == 5) return base; // Full color

    // Shader from light to dark
    return base.withValues(alpha: 0.2 + (count * 0.15));
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          'no_prayers_logged'.tr,
          style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 4),
        for (int i = 0; i <= 5; i++)
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: _getColor(i),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        const SizedBox(width: 4),
        Text(
          '5/5',
          style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
