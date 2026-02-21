import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/di/injection_container.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/features/settings/data/services/localization_service.dart';
import 'package:salah/core/theme/app_colors.dart';

/// App font families & typography styles
class AppFonts {
  AppFonts._();

  // ============================================================
  // FONT FAMILIES
  // ============================================================

  static const String arabic = 'Tajawal';
  static const String english = 'Poppins';

  /// Returns true if current language is Arabic
  static bool get _isArabic {
    try {
      final localizationService = sl<LocalizationService>();
      return localizationService.currentLanguage.value == AppLanguage.arabic;
    } catch (_) {
      return Get.locale?.languageCode == 'ar';
    }
  }

  /// Get current font family based on locale
  static String get current {
    try {
      final localizationService = sl<LocalizationService>();
      return localizationService.currentLanguage.value == AppLanguage.arabic
          ? arabic
          : english;
    } catch (_) {
      return Get.locale?.languageCode == 'ar' ? arabic : english;
    }
  }

  // ============================================================
  // DISPLAY STYLES
  // ============================================================

  static TextStyle get displayLarge => TextStyle(
    fontFamily: current,
    fontSize: 48,
    fontWeight: FontWeight.bold,
    height: 1.1,
    letterSpacing: _isArabic ? 0 : -0.5,
    color: AppColors.textPrimary,
  );

  static TextStyle get displayMedium => TextStyle(
    fontFamily: current,
    fontSize: 36,
    fontWeight: FontWeight.bold,
    height: 1.2,
    letterSpacing: _isArabic ? 0 : -0.25,
    color: AppColors.textPrimary,
  );

  static TextStyle get displaySmall => TextStyle(
    fontFamily: current,
    fontSize: 30,
    fontWeight: FontWeight.bold,
    height: 1.2,
    letterSpacing: _isArabic ? 0 : 0,
    color: AppColors.textPrimary,
  );

  // ============================================================
  // HEADLINE STYLES
  // ============================================================

  static TextStyle get headlineLarge => TextStyle(
    fontFamily: current,
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.3,
    letterSpacing: _isArabic ? 0 : 0,
    color: AppColors.textPrimary,
  );

  static TextStyle get headlineMedium => TextStyle(
    fontFamily: current,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.3,
    letterSpacing: _isArabic ? 0 : 0,
    color: AppColors.textPrimary,
  );

  static TextStyle get headlineSmall => TextStyle(
    fontFamily: current,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: _isArabic ? 0 : 0,
    color: AppColors.textPrimary,
  );

  // ============================================================
  // TITLE STYLES
  // ============================================================

  static TextStyle get titleLarge => TextStyle(
    fontFamily: current,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: _isArabic ? 0 : 0.15,
    color: AppColors.textPrimary,
  );

  static TextStyle get titleMedium => TextStyle(
    fontFamily: current,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: _isArabic ? 0 : 0.15,
    color: AppColors.textPrimary,
  );

  static TextStyle get titleSmall => TextStyle(
    fontFamily: current,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: _isArabic ? 0 : 0.1,
    color: AppColors.textPrimary,
  );

  // ============================================================
  // BODY STYLES
  // ============================================================

  static TextStyle get bodyLarge => TextStyle(
    fontFamily: current,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
    letterSpacing: _isArabic ? 0 : 0.15,
    wordSpacing: _isArabic ? 1.5 : 0,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodyMedium => TextStyle(
    fontFamily: current,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
    letterSpacing: _isArabic ? 0 : 0.15,
    wordSpacing: _isArabic ? 1.5 : 0,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodySmall => TextStyle(
    fontFamily: current,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.5,
    letterSpacing: _isArabic ? 0 : 0.15,
    wordSpacing: _isArabic ? 1.5 : 0,
    color: AppColors.textSecondary,
  );

  // ============================================================
  // LABEL STYLES
  // ============================================================

  static TextStyle get labelLarge => TextStyle(
    fontFamily: current,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: _isArabic ? 0 : 0.1,
    color: AppColors.textPrimary,
  );

  static TextStyle get labelMedium => TextStyle(
    fontFamily: current,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: _isArabic ? 0 : 0.5,
    color: AppColors.textSecondary,
  );

  static TextStyle get labelSmall => TextStyle(
    fontFamily: current,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: _isArabic ? 0 : 0.5,
    color: AppColors.textSecondary,
  );

  // ============================================================
  // HELPER — with custom color override
  // ============================================================

  /// Apply a custom color to any style
  /// Example: AppFonts.titleLarge.withColor(AppColors.primary)
  // ignore: avoid_classes_with_only_static_members
}

/// Extension to easily override color on any TextStyle
extension TextStyleExtension on TextStyle {
  TextStyle withColor(Color color) => copyWith(color: color);
  TextStyle withSize(double size) => copyWith(fontSize: size);
  TextStyle withWeight(FontWeight weight) => copyWith(fontWeight: weight);
}
