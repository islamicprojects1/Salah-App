import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salah/core/helpers/prayer_names.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/storage_keys.dart';
import 'package:salah/core/feedback/app_feedback.dart';
import 'package:salah/core/services/auth_service.dart';
import 'package:salah/core/services/storage_service.dart';
import 'package:salah/core/services/location_service.dart';
import 'package:salah/core/services/notification_service.dart';
import 'package:salah/core/services/prayer_time_service.dart';
import 'package:salah/data/models/prayer_log_model.dart';
import 'package:salah/data/models/prayer_time_model.dart';
import 'package:salah/data/repositories/prayer_repository.dart';
import 'package:salah/data/repositories/user_repository.dart';

/// Dashboard controller – UI logic only. All data comes from [PrayerRepository],
/// [UserRepository], [PrayerTimeService], [LocationService], [NotificationService].
/// Reactive: observables are updated from repository streams/calls; UI uses Obx.
class DashboardController extends GetxController {
  final PrayerTimeService _prayerService;
  final LocationService _locationService;
  final AuthService _authService;
  final UserRepository _userRepo;
  final PrayerRepository _prayerRepo;
  final NotificationService _notificationService;

  DashboardController({
    required PrayerTimeService prayerService,
    required LocationService locationService,
    required AuthService authService,
    required UserRepository userRepo,
    required PrayerRepository prayerRepo,
    required NotificationService notificationService,
  })  : _prayerService = prayerService,
        _locationService = locationService,
        _authService = authService,
        _userRepo = userRepo,
        _prayerRepo = prayerRepo,
        _notificationService = notificationService;

  final isLoading = true.obs;
  final currentPrayer = Rxn<PrayerTimeModel>();
  final nextPrayer = Rxn<PrayerTimeModel>();
  final timeUntilNextPrayer = ''.obs;
  final todayPrayers = <PrayerTimeModel>[].obs;
  final todayLogs = <PrayerLogModel>[].obs;
  final currentCity = ''.obs;
  final currentStreak = 0.obs;
  final tabIndex = 0.obs;

  void changeTabIndex(int index) => tabIndex.value = index;

  Timer? _timer;
  StreamSubscription<List<PrayerLogModel>>? _logsSubscription;
  StreamSubscription<dynamic>? _notificationsSubscription;

  @override
  void onInit() {
    super.onInit();
    _syncLocationLabel();
    ever(_locationService.cityName, (_) => _syncLocationLabel());
    ever(_locationService.isUsingDefaultLocation, (_) => _syncLocationLabel());
    _initDashboard();
  }

  void _syncLocationLabel() {
    currentCity.value = _locationService.locationDisplayLabel;
  }

  Future<void> _initDashboard() async {
    isLoading.value = true;
    try {
      await _locationService.init();
      _syncLocationLabel();
      await _loadPrayerTimes();
      await _notificationService.requestPermissions();
      _loadPrayerLogs();
      await _loadStreak();
      _listenForEncouragements();
      _startTimer();
    } catch (_) {
      AppFeedback.showError('خطأ', 'فشل تحميل لوحة التحكم');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadPrayerTimes() async {
    final prayers = _prayerService.getTodayPrayers();
    todayPrayers.assignAll(prayers);
    _updateCurrentAndNextPrayer();
    _scheduleNotifications();
  }

  void _loadPrayerLogs() {
    final userId = _authService.userId;
    if (userId == null) return;
    _logsSubscription?.cancel();
    _logsSubscription = _prayerRepo.getTodayPrayerLogs(userId).listen((logs) {
      todayLogs.assignAll(logs);
      _updateCurrentAndNextPrayer();
    });
  }

  Future<void> _loadStreak() async {
    final userId = _authService.userId;
    if (userId == null) return;
    currentStreak.value = await _prayerRepo.getCurrentStreak(userId);
  }

  Future<void> _scheduleNotifications() async {
    try {
      final storage = Get.find<StorageService>();
      final enabled = storage.read<bool>(StorageKeys.notificationsEnabled) ?? true;
      await _notificationService.cancelAllNotifications();
      if (!enabled) return;
      for (int i = 0; i < todayPrayers.length; i++) {
        final prayer = todayPrayers[i];
        if (prayer.dateTime.isAfter(DateTime.now())) {
          await _notificationService.schedulePrayerNotification(
            id: i,
            prayerName: prayer.name,
            prayerTime: prayer.dateTime,
          );
          await _notificationService.schedulePrayerReminder(
            id: i + 100,
            prayerName: prayer.name,
            prayerTime: prayer.dateTime,
          );
        }
      }
    } catch (_) {
      AppFeedback.showError('تنبيه', 'فشل جدولة الإشعارات');
    }
  }

  void _listenForEncouragements() {
    final userId = _authService.userId;
    if (userId == null) return;
    _notificationsSubscription?.cancel();
    _notificationsSubscription = _userRepo.getUserNotificationsStream(userId).listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null && data['type'] == 'encouragement') {
            AppFeedback.showSnackbar(
              data['fromName'] ?? 'عضو عائلة',
              data['message'] ?? 'شجعك على الصلاة',
            );
          }
        }
      }
    });
  }

  void _updateCurrentAndNextPrayer() {
    final now = DateTime.now();
    PrayerTimeModel? next;
    PrayerTimeModel? current;
    for (var prayer in todayPrayers) {
      if (prayer.dateTime.isAfter(now)) {
        next = prayer;
        break;
      }
      current = prayer;
    }
    currentPrayer.value = current;
    nextPrayer.value = next;
    _updateTimeUntilNext();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTimeUntilNext());
  }

  void _updateTimeUntilNext() {
    if (nextPrayer.value == null) return;
    final difference = nextPrayer.value!.dateTime.difference(DateTime.now());
    if (difference.isNegative) {
      _loadPrayerTimes();
      return;
    }
    final hours = difference.inHours;
    final minutes = difference.inMinutes.remainder(60);
    final seconds = difference.inSeconds.remainder(60);
    timeUntilNextPrayer.value =
        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Log a prayer. Uses [PrayerRepository]; duplicate check via todayLogs + optional repo check.
  Future<void> logPrayer(PrayerTimeModel prayer) async {
    final userId = _authService.userId;
    if (userId == null) return;
    try {
      final isLogged = PrayerNames.isPrayerLogged(todayLogs, prayer.name, prayer.prayerType);
      if (isLogged) {
        AppFeedback.showSnackbar('تنبيه', 'لقد قمت بتسجيل هذه الصلاة مسبقاً');
        return;
      }
      final log = PrayerLogModel.create(
        oderId: '',
        prayer: PrayerNames.fromDisplayName(prayer.name),
        adhanTime: prayer.dateTime,
      );
      await _prayerRepo.addPrayerLog(userId: userId, log: log);
      if (todayLogs.length + 1 >= 5) {
        currentStreak.value = await _prayerRepo.updateStreak(userId);
      }
      AppFeedback.showSuccess('تم بنجاح', 'تقبل الله طاعاتكم');
    } catch (e) {
      AppFeedback.showError('خطأ', 'فشل تسجيل الصلاة: $e');
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    _logsSubscription?.cancel();
    _notificationsSubscription?.cancel();
    super.onClose();
  }
}
