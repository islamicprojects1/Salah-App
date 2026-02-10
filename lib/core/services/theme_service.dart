import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/enums.dart';
import '../theme/app_theme.dart';
import 'storage_service.dart';

/// Service for managing app theme
/// 
/// Handles theme switching and persistence using GetStorage
class ThemeService extends GetxService {
  final _storageService = Get.find<StorageService>();
  
  /// Current theme mode
  final Rx<AppThemeMode> currentThemeMode = AppThemeMode.system.obs;
  
  /// Initialize theme service
  Future<ThemeService> init() async {
    _loadSavedTheme();
    return this;
  }
  
  /// Load saved theme from storage
  void _loadSavedTheme() {
    final savedTheme = _storageService.getThemeMode();
    currentThemeMode.value = _stringToThemeMode(savedTheme);
    _applyTheme();
  }
  
  /// Convert string to AppThemeMode
  AppThemeMode _stringToThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      default:
        return AppThemeMode.system;
    }
  }
  
  /// Convert AppThemeMode to string
  String _themeModeToString(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'light';
      case AppThemeMode.dark:
        return 'dark';
      case AppThemeMode.system:
        return 'system';
    }
  }
  
  /// Get the current ThemeMode for GetMaterialApp
  ThemeMode get themeMode {
    switch (currentThemeMode.value) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
  
  /// Check if current theme is dark
  bool get isDarkMode {
    if (currentThemeMode.value == AppThemeMode.system) {
      return Get.isPlatformDarkMode;
    }
    return currentThemeMode.value == AppThemeMode.dark;
  }
  
  /// Change theme mode
  Future<void> changeTheme(AppThemeMode mode) async {
    currentThemeMode.value = mode;
    await _storageService.setThemeMode(_themeModeToString(mode));
    _applyTheme();
  }
  
  /// Apply the current theme
  void _applyTheme() {
    Get.changeThemeMode(themeMode);
  }
  
  /// Toggle between light and dark theme
  Future<void> toggleTheme() async {
    if (isDarkMode) {
      await changeTheme(AppThemeMode.light);
    } else {
      await changeTheme(AppThemeMode.dark);
    }
  }
  
  /// Get light theme
  ThemeData get lightTheme => AppTheme.lightTheme;
  
  /// Get dark theme
  ThemeData get darkTheme => AppTheme.darkTheme;
}
