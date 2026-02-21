import 'package:flutter/material.dart';

/// App-wide layout constants and responsive sizing helpers.
///
/// Supports screens from small phones (< 360 px) to desktops (> 1024 px).
/// Use the [AppDimensionsExtension] on [BuildContext] for the most ergonomic API.
class AppDimensions {
  const AppDimensions._();

  // ============================================================
  // BREAKPOINTS (logical pixels)
  // ============================================================

  static const double breakpointXS = 360;
  static const double breakpointSM = 480;
  static const double breakpointMD = 600;
  static const double breakpointLG = 768;
  static const double breakpointXL = 1024;
  static const double breakpointXXL = 1200;

  // ============================================================
  // SCREEN SIZE DETECTION
  // ============================================================

  static bool isXSmall(BuildContext context) => _width(context) < breakpointXS;

  static bool isSmall(BuildContext context) =>
      _width(context) >= breakpointXS && _width(context) < breakpointSM;

  static bool isMedium(BuildContext context) =>
      _width(context) >= breakpointSM && _width(context) < breakpointMD;

  static bool isLarge(BuildContext context) =>
      _width(context) >= breakpointMD && _width(context) < breakpointLG;

  static bool isXLarge(BuildContext context) =>
      _width(context) >= breakpointLG && _width(context) < breakpointXL;

  static bool isXXLarge(BuildContext context) =>
      _width(context) >= breakpointXL;

  static bool isMobile(BuildContext context) => _width(context) < breakpointMD;

  static bool isTablet(BuildContext context) =>
      _width(context) >= breakpointMD && _width(context) < breakpointXL;

  static bool isDesktop(BuildContext context) =>
      _width(context) >= breakpointXL;

  // ============================================================
  // SCREEN DIMENSIONS
  // ============================================================

  static double screenWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height;

  static EdgeInsets safeArea(BuildContext context) =>
      MediaQuery.paddingOf(context);

  // ============================================================
  // FIXED SPACING & PADDING
  // ============================================================

  static const double paddingXXS = 2.0;
  static const double paddingXS = 4.0;
  static const double paddingSM = 8.0;
  static const double paddingMD = 12.0;
  static const double paddingLG = 16.0;

  /// Named XL but value is 18 — kept for backward compatibility.
  static const double paddingXL = 18.0;
  static const double paddingXXL = 24.0;
  static const double paddingXXXL = 32.0;
  static const double paddingHuge = 48.0;

  // ============================================================
  // RESPONSIVE PADDING
  // ============================================================

  static double screenPaddingH(BuildContext context) {
    final w = _width(context);
    if (w < breakpointXS) return 12.0;
    if (w < breakpointSM) return 16.0;
    if (w < breakpointMD) return 20.0;
    if (w < breakpointLG) return 24.0;
    if (w < breakpointXL) return 32.0;
    return 48.0;
  }

  static double screenPaddingV(BuildContext context) {
    final w = _width(context);
    if (w < breakpointXS) return 8.0;
    if (w < breakpointSM) return 12.0;
    if (w < breakpointMD) return 16.0;
    if (w < breakpointLG) return 20.0;
    if (w < breakpointXL) return 24.0;
    return 32.0;
  }

  static EdgeInsets screenPadding(BuildContext context) => EdgeInsets.symmetric(
    horizontal: screenPaddingH(context),
    vertical: screenPaddingV(context),
  );

  // ============================================================
  // BORDER RADIUS
  // ============================================================

  static const double radiusXS = 4.0;
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 24.0;
  static const double radiusRound = 32.0;
  static const double radiusCircle = 999.0;

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

  static const double iconXS = 12.0;
  static const double iconSM = 16.0;
  static const double iconMD = 20.0;
  static const double iconLG = 24.0;
  static const double iconXL = 28.0;
  static const double iconXXL = 32.0;
  static const double iconHuge = 48.0;
  static const double iconHero = 64.0;

  static double iconResponsive(BuildContext context, {double base = iconLG}) {
    final w = _width(context);
    if (w < breakpointXS) return base * 0.80;
    if (w < breakpointSM) return base * 0.90;
    if (w < breakpointMD) return base;
    if (w < breakpointLG) return base * 1.10;
    if (w < breakpointXL) return base * 1.20;
    return base * 1.30;
  }

  // ============================================================
  // SPECIFIC UI ELEMENTS
  // ============================================================

  static const double imageOnboarding = 280.0;
  static const double iconOnboardingPlaceholder = 120.0;
  static const double sizeLogo = 100.0;
  static const double iconLogo = 50.0;
  static const double dotSize = 8.0;
  static const double dotWidthActive = 24.0;
  static const double radiusProfileAvatarLarge = 50.0;
  static const double radiusProfileCameraBadge = 18.0;
  static const double iconGender = 32.0;
  static const double borderWidthSelected = 2.0;

  // ============================================================
  // BUTTON DIMENSIONS
  // ============================================================

  static const double buttonHeightXS = 32.0;
  static const double buttonHeightSM = 36.0;
  static const double buttonHeightMD = 44.0;
  static const double buttonHeightLG = 48.0;
  static const double buttonHeightXL = 56.0;

  static double buttonHeightResponsive(BuildContext context) {
    final w = _width(context);
    if (w < breakpointXS) return buttonHeightSM;
    if (w < breakpointSM) return buttonHeightMD;
    if (w < breakpointMD) return buttonHeightLG;
    return buttonHeightXL;
  }

  // ============================================================
  // INPUT FIELD DIMENSIONS
  // ============================================================

  static const double inputHeightSM = 44.0;
  static const double inputHeightMD = 48.0;
  static const double inputHeightLG = 56.0;

  // ============================================================
  // CARD ELEVATION
  // ============================================================

  static const double cardElevationLow = 1.0;
  static const double cardElevation = 2.0;
  static const double cardElevationHigh = 4.0;

  // ============================================================
  // SPACING
  // ============================================================

  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 12.0;
  static const double spaceLG = 16.0;
  static const double spaceXL = 24.0;
  static const double spaceXXL = 32.0;
  static const double spaceHuge = 48.0;

  static double spaceResponsive(BuildContext context, {double base = spaceLG}) {
    final w = _width(context);
    if (w < breakpointXS) return base * 0.75;
    if (w < breakpointSM) return base * 0.85;
    if (w < breakpointMD) return base;
    if (w < breakpointLG) return base * 1.15;
    if (w < breakpointXL) return base * 1.25;
    return base * 1.50;
  }

  // ============================================================
  // COMMON WIDGET SIZES
  // ============================================================

  static const double appBarHeight = 56.0;
  static const double appBarHeightLarge = 64.0;
  static const double bottomNavHeight = 56.0;
  static const double bottomNavHeightWithLabels = 72.0;

  static double drawerWidth(BuildContext context) {
    if (isMobile(context)) return _width(context) * 0.80;
    if (isTablet(context)) return 320;
    return 360;
  }

  static const double dialogWidthSM = 280;
  static const double dialogWidthMD = 320;
  static const double dialogWidthLG = 400;

  static const double maxContentWidth = 600;
  static const double maxContentWidthLarge = 800;
  static const double maxContentWidthXLarge = 1200;

  // ============================================================
  // GRID
  // ============================================================

  static int gridColumns(BuildContext context) {
    final w = _width(context);
    if (w < breakpointXS) return 1;
    if (w < breakpointSM) return 2;
    if (w < breakpointMD) return 2;
    if (w < breakpointLG) return 3;
    if (w < breakpointXL) return 4;
    return 5;
  }

  static double gridSpacing(BuildContext context) {
    if (isMobile(context)) return paddingSM;
    if (isTablet(context)) return paddingMD;
    return paddingLG;
  }

  // ============================================================
  // SIZEDBOX SHORTCUTS
  // ============================================================

  static const Widget gapH4 = SizedBox(width: 4);
  static const Widget gapH8 = SizedBox(width: 8);
  static const Widget gapH12 = SizedBox(width: 12);
  static const Widget gapH16 = SizedBox(width: 16);
  static const Widget gapH24 = SizedBox(width: 24);
  static const Widget gapH32 = SizedBox(width: 32);

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

  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 250);
  static const Duration durationSlow = Duration(milliseconds: 350);
  static const Duration durationVerySlow = Duration(milliseconds: 500);

  // ============================================================
  // PRIVATE HELPERS
  // ============================================================

  static double _width(BuildContext context) =>
      MediaQuery.sizeOf(context).width;
}

// ============================================================
// EXTENSION — ergonomic BuildContext access
// ============================================================

extension AppDimensionsExtension on BuildContext {
  double get screenWidth => AppDimensions.screenWidth(this);
  double get screenHeight => AppDimensions.screenHeight(this);
  bool get isMobile => AppDimensions.isMobile(this);
  bool get isTablet => AppDimensions.isTablet(this);
  bool get isDesktop => AppDimensions.isDesktop(this);
  EdgeInsets get screenPadding => AppDimensions.screenPadding(this);
  double get responsiveIconSize => AppDimensions.iconResponsive(this);
  int get gridColumns => AppDimensions.gridColumns(this);
  double get gridSpacing => AppDimensions.gridSpacing(this);
  double get screenPaddingH => AppDimensions.screenPaddingH(this);
  double get screenPaddingV => AppDimensions.screenPaddingV(this);
}
