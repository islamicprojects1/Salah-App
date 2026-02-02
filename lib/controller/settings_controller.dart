import 'package:get/get.dart';
import '../../core/services/theme_service.dart';
import '../../core/services/localization_service.dart';

/// Controller for Settings screen
/// 
/// Manages theme and language selection
class SettingsController extends GetxController {
  final _themeService = Get.find<ThemeService>();
  final _localizationService = Get.find<LocalizationService>();
  
  /// Current theme mode
  AppThemeMode get currentThemeMode => _themeService.currentThemeMode.value;
  
  /// Current language
  AppLanguage get currentLanguage => _localizationService.currentLanguage.value;
  
  /// Check if dark mode is active
  bool get isDarkMode => _themeService.isDarkMode;
  
  /// Check if current language is RTL
  bool get isRTL => _localizationService.isRTL;
  
  /// Change theme mode
  Future<void> changeTheme(AppThemeMode mode) async {
    await _themeService.changeTheme(mode);
    update();
  }
  
  /// Change language
  Future<void> changeLanguage(AppLanguage language) async {
    await _localizationService.changeLanguage(language);
    update();
  }
  
  /// Toggle theme between light and dark
  Future<void> toggleTheme() async {
    await _themeService.toggleTheme();
    update();
  }
  
  /// Toggle language between Arabic and English
  Future<void> toggleLanguage() async {
    await _localizationService.toggleLanguage();
    update();
  }
}
