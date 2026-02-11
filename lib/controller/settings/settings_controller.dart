import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:adhan/adhan.dart' as adhan;

import 'package:salah/core/constants/enums.dart';
import 'package:salah/data/repositories/user_repository.dart';
import 'package:salah/view/widgets/app_dialogs.dart';
import 'package:salah/core/constants/storage_keys.dart';
import 'package:salah/core/routes/app_routes.dart';
import 'package:salah/core/services/auth_service.dart';
import 'package:salah/core/services/localization_service.dart';
import 'package:salah/core/services/location_service.dart';
import 'package:salah/core/services/prayer_time_service.dart';
import 'package:salah/core/services/storage_service.dart';
import 'package:salah/core/services/theme_service.dart';

/// Settings controller – UI logic only. Theme/language/notifications in services or storage.
class SettingsController extends GetxController {
  final _themeService = Get.find<ThemeService>();
  final _localizationService = Get.find<LocalizationService>();
  final _storage = Get.find<StorageService>();
  final LocationService _locationService = Get.find<LocationService>();
  // Lazy put might be better, but find is okay if registered
  final _userRepository = Get.find<UserRepository>();
  final _authService = Get.find<AuthService>();

  final RxBool notificationsEnabled = true.obs;
  final RxBool adhanEnabled = true.obs;
  final RxBool reminderEnabled = true.obs;
  final RxBool familyNotificationsEnabled = true.obs;
  final Rx<NotificationSoundMode> notificationSoundMode =
      NotificationSoundMode.adhan.obs;
 
  String get locationDisplayLabel => _locationService.locationDisplayLabel;
  bool get isUsingDefaultLocation =>
      _locationService.isUsingDefaultLocation.value;
  bool get isLocationLoading => _locationService.isLoading.value;

  AppThemeMode get currentThemeMode => _themeService.currentThemeMode.value;
  AppLanguage get currentLanguage => _localizationService.currentLanguage.value;
  bool get isDarkMode => _themeService.isDarkMode;
  bool get isRTL => _localizationService.isRTL;

  // Prayer Settings
  final _prayerService = Get.find<PrayerTimeService>();
  adhan.CalculationMethod get currentCalculationMethod => _prayerService.currentCalculationMethod.value;
  adhan.Madhab get currentMadhab => _prayerService.currentMadhab.value;

  Future<void> updateCalculationMethod(adhan.CalculationMethod method) async {
    await _prayerService.setCalculationMethod(method);
  }

  Future<void> updateMadhab(adhan.Madhab madhab) async {
    await _prayerService.setMadhab(madhab);
  }

  Future<void> changeTheme(AppThemeMode mode) async {
    await _themeService.changeTheme(mode);
  }

  Future<void> logout() async {
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
        // 1. Delete user data
        await _userRepository.deleteUser(userId);
      }

      // 2. Delete auth account
      final success = await _authService.deleteAccount();

      AppDialogs.hideLoading();

      if (success) {
        Get.offAllNamed(AppRoutes.login);
        Get.snackbar('success'.tr, 'account_deleted_successfully'.tr);
      } else {
        final error = _authService.errorMessage.value.isNotEmpty
            ? _authService.errorMessage.value
            : 'delete_account_error'.tr;
        Get.snackbar('error'.tr, error);
      }
    } catch (e) {
      AppDialogs.hideLoading();
      Get.snackbar('error'.tr, 'delete_account_error'.tr);
    }
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

  @override
  void onInit() {
    super.onInit();
    notificationsEnabled.value =
        _storage.read<bool>(StorageKeys.notificationsEnabled) ?? true;
    adhanEnabled.value =
        _storage.read<bool>(StorageKeys.fajrNotification) ?? true;
    reminderEnabled.value =
        _storage.read<bool>(StorageKeys.reminderNotification) ?? true;
    familyNotificationsEnabled.value =
        _storage.read<bool>(StorageKeys.familyNotification) ?? true;
    notificationSoundMode.value = _storage.getNotificationSoundMode();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    await _storage.write(StorageKeys.notificationsEnabled, value);
    notificationsEnabled.value = value;
  }

  Future<void> setAdhanEnabled(bool value) async {
    await _storage.write(StorageKeys.fajrNotification, value);
    adhanEnabled.value = value;
  }

  Future<void> setReminderEnabled(bool value) async {
    await _storage.write(StorageKeys.reminderNotification, value);
    reminderEnabled.value = value;
  }

  Future<void> setFamilyNotificationsEnabled(bool value) async {
    await _storage.write(StorageKeys.familyNotification, value);
    familyNotificationsEnabled.value = value;
  }

  Future<void> setNotificationSoundMode(NotificationSoundMode mode) async {
    await _storage.setNotificationSoundMode(mode);
    notificationSoundMode.value = mode;
  }

  void showAboutDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('about'.tr),
        content: Text('${'app_name'.tr}\n${'version'.tr}: 1.0.0'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('close'.tr)),
        ],
      ),
    );
  }

  Future<void> shareApp() async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: 'share_app_text'.tr,
          subject: 'app_name'.tr,
        ),
      );
    } catch (_) {}
  }

  void openRateApp() {
    // When app is on store: launch store URL
    Get.snackbar('rate_app'.tr, 'coming_soon_store'.tr);
  }

  /// Refresh GPS location, reverse geocode, and recalculate prayer times.
  Future<void> refreshLocation() async {
    await _locationService.getCurrentLocation();
    if (Get.isRegistered<PrayerTimeService>()) {
      await Get.find<PrayerTimeService>().calculatePrayerTimes();
    }
  }
}
