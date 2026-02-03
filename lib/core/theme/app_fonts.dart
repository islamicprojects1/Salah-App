import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// App typography styles
class AppFonts {
  AppFonts._();

  // ============================================================
  // BASE FONT
  // ============================================================
  
  /// Primary font family
  /// Using Poppins for English and Tajawal for Arabic dynamic switching
  static String get _fontFamily {
    // Check current locale
    if (Get.locale?.languageCode == 'ar') {
      return 'Tajawal';
    }
    return 'Poppins';
  }

  // ============================================================
  // HEADLINE STYLES
  // ============================================================
  
  /// Large headline - for main titles
  static TextStyle get headlineLarge => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );

  /// Medium headline
  static TextStyle get headlineMedium => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );

  /// Small headline
  static TextStyle get headlineSmall => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  // ============================================================
  // TITLE STYLES
  // ============================================================
  
  /// Large title
  static TextStyle get titleLarge => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  /// Medium title
  static TextStyle get titleMedium => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  /// Small title
  static TextStyle get titleSmall => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // ============================================================
  // BODY STYLES
  // ============================================================
  
  /// Large body text
  static TextStyle get bodyLarge => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  /// Medium body text
  static TextStyle get bodyMedium => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  /// Small body text
  static TextStyle get bodySmall => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  // ============================================================
  // LABEL STYLES
  // ============================================================
  
  /// Large label
  static TextStyle get labelLarge => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  /// Medium label
  static TextStyle get labelMedium => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  /// Small label
  static TextStyle get labelSmall => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );
}
