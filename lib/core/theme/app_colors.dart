import 'package:flutter/material.dart';

/// App color palette with Islamic-inspired colors
/// 
/// Primary: Islamic Green - representing nature, paradise, and spirituality
/// Secondary: Gold - representing divine light and Quranic illumination
class AppColors {
  AppColors._();
  
  // ==================== Primary Colors ====================
  
  /// Primary Islamic Green
  static const Color primary = Color(0xFF1B5E20);
  static const Color primaryLight = Color(0xFF4C8C4A);
  static const Color primaryDark = Color(0xFF003300);
  
  /// Secondary Gold
  static const Color secondary = Color(0xFFD4AF37);
  static const Color secondaryLight = Color(0xFFFFE066);
  static const Color secondaryDark = Color(0xFFA07F00);
  
  // ==================== Light Theme Colors ====================
  
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF212121);
  static const Color lightTextSecondary = Color(0xFF757575);
  static const Color lightDivider = Color(0xFFBDBDBD);
  static const Color lightError = Color(0xFFB71C1C);
  
  // ==================== Dark Theme Colors ====================
  
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2C2C2C);
  static const Color darkText = Color(0xFFE0E0E0);
  static const Color darkTextSecondary = Color(0xFF9E9E9E);
  static const Color darkDivider = Color(0xFF424242);
  static const Color darkError = Color(0xFFCF6679);
  
  // ==================== Prayer Time Colors ====================
  
  /// Fajr - Dawn blue
  static const Color fajr = Color(0xFF1A237E);
  
  /// Dhuhr - Midday yellow
  static const Color dhuhr = Color(0xFFFFC107);
  
  /// Asr - Afternoon orange
  static const Color asr = Color(0xFFFF9800);
  
  /// Maghrib - Sunset red-orange
  static const Color maghrib = Color(0xFFE65100);
  
  /// Isha - Night purple
  static const Color isha = Color(0xFF4A148C);
  
  // ==================== Gradient Colors ====================
  
  /// Fajr gradient (dawn sky)
  static const List<Color> fajrGradient = [
    Color(0xFF1A237E),
    Color(0xFF3949AB),
    Color(0xFFFF8A65),
  ];
  
  /// Day gradient (bright sky)
  static const List<Color> dayGradient = [
    Color(0xFF42A5F5),
    Color(0xFF64B5F6),
    Color(0xFFFFEB3B),
  ];
  
  /// Maghrib gradient (sunset)
  static const List<Color> maghribGradient = [
    Color(0xFFE65100),
    Color(0xFFFF6F00),
    Color(0xFFFFD54F),
  ];
  
  /// Isha gradient (night sky)
  static const List<Color> ishaGradient = [
    Color(0xFF0D1B2A),
    Color(0xFF1B263B),
    Color(0xFF415A77),
  ];
  
  // ==================== Utility Colors ====================
  
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);
  
  /// Sunrise - Morning light gold
  static const Color sunrise = Color(0xFFFF8F00);
  
  /// Qibla compass pointer color
  static const Color qiblaPointer = secondary;
  
  /// Mosque/location marker color
  static const Color locationMarker = primary;
}
