import 'package:get/get.dart';
import 'package:salah/core/services/theme_service.dart';
import 'package:salah/core/services/localization_service.dart';
import 'package:salah/core/services/auth_service.dart';
import 'package:salah/core/routes/app_routes.dart';

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
  
  /// Change theme and save to storage
  Future<void> changeTheme(AppThemeMode mode) async {
    await _themeService.changeTheme(mode);
    update();
  }

  /// Logout from the app
  Future<void> logout() async {
    await Get.find<AuthService>().signOut();
    Get.offAllNamed(AppRoutes.login);
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
