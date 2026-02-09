import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
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

  final RxBool notificationsEnabled = true.obs;

  String get locationDisplayLabel => _locationService.locationDisplayLabel;
  bool get isUsingDefaultLocation => _locationService.isUsingDefaultLocation.value;
  bool get isLocationLoading => _locationService.isLoading.value;

  AppThemeMode get currentThemeMode => _themeService.currentThemeMode.value;
  AppLanguage get currentLanguage => _localizationService.currentLanguage.value;
  bool get isDarkMode => _themeService.isDarkMode;
  bool get isRTL => _localizationService.isRTL;

  Future<void> changeTheme(AppThemeMode mode) async {
    await _themeService.changeTheme(mode);
  }

  Future<void> logout() async {
    await Get.find<AuthService>().signOut();
    Get.offAllNamed(AppRoutes.login);
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
    notificationsEnabled.value = _storage.read<bool>(StorageKeys.notificationsEnabled) ?? true;
  }

  Future<void> setNotificationsEnabled(bool value) async {
    await _storage.write(StorageKeys.notificationsEnabled, value);
    notificationsEnabled.value = value;
  }

  void showAboutDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('about'.tr),
        content: Text('${'app_name'.tr}\n${'version'.tr}: 1.0.0'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('close'.tr),
          ),
        ],
      ),
    );
  }

  Future<void> shareApp() async {
    try {
      await SharePlus.instance.share(ShareParams(
        text: 'تحميل تطبيق صلاة - متابعة الصلوات والعائلة',
        subject: 'app_name'.tr,
      ));
    } catch (_) {}
  }

  void openRateApp() {
    // When app is on store: launch store URL
    Get.snackbar('rate_app'.tr, 'متوفر قريباً على متجر التطبيقات');
  }

  /// Refresh GPS location, reverse geocode, and recalculate prayer times.
  Future<void> refreshLocation() async {
    await _locationService.getCurrentLocation();
    if (Get.isRegistered<PrayerTimeService>()) {
      await Get.find<PrayerTimeService>().calculatePrayerTimes();
    }
  }
}
