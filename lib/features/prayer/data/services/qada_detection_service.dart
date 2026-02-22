import 'dart:async';
import 'package:get/get.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/services/storage_service.dart';
import 'package:salah/core/constants/storage_keys.dart';
import 'package:salah/core/helpers/prayer_names.dart';
import 'package:salah/features/auth/data/services/auth_service.dart';
import 'package:salah/features/prayer/data/repositories/prayer_repository.dart';
import 'package:salah/features/prayer/data/services/notification_service.dart';
import 'package:salah/features/prayer/data/services/prayer_time_service.dart';

/// Model for an unlogged prayer (used for qada detection and UI)
class UnloggedPrayerInfo {
  final PrayerName prayer;
  final DateTime adhanTime;
  final DateTime date;

  UnloggedPrayerInfo({
    required this.prayer,
    required this.adhanTime,
    required this.date,
  });

  String get displayName => PrayerNames.displayName(prayer);

  /// Key for uniqueness: "2026-02-12_fajr"
  String get key => '${date.toIso8601String().substring(0, 10)}_${prayer.name}';
}

/// Group of unlogged prayers for a single day (for "by day" qada UI).
class QadaDayGroup {
  final DateTime date;
  final String label;
  final List<UnloggedPrayerInfo> prayers;

  const QadaDayGroup({
    required this.date,
    required this.label,
    required this.prayers,
  });

  int get count => prayers.length;
}

/// QadaDetectionService — intelligently detects unlogged/missed prayers.
///
/// Runs on:
/// - App resume (foreground)
/// - Midnight rollover (date change)
/// - After a prayer is logged (to refresh state)
///
/// Exposes reactive lists for UI consumption.
class QadaDetectionService extends GetxService {
  final PrayerTimeService _prayerTimeService;
  final PrayerRepository _prayerRepo;
  final AuthService _authService;
  final StorageService _storageService;

  QadaDetectionService({
    required PrayerTimeService prayerTimeService,
    required PrayerRepository prayerRepo,
    required AuthService authService,
    required StorageService storageService,
  }) : _prayerTimeService = prayerTimeService,
       _prayerRepo = prayerRepo,
       _authService = authService,
       _storageService = storageService;

  // ============================================================
  // REACTIVE STATE
  // ============================================================

  /// Unlogged prayers from today (past adhan time but not logged)
  final todayUnlogged = <UnloggedPrayerInfo>[].obs;

  /// Unlogged prayers from yesterday
  final yesterdayUnlogged = <UnloggedPrayerInfo>[].obs;

  /// Combined pending qada (today + yesterday)
  final allPendingQada = <UnloggedPrayerInfo>[].obs;

  /// Whether yesterday has unlogged prayers
  final hasYesterdayUnlogged = false.obs;

  /// Whether today has unlogged prayers (past ones only)
  final hasTodayUnlogged = false.obs;

  /// Total count of pending qada prayers
  final pendingQadaCount = 0.obs;

  /// Date we last checked qada (to detect midnight rollover)
  DateTime? _lastCheckedDate;

  /// Timer for scheduling evening qada review notification
  Timer? _eveningReviewTimer;

  bool _isInitialized = false;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  Future<QadaDetectionService> init() async {
    if (_isInitialized) return this;
    _isInitialized = true;
    _lastCheckedDate = DateTime.now();
    await checkForUnloggedPrayers();
    _scheduleEveningReviewCheck();
    return this;
  }

  // ============================================================
  // CORE DETECTION
  // ============================================================

  /// Check for unlogged prayers. Called on:
  /// - App init
  /// - App resume (foreground)
  /// - Midnight rollover
  /// - After prayer log (to refresh counts)
  Future<void> checkForUnloggedPrayers({int daysBack = 1}) async {
    final userId = _authService.userId;
    if (userId == null) return;

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // --- Check today's unlogged ---
      final todayResult = await _getUnloggedForDate(userId, today, now);
      todayUnlogged.assignAll(todayResult);
      hasTodayUnlogged.value = todayResult.isNotEmpty;

      // --- Check yesterday's unlogged ---
      if (daysBack >= 1) {
        final yesterday = today.subtract(const Duration(days: 1));
        final endOfYesterday = today; // midnight = end of yesterday
        final yesterdayResult = await _getUnloggedForDate(
          userId,
          yesterday,
          endOfYesterday,
        );
        yesterdayUnlogged.assignAll(yesterdayResult);
        hasYesterdayUnlogged.value = yesterdayResult.isNotEmpty;
      }

      // Combine
      allPendingQada.assignAll([...yesterdayUnlogged, ...todayUnlogged]);
      pendingQadaCount.value = allPendingQada.length;

      // Detect midnight rollover
      if (_lastCheckedDate != null) {
        final lastDate = DateTime(
          _lastCheckedDate!.year,
          _lastCheckedDate!.month,
          _lastCheckedDate!.day,
        );
        if (today.isAfter(lastDate)) {
          // Date changed! Reschedule evening review
          _scheduleEveningReviewCheck();
        }
      }
      _lastCheckedDate = now;
    } catch (_) {
      // Silently fail — qada detection is non-critical
    }
  }

  /// Get unlogged prayers for a specific date.
  /// [cutoffTime] limits which prayers are considered "past" (for today, it's now;
  /// for yesterday, it's midnight/end of day).
  Future<List<UnloggedPrayerInfo>> _getUnloggedForDate(
    String userId,
    DateTime date,
    DateTime cutoffTime,
  ) async {
    final result = <UnloggedPrayerInfo>[];

    // Get prayer times for the date
    final prayers = await _prayerTimeService.getPrayersForDate(date);

    // Get logs for that date
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final logs = await _prayerRepo.getPrayerLogsInRange(
      userId: userId,
      startDate: startOfDay,
      endDate: endOfDay,
    );

    for (final prayer in prayers) {
      // Skip sunrise
      if (prayer.prayerType == PrayerName.sunrise) continue;
      if (prayer.prayerType == null) continue;

      // Only consider prayers whose time has passed
      if (prayer.dateTime.isAfter(cutoffTime)) continue;

      // Check if already logged
      final hasLog = logs.any((l) => l.prayer == prayer.prayerType);
      if (!hasLog) {
        result.add(
          UnloggedPrayerInfo(
            prayer: prayer.prayerType!,
            adhanTime: prayer.dateTime,
            date: startOfDay,
          ),
        );
      }
    }

    return result;
  }

  /// Unlogged prayers grouped by day for the last [lastDays] days (today + past).
  /// Used by Missed Prayers screen for "by day" view and "I prayed all for this day".
  Future<List<QadaDayGroup>> getUnloggedByDay({int lastDays = 7}) async {
    final userId = _authService.userId;
    if (userId == null) return [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final result = <QadaDayGroup>[];

    for (var i = 0; i < lastDays; i++) {
      final date = today.subtract(Duration(days: i));
      final cutoffTime = i == 0 ? now : date.add(const Duration(days: 1));
      final list = await _getUnloggedForDate(userId, date, cutoffTime);
      if (list.isEmpty) continue;

      final label = _dayLabel(date, today);
      result.add(QadaDayGroup(date: date, label: label, prayers: list));
    }

    return result;
  }

  static String _dayLabel(DateTime date, DateTime today) {
    final d = DateTime(date.year, date.month, date.day);
    final t = DateTime(today.year, today.month, today.day);
    if (d == t) return 'qada_today'.tr;
    final yesterday = t.subtract(const Duration(days: 1));
    if (d == yesterday) return 'qada_yesterday'.tr;
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  // ============================================================
  // EVENING REVIEW SCHEDULING
  // ============================================================

  /// Schedule a check at 9 PM to see if user has unlogged prayers today.
  /// If so, fire a notification prompting them to review.
  void _scheduleEveningReviewCheck() {
    _eveningReviewTimer?.cancel();
    final now = DateTime.now();
    final tonight9pm = DateTime(now.year, now.month, now.day, 21, 0, 0);

    if (now.isBefore(tonight9pm)) {
      final delay = tonight9pm.difference(now);
      _eveningReviewTimer = Timer(delay, () => _fireEveningReviewIfNeeded());
    }
  }

  /// Check if there are unlogged prayers and fire a review notification.
  Future<void> _fireEveningReviewIfNeeded() async {
    await checkForUnloggedPrayers(daysBack: 0);
    if (todayUnlogged.isNotEmpty) {
      _fireQadaReviewNotification(todayUnlogged);
    }
  }

  /// Fire a local notification prompting the user to review unlogged prayers.
  void _fireQadaReviewNotification(List<UnloggedPrayerInfo> unlogged) {
    if (!Get.isRegistered<NotificationService>()) return;
    try {
      final notifService = Get.find<NotificationService>();
      final prayerNames = unlogged.map((u) => u.displayName).join('، ');
      notifService.showNotification(
        id: 998, // Fixed ID for qada review
        title: 'qada_review_title'.tr,
        body: 'qada_review_body'.trParams({
          'prayers': prayerNames,
          'count': '${unlogged.length}',
        }),
      );
    } catch (_) {}
  }

  // ============================================================
  // PUBLIC API
  // ============================================================

  /// Called after a prayer is logged — refreshes qada state.
  Future<void> onPrayerLogged() async {
    await checkForUnloggedPrayers();
  }

  /// Check if midnight has passed since last check (for LiveContextService).
  bool hasMidnightPassed() {
    if (_lastCheckedDate == null) return false;
    final now = DateTime.now();
    final lastDate = DateTime(
      _lastCheckedDate!.year,
      _lastCheckedDate!.month,
      _lastCheckedDate!.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    return today.isAfter(lastDate);
  }

  // ============================================================
  // SNOOZE ESCALATION
  // ============================================================

  /// Get the current snooze count for a prayer (tracks escalation).
  int getSnoozeCount(PrayerName prayer) {
    final key = '${StorageKeys.userPatternPrefix}snooze_${prayer.name}';
    return _storageService.read<int>(key) ?? 0;
  }

  /// Increment snooze count and return new delay duration.
  /// Max 2 snoozes: 1st → 10 min, 2nd → 30 min (final reminder with سأقضيها), 3rd+ → null.
  Duration? incrementSnoozeAndGetDelay(PrayerName prayer) {
    final key = '${StorageKeys.userPatternPrefix}snooze_${prayer.name}';
    final current = getSnoozeCount(prayer);
    final newCount = current + 1;
    _storageService.write(key, newCount);

    switch (newCount) {
      case 1:
        return const Duration(minutes: 10);
      case 2:
        return const Duration(minutes: 30);
      default:
        return null;
    }
  }

  /// True if next reminder should show "سأقضيها" (after 2nd snooze).
  bool isNextReminderFinal(PrayerName prayer) => getSnoozeCount(prayer) >= 2;

  /// Reset snooze count for a prayer (called when prayer is logged).
  void resetSnoozeCount(PrayerName prayer) {
    final key = '${StorageKeys.userPatternPrefix}snooze_${prayer.name}';
    _storageService.remove(key);
  }

  /// Reset all snooze counts (called on new day).
  void resetAllSnoozeCounts() {
    for (final prayer in PrayerName.values) {
      if (prayer == PrayerName.sunrise) continue;
      resetSnoozeCount(prayer);
    }
  }

  // ============================================================
  // CLEANUP
  // ============================================================

  @override
  void onClose() {
    _eveningReviewTimer?.cancel();
    super.onClose();
  }
}
