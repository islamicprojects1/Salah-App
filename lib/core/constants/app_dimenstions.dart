import 'package:flutter/material.dart';

/// App dimensions and responsive sizing helper
/// Supports all screen sizes from small phones to laptops/tablets
class AppDimensions {
  AppDimensions._();

  // ============================================================
  // BREAKPOINTS
  // ============================================================

  /// Extra small phones (< 360)
  static const double breakpointXS = 360;

  /// Small phones (360 - 480)
  static const double breakpointSM = 480;

  /// Medium phones / Large phones (480 - 600)
  static const double breakpointMD = 600;

  /// Small tablets (600 - 768)
  static const double breakpointLG = 768;

  /// Large tablets (768 - 1024)
  static const double breakpointXL = 1024;

  /// Laptops / Desktops (> 1024)
  static const double breakpointXXL = 1200;

  // ============================================================
  // SCREEN SIZE DETECTION
  // ============================================================

  /// Check if screen is extra small phone
  static bool isXSmall(BuildContext context) =>
      MediaQuery.of(context).size.width < breakpointXS;

  /// Check if screen is small phone
  static bool isSmall(BuildContext context) =>
      MediaQuery.of(context).size.width >= breakpointXS &&
      MediaQuery.of(context).size.width < breakpointSM;

  /// Check if screen is medium/large phone
  static bool isMedium(BuildContext context) =>
      MediaQuery.of(context).size.width >= breakpointSM &&
      MediaQuery.of(context).size.width < breakpointMD;

  /// Check if screen is small tablet
  static bool isLarge(BuildContext context) =>
      MediaQuery.of(context).size.width >= breakpointMD &&
      MediaQuery.of(context).size.width < breakpointLG;

  /// Check if screen is large tablet
  static bool isXLarge(BuildContext context) =>
      MediaQuery.of(context).size.width >= breakpointLG &&
      MediaQuery.of(context).size.width < breakpointXL;

  /// Check if screen is laptop/desktop
  static bool isXXLarge(BuildContext context) =>
      MediaQuery.of(context).size.width >= breakpointXL;

  /// Check if screen is mobile (phone)
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < breakpointMD;

  /// Check if screen is tablet
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= breakpointMD &&
      MediaQuery.of(context).size.width < breakpointXL;

  /// Check if screen is desktop/laptop
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= breakpointXL;

  // ============================================================
  // SCREEN DIMENSIONS
  // ============================================================

  /// Get screen width
  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  /// Get screen height
  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  /// Get safe area padding
  static EdgeInsets safeArea(BuildContext context) =>
      MediaQuery.of(context).padding;

  // ============================================================
  // FIXED PADDING & MARGIN
  // ============================================================

  /// 2.0
  static const double paddingXXS = 2.0;

  /// 4.0
  static const double paddingXS = 4.0;

  /// 8.0
  static const double paddingSM = 8.0;

  /// 12.0
  static const double paddingMD = 12.0;

  /// 16.0
  static const double paddingLG = 16.0;

  /// 20.0
  static const double paddingXL = 20.0;

  /// 24.0
  static const double paddingXXL = 24.0;

  /// 32.0
  static const double paddingXXXL = 32.0;

  /// 48.0
  static const double paddingHuge = 48.0;

  // ============================================================
  // RESPONSIVE PADDING (Based on screen size)
  // ============================================================

  /// Get responsive horizontal padding for screen edges
  static double screenPaddingH(BuildContext context) {
    final width = screenWidth(context);
    if (width < breakpointXS) return 12.0;
    if (width < breakpointSM) return 16.0;
    if (width < breakpointMD) return 20.0;
    if (width < breakpointLG) return 24.0;
    if (width < breakpointXL) return 32.0;
    return 48.0;
  }

  /// Get responsive vertical padding
  static double screenPaddingV(BuildContext context) {
    final width = screenWidth(context);
    if (width < breakpointXS) return 8.0;
    if (width < breakpointSM) return 12.0;
    if (width < breakpointMD) return 16.0;
    if (width < breakpointLG) return 20.0;
    if (width < breakpointXL) return 24.0;
    return 32.0;
  }

  /// Get responsive EdgeInsets for screen padding
  static EdgeInsets screenPadding(BuildContext context) => EdgeInsets.symmetric(
    horizontal: screenPaddingH(context),
    vertical: screenPaddingV(context),
  );

  // ============================================================
  // BORDER RADIUS
  // ============================================================

  /// 4.0
  static const double radiusXS = 4.0;

  /// 8.0
  static const double radiusSM = 8.0;

  /// 12.0
  static const double radiusMD = 12.0;

  /// 16.0
  static const double radiusLG = 16.0;

  /// 20.0
  static const double radiusXL = 20.0;

  /// 24.0
  static const double radiusXXL = 24.0;

  /// 32.0
  static const double radiusRound = 32.0;

  /// Full circle
  static const double radiusCircle = 999.0;

  /// Pre-built BorderRadius objects
  static BorderRadius get borderRadiusXS => BorderRadius.circular(radiusXS);
  static BorderRadius get borderRadiusSM => BorderRadius.circular(radiusSM);
  static BorderRadius get borderRadiusMD => BorderRadius.circular(radiusMD);
  static BorderRadius get borderRadiusLG => BorderRadius.circular(radiusLG);
  static BorderRadius get borderRadiusXL => BorderRadius.circular(radiusXL);
  static BorderRadius get borderRadiusXXL => BorderRadius.circular(radiusXXL);
  static BorderRadius get borderRadiusRound =>
      BorderRadius.circular(radiusRound);

  // ============================================================
  // ICON SIZES
  // ============================================================

  /// 12.0 - Very small icons
  static const double iconXS = 12.0;

  /// 16.0 - Small icons
  static const double iconSM = 16.0;

  /// 20.0 - Default small icons
  static const double iconMD = 20.0;

  /// 24.0 - Default icons
  static const double iconLG = 24.0;

  /// 28.0 - Large icons
  static const double iconXL = 28.0;

  /// 32.0 - Extra large icons
  static const double iconXXL = 32.0;

  /// 48.0 - Huge icons
  static const double iconHuge = 48.0;

  /// 64.0 - Hero icons
  static const double iconHero = 64.0;

  /// Responsive icon size
  static double iconResponsive(BuildContext context, {double base = iconLG}) {
    final width = screenWidth(context);
    if (width < breakpointXS) return base * 0.8;
    if (width < breakpointSM) return base * 0.9;
    if (width < breakpointMD) return base;
    if (width < breakpointLG) return base * 1.1;
    if (width < breakpointXL) return base * 1.2;
    return base * 1.3;
  }

  // ============================================================
  // BUTTON DIMENSIONS
  // ============================================================

  /// 32.0 - Extra small button
  static const double buttonHeightXS = 32.0;

  /// 36.0 - Small button
  static const double buttonHeightSM = 36.0;

  /// 44.0 - Medium button
  static const double buttonHeightMD = 44.0;

  /// 48.0 - Default button
  static const double buttonHeightLG = 48.0;

  /// 56.0 - Large button
  static const double buttonHeightXL = 56.0;

  /// Responsive button height
  static double buttonHeightResponsive(BuildContext context) {
    final width = screenWidth(context);
    if (width < breakpointXS) return buttonHeightSM;
    if (width < breakpointSM) return buttonHeightMD;
    if (width < breakpointMD) return buttonHeightLG;
    return buttonHeightXL;
  }

  // ============================================================
  // INPUT FIELD DIMENSIONS
  // ============================================================

  /// 44.0 - Small input field
  static const double inputHeightSM = 44.0;

  /// 48.0 - Medium input field
  static const double inputHeightMD = 48.0;

  /// 56.0 - Large input field
  static const double inputHeightLG = 56.0;

  // ============================================================
  // CARD DIMENSIONS
  // ============================================================

  /// Card elevation
  static const double cardElevation = 2.0;
  static const double cardElevationHigh = 4.0;
  static const double cardElevationLow = 1.0;

  // ============================================================
  // SPACING (Vertical gaps between elements)
  // ============================================================

  /// 4.0
  static const double spaceXS = 4.0;

  /// 8.0
  static const double spaceSM = 8.0;

  /// 12.0
  static const double spaceMD = 12.0;

  /// 16.0
  static const double spaceLG = 16.0;

  /// 24.0
  static const double spaceXL = 24.0;

  /// 32.0
  static const double spaceXXL = 32.0;

  /// 48.0
  static const double spaceHuge = 48.0;

  /// Responsive vertical spacing
  static double spaceResponsive(BuildContext context, {double base = spaceLG}) {
    final width = screenWidth(context);
    if (width < breakpointXS) return base * 0.75;
    if (width < breakpointSM) return base * 0.85;
    if (width < breakpointMD) return base;
    if (width < breakpointLG) return base * 1.15;
    if (width < breakpointXL) return base * 1.25;
    return base * 1.5;
  }

  // ============================================================
  // COMMON WIDGETS
  // ============================================================

  /// App bar heights
  static const double appBarHeight = 56.0;
  static const double appBarHeightLarge = 64.0;

  /// Bottom navigation bar height
  static const double bottomNavHeight = 56.0;
  static const double bottomNavHeightWithLabels = 72.0;

  /// Drawer width
  static double drawerWidth(BuildContext context) {
    final width = screenWidth(context);
    if (isMobile(context)) return width * 0.8;
    if (isTablet(context)) return 320;
    return 360;
  }

  /// Dialog widths
  static const double dialogWidthSM = 280;
  static const double dialogWidthMD = 320;
  static const double dialogWidthLG = 400;

  /// Maximum content width for large screens
  static const double maxContentWidth = 600;
  static const double maxContentWidthLarge = 800;
  static const double maxContentWidthXLarge = 1200;

  // ============================================================
  // GRID LAYOUTS
  // ============================================================

  /// Get number of grid columns based on screen size
  static int gridColumns(BuildContext context) {
    final width = screenWidth(context);
    if (width < breakpointXS) return 1;
    if (width < breakpointSM) return 2;
    if (width < breakpointMD) return 2;
    if (width < breakpointLG) return 3;
    if (width < breakpointXL) return 4;
    return 5;
  }

  /// Get grid cross axis spacing
  static double gridSpacing(BuildContext context) {
    if (isMobile(context)) return paddingSM;
    if (isTablet(context)) return paddingMD;
    return paddingLG;
  }

  // ============================================================
  // HELPER WIDGETS (SizedBox shortcuts)
  // ============================================================

  /// Horizontal gaps
  static const Widget gapH4 = SizedBox(width: 4);
  static const Widget gapH8 = SizedBox(width: 8);
  static const Widget gapH12 = SizedBox(width: 12);
  static const Widget gapH16 = SizedBox(width: 16);
  static const Widget gapH24 = SizedBox(width: 24);
  static const Widget gapH32 = SizedBox(width: 32);

  /// Vertical gaps
  static const Widget gapV4 = SizedBox(height: 4);
  static const Widget gapV8 = SizedBox(height: 8);
  static const Widget gapV12 = SizedBox(height: 12);
  static const Widget gapV16 = SizedBox(height: 16);
  static const Widget gapV24 = SizedBox(height: 24);
  static const Widget gapV32 = SizedBox(height: 32);
  static const Widget gapV48 = SizedBox(height: 48);

  // ============================================================
  // ANIMATION DURATIONS
  // ============================================================

  /// 150ms - Fast animations
  static const Duration durationFast = Duration(milliseconds: 150);

  /// 250ms - Normal animations
  static const Duration durationNormal = Duration(milliseconds: 250);

  /// 350ms - Slow animations
  static const Duration durationSlow = Duration(milliseconds: 350);

  /// 500ms - Very slow animations
  static const Duration durationVerySlow = Duration(milliseconds: 500);
}

/// Extension for easier access to responsive dimensions
extension AppDimensionsExtension on BuildContext {
  /// Access AppDimensions helpers
  double get screenWidth => AppDimensions.screenWidth(this);
  double get screenHeight => AppDimensions.screenHeight(this);
  bool get isMobile => AppDimensions.isMobile(this);
  bool get isTablet => AppDimensions.isTablet(this);
  bool get isDesktop => AppDimensions.isDesktop(this);
  EdgeInsets get screenPadding => AppDimensions.screenPadding(this);
  double get responsiveIconSize => AppDimensions.iconResponsive(this);
  int get gridColumns => AppDimensions.gridColumns(this);
}
