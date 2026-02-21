/// Centralized asset paths for images, icons, and Lottie animations.
///
/// Always reference assets through this class — never hard-code paths.
class ImageAssets {
  const ImageAssets._();

  // ============================================================
  // BASE PATHS (private — use the public constants below)
  // ============================================================

  static const String _images = 'assets/images';
  static const String _icons = 'assets/icons';
  static const String _animations = 'assets/animations';

  // ============================================================
  // APP BRANDING
  // ============================================================

  static const String appIcon = '$_icons/app_icon.png';
  static const String appLogo = '$_icons/salah_app_logo.png';

  // ============================================================
  // PRAYER TIME BACKGROUNDS
  // ============================================================

  static const String fajrBg = '$_images/fajr_prayer_bg.png';
  static const String dhuhrBg = '$_images/dhuhr_prayer_bg.png';
  static const String asrBg = '$_images/asr_prayer_bg.png';
  static const String maghribBg = '$_images/maghrib_prayer_bg.png';
  static const String ishaBg = '$_images/isha_prayer_bg.png';

  // ============================================================
  // GENERAL IMAGES
  // ============================================================

  static const String mosqueSilhouette = '$_images/mosque_silhouette.png';
  static const String qiblaCompass = '$_images/qibla_compass.png';
  static const String defaultAvatar = '$_images/user_avatar_default.png';
  static const String prayerCelebration =
      '$_images/prayer_done_celebration.png';

  // ============================================================
  // ONBOARDING
  // ============================================================

  static const String onboardingWelcome = '$_images/onboarding_welcome.png';
  static const String onboardingLocation = '$_images/onboarding_location.png';
  static const String onboardingCommunity = '$_images/onboarding_community.png';

  // ============================================================
  // EMPTY STATES
  // ============================================================

  static const String emptyPrayers = '$_images/empty_prayers.png';
  static const String emptyCommunity = '$_images/empty_community.png';

  // ============================================================
  // LOTTIE ANIMATIONS
  // ============================================================

  static const String loadingAnimation = '$_animations/loading.json';
  static const String successAnimation = '$_animations/Success.json';
  static const String confettiAnimation = '$_animations/Confetti.json';
  static const String mosqueAnimation = '$_animations/mosque.json';
  static const String familyPrayingAnimation =
      '$_animations/dadwithfatherareprayer.json';

  // ============================================================
  // HELPERS
  // ============================================================

  /// Returns the background image for the given prayer name (case-insensitive).
  /// Falls back to [fajrBg] for unrecognised names (e.g. 'sunrise').
  static String prayerBackground(String prayerName) =>
      _prayerBackgrounds[prayerName.toLowerCase()] ?? fajrBg;

  static const Map<String, String> _prayerBackgrounds = {
    'fajr': fajrBg,
    'dhuhr': dhuhrBg,
    'asr': asrBg,
    'maghrib': maghribBg,
    'isha': ishaBg,
  };
}
