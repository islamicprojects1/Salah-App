import 'dart:async';
import 'package:get/get.dart';
import 'package:salah/core/services/notification_service.dart';
import 'package:salah/core/services/prayer_time_service.dart';
import 'package:salah/core/services/location_service.dart';
import 'package:salah/core/services/auth_service.dart';
import 'package:salah/core/services/firestore_service.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/data/models/prayer_time_model.dart';
import 'package:salah/data/models/prayer_log_model.dart';
import 'package:salah/data/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Controller for the main dashboard
class DashboardController extends GetxController {
  // ============================================================
  // DEPENDENCIES
  // ============================================================

  final PrayerTimeService _prayerService = Get.find<PrayerTimeService>();
  final LocationService _locationService = Get.find<LocationService>();
  final AuthService _authService = Get.find<AuthService>();
  final FirestoreService _firestore = Get.find<FirestoreService>();
  final NotificationService _notificationService =
      Get.find<NotificationService>();

  // ============================================================
  // OBSERVABLES
  // ============================================================

  final isLoading = true.obs;
  final currentPrayer = Rxn<PrayerTimeModel>();
  final nextPrayer = Rxn<PrayerTimeModel>();
  final timeUntilNextPrayer = ''.obs;
  final todayPrayers = <PrayerTimeModel>[].obs;
  final todayLogs = <PrayerLogModel>[].obs;
  final currentCity = ''.obs;
  final currentStreak = 0.obs;

  // Navigation
  final tabIndex = 0.obs;

  void changeTabIndex(int index) {
    tabIndex.value = index;
  }

  // Timer for countdown
  Timer? _timer;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void onInit() {
    super.onInit();
    _initDashboard();
  }

  Future<void> _initDashboard() async {
    isLoading.value = true;
    try {
      // 1. Get location if needed
      await _locationService.init();
      currentCity.value = _locationService.currentCity ?? 'تحديد الموقع...';

      // 2. Get prayer times
      await _loadPrayerTimes();

      // 3. Request Notification permissions
      await _notificationService.requestPermissions();

      // 4. Load today's logs from Firestore
      await _loadPrayerLogs();

      // 5. Load streak
      await _loadStreak();
      
      // 6. Schedule notifications (This call is now handled within _loadPrayerTimes)
      // Duplicate removed here
      
      // 7. Listen for pokes/encouragements
      _listenForEncouragements();
      
      // 8. Start timer
      _startTimer();
    } catch (e) {
      print('Error initializing dashboard: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // DATA LOADING
  // ============================================================

  Future<void> _loadPrayerTimes() async {
    final prayers = _prayerService.getTodayPrayers();
    todayPrayers.assignAll(prayers);
    _updateCurrentAndNextPrayer();
    _scheduleNotifications();
  }

  // Duplicate removed here

  Future<void> _loadPrayerLogs() async {
    final userId = _authService.userId;
    if (userId == null) return;

    _firestore.getTodayPrayerLogs(userId).listen((snapshot) {
      final logs = snapshot.docs
          .map((doc) => PrayerLogModel.fromFirestore(doc))
          .toList();
      todayLogs.assignAll(logs);
      _updateCurrentAndNextPrayer(); // Re-run to update status if needed
    });
  }

  Future<void> _loadStreak() async {
    final userId = _authService.userId;
    if (userId == null) return;

    final userDoc = await _firestore.getUser(userId);
    currentStreak.value = userDoc.data()?['currentStreak'] ?? 0;
  }

  Future<void> _scheduleNotifications() async {
    try {
      // Cancel pending first to avoid duplicates
      await _notificationService.cancelAllNotifications();
      
      for (int i = 0; i < todayPrayers.length; i++) {
        final prayer = todayPrayers[i];
        if (prayer.dateTime.isAfter(DateTime.now())) {
          await _notificationService.schedulePrayerNotification(
            id: i,
            prayerName: prayer.name,
            prayerTime: prayer.dateTime,
          );

          // Also schedule a reminder
          await _notificationService.schedulePrayerReminder(
            id: i + 100,
            prayerName: prayer.name,
            prayerTime: prayer.dateTime,
          );
        }
      }
    } catch (e) {
      print('Error scheduling notifications: $e');
    }
  }

  void _listenForEncouragements() {
    final userId = _authService.userId;
    if (userId == null) return;

    _firestore.getUserNotifications(userId).listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null && data['type'] == 'encouragement') {
            Get.snackbar(
              data['fromName'] ?? 'عضو عائلة',
              data['message'] ?? 'شجعك على الصلاة',
              backgroundColor: AppColors.secondary.withValues(alpha: 0.9),
              colorText: Colors.white,
              icon: Icon(Icons.bolt, color: Colors.orange),
              duration: const Duration(seconds: 5),
            );
          }
        }
      }
    });
  }

  void _updateCurrentAndNextPrayer() {
    final now = DateTime.now();

    // Find next prayer
    // TODO: Implement logic to find next prayer correctly wrapping to next day Fajr if needed
    // For MVP, simple logic:

    PrayerTimeModel? next;
    PrayerTimeModel? current;

    for (var prayer in todayPrayers) {
      if (prayer.dateTime.isAfter(now)) {
        next = prayer;
        break;
      }
      current = prayer;
    }

    // If no next prayer found today, it means next is Fajr tomorrow
    // For now, we'll handle day wrap in next iteration

    currentPrayer.value = current;
    nextPrayer.value = next;

    _updateTimeUntilNext();
  }

  // ============================================================
  // TIMER & PRESENTATION
  // ============================================================

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTimeUntilNext();
    });
  }

  void _updateTimeUntilNext() {
    if (nextPrayer.value == null) return;

    final now = DateTime.now();
    final difference = nextPrayer.value!.dateTime.difference(now);

    if (difference.isNegative) {
      // Refresh prayers if time passed
      _loadPrayerTimes();
      return;
    }

    final hours = difference.inHours;
    final minutes = difference.inMinutes.remainder(60);
    final seconds = difference.inSeconds.remainder(60);

    timeUntilNextPrayer.value =
        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  Future<void> logPrayer(PrayerTimeModel prayer) async {
    final userId = _authService.userId;
    if (userId == null) return;

    try {
      // Check if already logged
      final isLogged = todayLogs.any(
        (l) =>
            l.prayer.name.toLowerCase() == prayer.name.toLowerCase() ||
            (prayer.name == 'الشروق' && l.prayer == PrayerName.sunrise),
      );

      if (isLogged) {
        Get.snackbar('تنبيه', 'لقد قمت بتسجيل هذه الصلاة مسبقاً');
        return;
      }

      final log = PrayerLogModel.create(
        oderId: '', // Will be set by Firestore
        prayer: _mapNameToPrayerName(prayer.name),
        adhanTime: prayer.dateTime,
      );

      await _firestore.addPrayerLog(userId, log.toFirestore());
      
      // Update streak if it's the 5th prayer
      if (todayLogs.length + 1 >= 5) {
        final newStreak = await _firestore.updateStreak(userId);
        currentStreak.value = newStreak;
      }
      
      Get.snackbar('تم بنجاح', 'تقبل الله طاعاتكم');
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تسجيل الصلاة: $e');
    }
  }

  PrayerName _mapNameToPrayerName(String name) {
    switch (name) {
      case 'الفجر':
        return PrayerName.fajr;
      case 'الشروق':
        return PrayerName.sunrise;
      case 'الظهر':
        return PrayerName.dhuhr;
      case 'العصر':
        return PrayerName.asr;
      case 'المغرب':
        return PrayerName.maghrib;
      case 'العشاء':
        return PrayerName.isha;
      default:
        return PrayerName.fajr;
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
