import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/di/injection_container.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/services/cloudinary_service.dart';
import 'package:salah/core/widgets/app_dialogs.dart';
import 'package:salah/features/auth/data/models/user_model.dart';
import 'package:salah/features/auth/data/models/user_privacy_settings.dart';
import 'package:salah/features/auth/data/repositories/user_repository.dart';
import 'package:salah/features/auth/data/services/auth_service.dart';
import 'package:salah/features/family/controller/family_controller.dart';
import 'package:salah/features/prayer/data/services/notification_service.dart';
import 'package:salah/features/prayer/data/services/prayer_time_service.dart';
import 'package:salah/features/settings/data/services/localization_service.dart';
import 'package:salah/features/settings/data/services/theme_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:salah/core/feedback/app_feedback.dart';
import 'package:salah/core/constants/storage_keys.dart';
import 'package:salah/core/error/app_logger.dart';
import 'package:salah/core/routes/app_routes.dart';
import 'package:salah/core/services/audio_service.dart';
import 'package:salah/core/services/location_service.dart';
import 'package:salah/core/services/storage_service.dart';
import 'package:salah/features/settings/controller/settings_support_mixin.dart';

/// Settings controller – UI logic only. Theme/language/notifications in services or storage.
class SettingsController extends GetxController with SettingsSupportMixin {
  final _themeService = sl<ThemeService>();
  final _localizationService = sl<LocalizationService>();
  final _storage = sl<StorageService>();
  final LocationService _locationService = sl<LocationService>();
  // Lazy put might be better, but find is okay if registered
  final _userRepository = sl<UserRepository>();
  final _authService = sl<AuthService>();
  final _cloudinaryService = sl<CloudinaryService>();

  // Replaced currentUser (Firebase User) with userModel (Custom Model)
  final userModel = Rxn<UserModel>();

  // Expose underlying auth user for UI fallback (e.g. photo/email if userModel not loaded)
  Rx<User?> get currentUser => _authService.currentUser;

  // Keep underlying auth user for ID checks if needed; UI should use userModel
  User? get _authUser => _authService.currentUser.value;
  @override
  AuthService get authService => _authService;

  final RxBool notificationsEnabled = true.obs;
  final RxBool adhanEnabled = true.obs;
  final RxBool reminderEnabled = true.obs;
  final RxBool familyNotificationsEnabled = true.obs;

  // Individual Prayer Toggles
  final RxBool fajrNotif = true.obs;
  final RxBool dhuhrNotif = true.obs;
  final RxBool asrNotif = true.obs;
  final RxBool maghribNotif = true.obs;
  final RxBool ishaNotif = true.obs;

  final Rx<NotificationSoundMode> notificationSoundMode =
      NotificationSoundMode.adhan.obs;

  // Approaching & Takbeer
  final RxBool approachingAlertEnabled = false.obs;
  final RxInt approachingAlertMinutes = 15.obs;
  final RxBool takbeerAtPrayerEnabled = true.obs;

  String get locationDisplayLabel => _locationService.locationDisplayLabel;
  bool get isUsingDefaultLocation =>
      _locationService.isUsingDefaultLocation.value;
  bool get isLocationLoading => _locationService.isLoading.value;

  AppThemeMode get currentThemeMode => _themeService.currentThemeMode.value;
  AppLanguage get currentLanguage => _localizationService.currentLanguage.value;
  bool get isDarkMode => _themeService.isDarkMode;
  bool get isRTL => _localizationService.isRTL;

  // Prayer Settings
  final _prayerService = sl<PrayerTimeService>();
  // adhan.CalculationMethod get currentCalculationMethod =>
  //     _prayerService.currentCalculationMethod.value;
  // adhan.Madhab get currentMadhab => _prayerService.currentMadhab.value;

  @override
  void onInit() {
    super.onInit();
    _initPreferences();

    // Listen to Auth State
    ever(_authService.currentUser, (User? user) async {
      if (user != null) {
        await _fetchErrorMessage(user.uid);
      } else {
        userModel.value = null;
      }
    });

    // Initial fetch if already logged in
    if (_authService.currentUser.value != null) {
      _fetchErrorMessage(_authService.currentUser.value!.uid);
    }
  }

  void _initPreferences() {
    notificationsEnabled.value =
        _storage.read<bool>(StorageKeys.notificationsEnabled) ?? true;
    adhanEnabled.value =
        _storage.read<bool>(StorageKeys.adhanNotificationsEnabled) ?? true;
    reminderEnabled.value =
        _storage.read<bool>(StorageKeys.reminderNotification) ?? true;
    familyNotificationsEnabled.value =
        _storage.read<bool>(StorageKeys.familyNotification) ?? true;

    fajrNotif.value = _storage.read<bool>(StorageKeys.fajrNotification) ?? true;
    dhuhrNotif.value =
        _storage.read<bool>(StorageKeys.dhuhrNotification) ?? true;
    asrNotif.value = _storage.read<bool>(StorageKeys.asrNotification) ?? true;
    maghribNotif.value =
        _storage.read<bool>(StorageKeys.maghribNotification) ?? true;
    ishaNotif.value = _storage.read<bool>(StorageKeys.ishaNotification) ?? true;

    notificationSoundMode.value = _storage.getNotificationSoundMode();

    approachingAlertEnabled.value = _storage.approachingAlertEnabled;
    approachingAlertMinutes.value = _storage.approachingAlertMinutes;
    takbeerAtPrayerEnabled.value = _storage.takbeerAtPrayerEnabled;
  }

  Future<void> _fetchErrorMessage(String uid) async {
    try {
      final user = await _userRepository.getUser(uid);
      if (user != null) {
        userModel.value = user;
        // Sync offsets to storage for PrayerTimeService
        await _storage.write('prayer_offsets', user.prayerOffsets);
      }
    } catch (e) {
      AppLogger.debug('Settings: fetch user profile failed', e);
    }
  }

  // Future<void> updateCalculationMethod(adhan.CalculationMethod method) async {
  //   await _prayerService.setCalculationMethod(method);
  // }

  // Future<void> updateMadhab(adhan.Madhab madhab) async {
  //   await _prayerService.setMadhab(madhab);
  // }

  Future<void> changeTheme(AppThemeMode mode) async {
    await _themeService.changeTheme(mode);
  }

  Future<void> updatePrivacy(UserPrivacySettings settings) async {
    final uid = _authService.userId;
    if (uid == null) return;

    try {
      await _userRepository.updateUserProfile(
        userId: uid,
        updates: {'privacySettings': settings.toMap()},
      );
      // Update local state
      userModel.update((val) {
        if (val != null) {
          userModel.value = val.copyWith(privacySettings: settings);
        }
      });
    } catch (e) {
      AppFeedback.showError('error'.tr, 'failed_to_update_privacy'.tr);
    }
  }

  Future<void> updatePrayerOffset(String prayerName, int minutes) async {
    final uid = _authService.userId;
    if (uid == null) return;

    // Validation (e.g. max +/- 60 mins)
    if (minutes.abs() > 60) {
      AppFeedback.showError('error'.tr, 'offset_too_large'.tr);
      return;
    }

    try {
      final currentOffsets = Map<String, int>.from(
        userModel.value?.prayerOffsets ?? {},
      );
      currentOffsets[prayerName] = minutes;

      await _userRepository.updateUserProfile(
        userId: uid,
        updates: {'prayerOffsets': currentOffsets},
      );

      // Update local state and storage
      userModel.update((val) {
        if (val != null) {
          userModel.value = val.copyWith(prayerOffsets: currentOffsets);
        }
      });
      await _storage.write('prayer_offsets', currentOffsets);

      // Trigger strict recalculation
      if (Get.isRegistered<PrayerTimeService>()) {
        await sl<PrayerTimeService>().calculatePrayerTimes();
      }
    } catch (e) {
      AppFeedback.showError('error'.tr, 'update_failed'.tr);
    }
  }

  Future<void> exportPrayerData() async {
    final uid = _authService.userId;
    if (uid == null) return;

    AppDialogs.showLoading(message: 'exporting_data'.tr);
    try {
      // Fetch all logs
      final logsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('prayer_logs')
          .orderBy('adhanTime', descending: true)
          .get();

      final logs = logsSnapshot.docs;

      // Create CSV content
      final buffer = StringBuffer();
      buffer.writeln('Date,Time,Prayer,Status,Quality'); // Header

      final dateFormat = DateFormat('yyyy-MM-dd');
      final timeFormat = DateFormat('HH:mm');

      for (var doc in logs) {
        final data = doc.data();
        final timestamp = (data['adhanTime'] as Timestamp).toDate();
        final prayer = data['prayer'] ?? '';
        final status = data['status'] ?? 'completed';
        final quality = data['quality'] ?? '';

        buffer.writeln(
          '${dateFormat.format(timestamp)},${timeFormat.format(timestamp)},$prayer,$status,$quality',
        );
      }

      // Save to temporary file
      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/prayer_logs_${dateFormat.format(DateTime.now())}.csv';
      final file = File(path);
      await file.writeAsString(buffer.toString());

      AppDialogs.hideLoading();

      // Share file
      // Share file
      await Share.shareXFiles(
        [XFile(path)],
        subject: 'prayer_logs_export'.tr,
        text: 'here_is_my_prayer_data'.tr,
      );
    } catch (e) {
      AppDialogs.hideLoading();
      AppFeedback.showError('error'.tr, 'export_failed'.tr);
    }
  }

  Future<void> logout() async {
    if (Get.isRegistered<FamilyController>()) {
      Get.find<FamilyController>().cancelStreamsForLogout();
    }
    await _authService.signOut();
    Get.offAllNamed(AppRoutes.login);
  }

  Future<void> deleteAccount() async {
    final confirmed = await AppDialogs.confirm(
      title: 'delete_account'.tr,
      message: 'delete_account_confirmation'.tr,
      confirmText: 'delete'.tr,
      cancelText: 'cancel'.tr,
      isDestructive: true,
    );

    if (!confirmed) return;

    AppDialogs.showLoading(message: 'deleting_account'.tr);

    try {
      final userId = _authService.userId;
      if (userId != null) {
        await _userRepository.deleteUser(userId);
      }

      final success = await _authService.deleteAccount();

      AppDialogs.hideLoading();

      if (success) {
        Get.offAllNamed(AppRoutes.login);
        AppFeedback.showSuccess(
          'success'.tr,
          'account_deleted_successfully'.tr,
        );
      } else {
        final error = _authService.errorMessage.value.isNotEmpty
            ? _authService.errorMessage.value
            : 'delete_account_error'.tr;
        AppFeedback.showError('error'.tr, error);
      }
    } catch (e) {
      AppDialogs.hideLoading();
      AppFeedback.showError('error'.tr, 'delete_account_error'.tr);
    }
  }

  Future<void> updateDisplayName(String name) async {
    final uid = _authService.userId;
    if (uid == null) return;

    if (name.trim().isEmpty) {
      AppFeedback.showSnackbar('error'.tr, 'name_required'.tr, true);
      return;
    }

    AppDialogs.showLoading();
    try {
      await _authService.updateDisplayName(name);
      await _userRepository.updateUserProfile(
        userId: uid,
        updates: {'name': name},
      );

      // Local update
      userModel.update((val) {
        if (val != null) {
          userModel.value = val.copyWith(name: name);
        }
      });

      AppDialogs.hideLoading();
      Get.back(); // Close dialog if open
      AppFeedback.showSuccess('success'.tr, 'profile_updated'.tr);
    } catch (e) {
      AppDialogs.hideLoading();
      AppFeedback.showError('error'.tr, 'update_failed'.tr);
    }
  }

  Future<void> updateProfilePhoto() async {
    final uid = _authService.userId;
    if (uid == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );

    if (pickedFile == null) return;

    AppDialogs.showLoading();
    // try {
    // final File imageFile = File(pickedFile.path);
    // final url = await _cloudinaryService.uploadImage(
    //   imageFile,
    //   folder: 'user_profiles',
    // );

    // if (url != null) {
    //   await _authService.updateProfile(photoURL: url);
    //   await _userRepository.updateUserProfile(
    //     userId: uid,
    //     updates: {'photoUrl': url},
    //   );
    //     AppDialogs.hideLoading();
    //     AppFeedback.showSuccess('success'.tr, 'profile_updated'.tr);
    //   } else {
    //     throw Exception('Upload failed');
    //   }
    // } catch (e) {
    //   AppDialogs.hideLoading();
    //   AppFeedback.showError('error'.tr, 'update_failed'.tr);
    // }
  }

  Future<void> changeLanguage(AppLanguage language) async {
    await _localizationService.changeLanguage(language);
  }

  Future<void> toggleTheme() async {
    await _themeService.toggleTheme();
  }

  Future<void> toggleLanguage() async {
    await _localizationService.toggleLanguage();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    await _storage.write(StorageKeys.notificationsEnabled, value);
    notificationsEnabled.value = value;
  }

  Future<void> setAdhanEnabled(bool value) async {
    await _storage.write(StorageKeys.adhanNotificationsEnabled, value);
    adhanEnabled.value = value;
    _rescheduleNotifications();
  }

  Future<void> setReminderEnabled(bool value) async {
    await _storage.write(StorageKeys.reminderNotification, value);
    reminderEnabled.value = value;
    _rescheduleNotifications();
  }

  Future<void> setFamilyNotificationsEnabled(bool value) async {
    await _storage.write(StorageKeys.familyNotification, value);
    familyNotificationsEnabled.value = value;
  }

  Future<void> setNotificationSoundMode(NotificationSoundMode mode) async {
    await _storage.setNotificationSoundMode(mode);
    notificationSoundMode.value = mode;
    _rescheduleNotifications();
  }

  Future<void> setApproachingAlertEnabled(bool value) async {
    await _storage.setApproachingAlertEnabled(value);
    approachingAlertEnabled.value = value;
    _rescheduleNotifications();
  }

  Future<void> setApproachingAlertMinutes(int minutes) async {
    await _storage.setApproachingAlertMinutes(minutes);
    approachingAlertMinutes.value = minutes;
    _rescheduleNotifications();
  }

  Future<void> setTakbeerAtPrayerEnabled(bool value) async {
    await _storage.setTakbeerAtPrayerEnabled(value);
    takbeerAtPrayerEnabled.value = value;
    _rescheduleNotifications();
  }

  void _rescheduleNotifications() {
    if (sl.isRegistered<NotificationService>()) {
      sl<NotificationService>().rescheduleAllForToday();
    }
  }

  void playApproachPreview(PrayerName prayer) {
    if (sl.isRegistered<AudioService>()) {
      sl<AudioService>().playApproachSound(prayer);
    }
  }

  void playTakbeerPreview() {
    if (sl.isRegistered<AudioService>()) {
      sl<AudioService>().playTakbeer();
    }
  }

  Future<void> setPrayerNotif(String key, bool value) async {
    await _storage.write(key, value);
    switch (key) {
      case StorageKeys.fajrNotification:
        fajrNotif.value = value;
        break;
      case StorageKeys.dhuhrNotification:
        dhuhrNotif.value = value;
        break;
      case StorageKeys.asrNotification:
        asrNotif.value = value;
        break;
      case StorageKeys.maghribNotification:
        maghribNotif.value = value;
        break;
      case StorageKeys.ishaNotification:
        ishaNotif.value = value;
        break;
    }
    _rescheduleNotifications();
  }

  /// Refresh GPS location, reverse geocode, and recalculate prayer times.
  Future<void> refreshLocation() async {
    await _locationService.getCurrentLocation();
    if (Get.isRegistered<PrayerTimeService>()) {
      await Get.find<PrayerTimeService>().calculatePrayerTimes();
    }
  }
}
