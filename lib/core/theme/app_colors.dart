import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// App color palette with Islamic-inspired colors
/// Refined for harmony, contrast, and a premium feel
class AppColors {
  AppColors._();

  // ==================== Primary Colors ====================

  /// Primary Islamic Green — deep emerald
  static const Color primary = Color(0xFF156340);
  static const Color primaryLight = Color(0xFF4A9D6E);
  static const Color primaryDark = Color(0xFF0A3D24);

  /// Secondary Gold — warm, elegant
  static const Color secondary = Color(0xFFC9A227);
  static const Color secondaryLight = Color(0xFFE8D48B);
  static const Color secondaryDark = Color(0xFF8B7219);
  static const Color gold = secondary;

  // ==================== Light Theme Colors ====================

  static const Color lightBackground = Color(0xFFF8F6F1);
  static const Color lightSurface = Color(0xFFFFFEFB);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF1C1B1A);
  static const Color lightTextSecondary = Color(0xFF6B6560);
  static const Color lightDivider = Color(0xFFE5E2DD);
  static const Color lightError = Color(0xFFC62828);

  // ==================== Dark Theme Colors ====================

  static const Color darkBackground = Color(0xFF0F1412);
  static const Color darkSurface = Color(0xFF1A211D);
  static const Color darkCard = Color(0xFF242D28);
  static const Color darkText = Color(0xFFE8E6E3);
  static const Color darkTextSecondary = Color(0xFFA8A29E);
  static const Color darkDivider = Color(0xFF3D4A44);
  static const Color darkError = Color(0xFFE57373);

  // ==================== Dynamic Colors (GetX) ====================

  static Color get background =>
      Get.isDarkMode ? darkBackground : lightBackground;
  static Color get surface => Get.isDarkMode ? darkSurface : lightSurface;
  static Color get card => Get.isDarkMode ? darkCard : lightCard;
  static Color get textPrimary => Get.isDarkMode ? darkText : lightText;
  static Color get textSecondary =>
      Get.isDarkMode ? darkTextSecondary : lightTextSecondary;
  static Color get divider => Get.isDarkMode ? darkDivider : lightDivider;

  // ==================== Utility Colors ====================

  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF1976D2);
  static const Color orange = Color(0xFFE65100);
  static const Color green = Color(0xFF388E3C);
  static const Color amber = Color(0xFFFFB300);

  // ==================== Prayer Time Colors ====================

  static const Color fajr = Color(0xFF1E3A5F);
  static const Color dhuhr = Color(0xFFE6A800);
  static const Color asr = Color(0xFFE87400);
  static const Color maghrib = Color(0xFFD84315);
  static const Color isha = Color(0xFF311B92);
  static const Color sunrise = Color(0xFFFF8F00);

  // ==================== Absolute Colors ====================

  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color transparent = Colors.transparent;

  // ==================== Grey Shades ====================

  static const Color grey50 = Color(0xFFFAFAF8);
  static const Color grey100 = Color(0xFFF5F4F2);
  static const Color grey200 = Color(0xFFEEEDEA);
  static const Color grey300 = Color(0xFFE0DDD8);
  static const Color grey400 = Color(0xFFB8B3AB);
  static const Color grey500 = Color(0xFF928D84);
  static const Color grey600 = Color(0xFF6B6560);
  static const Color grey700 = Color(0xFF524D48);
  static const Color grey800 = Color(0xFF3D3935);
  static const Color grey900 = Color(0xFF1C1B1A);

  // ==================== Gradient Colors ====================

  static const List<Color> fajrGradient = [
    Color(0xFF1E3A5F),
    Color(0xFF2D4A7C),
    Color(0xFFE8A65C),
  ];
  static const List<Color> dayGradient = [
    Color(0xFF4FC3F7),
    Color(0xFF81D4FA),
    Color(0xFFFFE082),
  ];
  static const List<Color> maghribGradient = [
    Color(0xFFD84315),
    Color(0xFFFF6F00),
    Color(0xFFFFD54F),
  ];
  static const List<Color> ishaGradient = [
    Color(0xFF0D0A1A),
    Color(0xFF1B1625),
    Color(0xFF3E3A52),
  ];

  // ==================== Splash Screen Colors ====================

  /// Splash screen gradient colors for light mode
  static const List<Color> splashLightGradient = [
    Color(0xFF156340), // primary
    Color(0xFF0A3D24), // primaryDark
  ];

  /// Splash screen gradient colors for dark mode
  static const List<Color> splashDarkGradient = [
    Color(0xFF0F1412), // darkBackground
    Color(0xFF0A3D24), // primaryDark
  ];

  /// Decorative glow color for splash screen
  static const Color splashGlowColor = Color(0xFFC9A227); // secondary gold

  /// White with transparency for splash screen elements
  static const Color splashWhite = Color(0xFFFFFFFF);

  // static const Color qiblaPointer = secondary,;
  static const Color locationMarker = primary;

  // ==================== Onboarding Feature Colors ====================

  static const Color feature1 = Color(0xFF5C6BC0);
  static const Color feature2 = Color(0xFF2E7D32);
  static const Color feature3 = Color(0xFFF9A825);

  // ==================== Onboarding Page Gradients ====================

  static const Color onboarding1Start = Color(0xFFE8A65C);
  static const Color onboarding1End = Color(0xFFFFD54F);
  static const Color onboarding2Start = Color(0xFF4A9D6E);
  static const Color onboarding2End = Color(0xFF81C784);
  static const Color onboarding3Start = Color(0xFF156340);
  static const Color onboarding3End = Color(0xFF4A9D6E);

  // ==================== Branded Colors ====================

  static const Color googleRed = Color(0xFFDB4437);
  static const Color black87 = Color(0xDE000000);
  static const Color black26 = Color(0x42000000);
  static const Color white70 = Color(0xB3FFFFFF);
  static const Color white24 = Color(0x3DFFFFFF);
  static const Color white10 = Color(0x1AFFFFFF);
  static const Color pink = Color(0xFFE91E63);
  static const Color purple = Color(0xFF7E57C2);
}
