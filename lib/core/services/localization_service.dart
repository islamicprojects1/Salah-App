import 'dart:ui';
import 'package:get/get.dart';
import 'storage_service.dart';

/// Supported languages
enum AppLanguage {
  arabic('ar', 'العربية', TextDirection.rtl),
  english('en', 'English', TextDirection.ltr);
  
  final String code;
  final String name;
  final TextDirection direction;
  
  const AppLanguage(this.code, this.name, this.direction);
  
  /// Get locale from language
  Locale get locale => Locale(code);
  
  /// Get language from code
  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => AppLanguage.arabic,
    );
  }
}

/// Service for managing app localization
/// 
/// Handles language switching and persistence using GetStorage
class LocalizationService extends GetxService {
  final _storageService = Get.find<StorageService>();
  
  /// Current language
  final Rx<AppLanguage> currentLanguage = AppLanguage.arabic.obs;
  
  /// Supported locales
  static final List<Locale> supportedLocales = [
    const Locale('ar'),
    const Locale('en'),
  ];
  
  /// Fallback locale (Arabic)
  static const Locale fallbackLocale = Locale('ar');
  
  /// Initialize localization service
  Future<LocalizationService> init() async {
    _loadSavedLanguage();
    return this;
  }
  
  /// Load saved language from storage
  void _loadSavedLanguage() {
    final savedLanguage = _storageService.getLanguage();
    currentLanguage.value = AppLanguage.fromCode(savedLanguage);
    _applyLanguage();
  }
  
  /// Get current locale
  Locale get currentLocale => currentLanguage.value.locale;
  
  /// Check if current language is RTL
  bool get isRTL => currentLanguage.value.direction == TextDirection.rtl;
  
  /// Change app language
  Future<void> changeLanguage(AppLanguage language) async {
    currentLanguage.value = language;
    await _storageService.setLanguage(language.code);
    _applyLanguage();
  }
  
  /// Apply the current language
  void _applyLanguage() {
    Get.updateLocale(currentLanguage.value.locale);
  }
  
  /// Toggle between Arabic and English
  Future<void> toggleLanguage() async {
    if (currentLanguage.value == AppLanguage.arabic) {
      await changeLanguage(AppLanguage.english);
    } else {
      await changeLanguage(AppLanguage.arabic);
    }
  }
  
  /// Get device locale or fallback
  static Locale getDeviceLocale() {
    final deviceLocale = Get.deviceLocale;
    if (deviceLocale != null && 
        supportedLocales.any((l) => l.languageCode == deviceLocale.languageCode)) {
      return deviceLocale;
    }
    return fallbackLocale;
  }
}
