import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/features/stats/controller/stats_controller.dart';

/// Personal prayer stats: streak, completion %, heatmap for the month.
class StatsScreen extends GetView<StatsController> {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('my_stats'.tr),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: Lottie.asset(
              'assets/animations/loading.json',
              width: 120,
              height: 120,
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadStats,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppDimensions.paddingMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatCard(
                  title: 'streak'.tr,
                  value: '${controller.currentStreak.value}',
                  subtitle: 'stats_streak_days'.tr,
                  icon: Icons.local_fire_department_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 12),
                _buildStatCard(
                  title: 'stats_completion'.tr,
                  value: '${controller.completionPercent.value.toStringAsFixed(0)}%',
                  subtitle: 'stats_this_month'.trParams({
                    'count': '${controller.daysCompleteThisMonth.value}',
                    'total': '${controller.totalDaysThisMonth.value}',
                  }),
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.success,
                ),
                const SizedBox(height: 12),
                _buildStatCard(
                  title: 'stats_longest_streak'.tr,
                  value: '${controller.longestStreak.value}',
                  subtitle: 'stats_streak_days'.tr,
                  icon: Icons.emoji_events_outlined,
                  color: AppColors.warning,
                ),
                const SizedBox(height: 24),
                Text(
                  'stats_heatmap_title'.tr,
                  style: AppFonts.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildHeatmap(context),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLG),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.labelMedium.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppFonts.headlineSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppFonts.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmap(BuildContext context) {
    final list = controller.monthHeatmap;
    if (list.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (i) => SizedBox(
              width: 36,
              child: Text(
                _weekdayShort(i),
                style: AppFonts.labelSmall.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            )),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final stat = list[index];
              final isFuture = stat.date.isAfter(today);
              return Container(
                decoration: BoxDecoration(
                  color: isFuture
                      ? AppColors.textSecondary.withValues(alpha: 0.08)
                      : stat.isComplete
                          ? AppColors.success.withValues(alpha: 0.5)
                          : AppColors.textSecondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: isFuture
                      ? null
                      : Text(
                          '${stat.date.day}',
                          style: AppFonts.labelSmall.copyWith(
                            color: stat.isComplete
                                ? AppColors.success
                                : AppColors.textSecondary,
                            fontWeight: stat.isComplete ? FontWeight.bold : null,
                          ),
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _weekdayShort(int i) {
    const en = ['S','M','T','W','T','F','S'];
    return en[i];
  }
}
