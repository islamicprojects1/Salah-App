import 'package:get/get.dart';
import 'package:salah/core/di/injection_container.dart';
import 'package:salah/features/auth/data/services/auth_service.dart';
import 'package:salah/features/prayer/data/repositories/prayer_repository.dart';

/// Per-day summary for heatmap: date and whether all 5 prayers were logged.
class DayStat {
  final DateTime date;
  final bool isComplete;

  const DayStat({required this.date, required this.isComplete});
}

/// Controller for personal prayer stats: streak, completion %, heatmap.
class StatsController extends GetxController {
  final AuthService _authService = sl<AuthService>();
  final PrayerRepository _prayerRepo = sl<PrayerRepository>();

  final isLoading = true.obs;
  final currentStreak = 0.obs;
  final longestStreak = 0.obs;
  final completionPercent = 0.0.obs;
  final daysCompleteThisMonth = 0.obs;
  final totalDaysThisMonth = 0.obs;
  final monthHeatmap = <DayStat>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadStats();
  }

  Future<void> loadStats() async {
    final userId = _authService.userId;
    if (userId == null) {
      isLoading.value = false;
      return;
    }
    try {
      isLoading.value = true;
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = startOfMonth.add(const Duration(days: 32));
      final endOfMonthOnly = DateTime(now.year, now.month + 1 > 12 ? 1 : now.month + 1, 0);
      totalDaysThisMonth.value = endOfMonthOnly.day;

      final logs = await _prayerRepo.getPrayerLogsInRange(
        userId: userId,
        startDate: startOfMonth,
        endDate: endOfMonth,
      );

      currentStreak.value = await _prayerRepo.getCurrentStreak(userId);

      final dailyCount = <DateTime, int>{};
      for (final log in logs) {
        final d = DateTime(log.prayedAt.year, log.prayedAt.month, log.prayedAt.day);
        dailyCount[d] = (dailyCount[d] ?? 0) + 1;
      }

      final requiredPrayers = 5;
      int complete = 0;
      final heatmap = <DayStat>[];
      for (var day = 1; day <= endOfMonthOnly.day; day++) {
        final d = DateTime(now.year, now.month, day);
        final count = dailyCount[d] ?? 0;
        final isComplete = count >= requiredPrayers;
        if (isComplete) complete++;
        heatmap.add(DayStat(date: d, isComplete: isComplete));
      }
      daysCompleteThisMonth.value = complete;
      monthHeatmap.assignAll(heatmap);

      if (totalDaysThisMonth.value > 0) {
        completionPercent.value = (complete / totalDaysThisMonth.value) * 100;
      }

      longestStreak.value = _computeLongestStreak(heatmap);
    } catch (_) {
      // Keep defaults
    } finally {
      isLoading.value = false;
    }
  }

  int _computeLongestStreak(List<DayStat> days) {
    int maxStreak = 0;
    int current = 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (final stat in days) {
      if (stat.date.isAfter(today)) break;
      if (stat.isComplete) {
        current++;
        if (current > maxStreak) maxStreak = current;
      } else {
        current = 0;
      }
    }
    return maxStreak;
  }
}
