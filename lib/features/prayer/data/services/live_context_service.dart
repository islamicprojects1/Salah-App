import 'dart:async';

import 'package:get/get.dart';
import 'package:salah/core/di/injection_container.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/services/audio_service.dart';
import 'package:salah/features/auth/data/services/auth_service.dart';
import 'package:salah/features/prayer/data/models/live_context_models.dart';
import 'package:salah/features/prayer/data/models/prayer_log_model.dart';
import 'package:salah/features/prayer/data/models/prayer_time_model.dart';
import 'package:salah/features/prayer/data/repositories/prayer_repository.dart';
import 'package:salah/features/prayer/data/services/prayer_time_service.dart';
import 'package:salah/features/prayer/data/services/qada_detection_service.dart';

/// LiveContextService
///
/// Central orchestrator that understands:
/// - current prayer & next prayer (based on [PrayerTimeService])
/// - today's logged prayers (via [PrayerRepository])
/// - high-level status for the current prayer and daily summary
///
/// UI (e.g. Dashboard/Home) should bind to:
/// - [prayerContext] for current card/countdown
/// - [todaySummary] for progress/streak-like visuals
class LiveContextService extends GetxService {
  final PrayerTimeService _prayerTimeService;
  final PrayerRepository _prayerRepository;
  final AuthService _authService;
  final AudioService _audioService = sl<AudioService>();

  LiveContextService({
    required PrayerTimeService prayerTimeService,
    required PrayerRepository prayerRepository,
    required AuthService authService,
  }) : _prayerTimeService = prayerTimeService,
       _prayerRepository = prayerRepository,
       _authService = authService;

  // Observables
  final Rx<PrayerContextModel> prayerContext = PrayerContextModel.empty().obs;
  final Rx<DailyPrayersSummary> todaySummary = DailyPrayersSummary.empty(DateTime.now()).obs;
  final RxList<PrayerLogModel> todayLogs = <PrayerLogModel>[].obs;

  // Internal state
  Timer? _timer;
  StreamSubscription<List<PrayerLogModel>>? _logsSubscription;
  PrayerName? _lastPlayedPrayer;
  DateTime? _currentDate;

  bool _isInitialized = false;

  Future<LiveContextService> init() async {
    if (_isInitialized) return this;
    _isInitialized = true;
    _currentDate = DateTime.now();
    _subscribeToTodayLogs();
    _recomputeContext();
    _startTimer();
    return this;
  }

  /// Should be called when a prayer is logged from anywhere
  /// (e.g. DashboardController, notification action).
  Future<void> onPrayerLogged() async {
    // Stop adhan if it's playing when user logs the prayer
    await _audioService.stop();

    // Refresh today's logs (stream may not re-emit when logging offline)
    final userId = _authService.userId;
    if (userId != null) {
      final logs = await _prayerRepository.getTodayPrayerLogsOnce(userId);
      todayLogs.assignAll(logs);
    }
    _recomputeContext();
  }

  void _subscribeToTodayLogs() {
    final userId = _authService.userId;
    if (userId == null) return;
    _logsSubscription?.cancel();
    _logsSubscription = _prayerRepository.getTodayPrayerLogs(userId).listen((
      logs,
    ) {
      todayLogs.assignAll(logs);
      _recomputeContext();
    });
  }

  void _startTimer() {
    _timer?.cancel();
    // Every second so countdown (timeUntilNext) stays accurate; day summary updates with logs
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _recomputeContext(),
    );
  }

  void _recomputeContext() {
    final now = DateTime.now();

    // Detect midnight rollover
    if (_currentDate != null) {
      final lastDate = DateTime(
        _currentDate!.year,
        _currentDate!.month,
        _currentDate!.day,
      );
      final today = DateTime(now.year, now.month, now.day);
      if (today.isAfter(lastDate)) {
        _currentDate = now;
        _lastPlayedPrayer = null;
        _subscribeToTodayLogs(); // Re-subscribe for new day
        // Trigger qada check for yesterday
        if (Get.isRegistered<QadaDetectionService>()) {
          Get.find<QadaDetectionService>().checkForUnloggedPrayers();
        }
      }
    }

    final prayers = _prayerTimeService.getTodayPrayers();
    if (prayers.isEmpty) {
      prayerContext.value = PrayerContextModel.empty();
      todaySummary.value = DailyPrayersSummary.empty(now);
      return;
    }

    PrayerTimeModel? current;
    PrayerTimeModel? next;

    for (final prayer in prayers) {
      if (prayer.dateTime.isAfter(now)) {
        next = prayer;
        break;
      }
      if (prayer.prayerType != PrayerName.sunrise) {
        current = prayer;
      }
    }

    // Trigger Adhan logic
    if (current != null &&
        current.prayerType != _lastPlayedPrayer &&
        now.difference(current.dateTime).inSeconds < 30 &&
        now.difference(current.dateTime).inSeconds >= 0) {
      _lastPlayedPrayer = current.prayerType;
      _audioService.playAdhan();
    }

    final status = _computeStatusForCurrent(now, current, next);
    final timeUntilNext = next?.dateTime.difference(now);

    prayerContext.value = PrayerContextModel(
      currentPrayer: current,
      nextPrayer: next,
      status: status,
      timeUntilNext: timeUntilNext,
    );

    todaySummary.value = _buildDaySummary(now);
  }

  LivePrayerStatus _computeStatusForCurrent(
    DateTime now,
    PrayerTimeModel? current,
    PrayerTimeModel? next,
  ) {
    if (current == null) {
      // قبل الفجر
      return LivePrayerStatus.notStarted;
    }

    final currentName = current.prayerType;
    final log = todayLogs.firstWhereOrNull((l) => l.prayer == currentName);

    // Determine prayer time window using PrayerTimeRange helper
    final todayPrayers = _prayerTimeService.getTodayPrayers();
    PrayerTimeRange? range;
    if (todayPrayers.isNotEmpty) {
      range = PrayerTimeRange.fromPrayerModels(
        prayers: todayPrayers,
        prayer: currentName,
      );
    }

    if (log == null) {
      // لم يُسجَّل بعد
      if (range != null && now.isAfter(range.nextPrayerTime)) {
        return LivePrayerStatus.missed;
      }
      if (now.isBefore(current.dateTime)) {
        return LivePrayerStatus.notStarted;
      }
      return LivePrayerStatus.pending;
    }

    // Logged: decide if on-time or late based on quality
    switch (log.quality) {
      case PrayerQuality.early:
      case PrayerQuality.onTime:
        return LivePrayerStatus.prayedOnTime;
      case PrayerQuality.late:
        return LivePrayerStatus.prayedLate;
      case PrayerQuality.missed:
        return LivePrayerStatus.missed;
    }
  }

  DailyPrayersSummary _buildDaySummary(DateTime now) {
    final date = DateTime(now.year, now.month, now.day);
    final map = <PrayerName, PrayerLogModel?>{
      PrayerName.fajr: null,
      PrayerName.dhuhr: null,
      PrayerName.asr: null,
      PrayerName.maghrib: null,
      PrayerName.isha: null,
    };

    for (final log in todayLogs) {
      if (map.containsKey(log.prayer) && map[log.prayer] == null) {
        map[log.prayer] = log;
      }
    }
    return DailyPrayersSummary(date: date, prayers: map);
  }

  @override
  void onClose() {
    _timer?.cancel();
    _logsSubscription?.cancel();
    super.onClose();
  }
}
