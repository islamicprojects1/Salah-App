/// App image and animation asset paths
/// 
/// Centralized location for all asset references
class ImageAssets {
  ImageAssets._();

  // ============================================================
  // BASE PATHS
  // ============================================================
  
  static const String _imagesPath = 'assets/images';
  static const String _iconsPath = 'assets/icons';
  static const String _animationsPath = 'assets/animations';

  // ============================================================
  // APP ICONS
  // ============================================================
  
  /// App icon
  static const String appIcon = '$_iconsPath/app_icon.png';

  // ============================================================
  // PRAYER TIME BACKGROUNDS
  // ============================================================
  
  /// Fajr (dawn) prayer background
  static const String fajrBg = '$_imagesPath/fajr_prayer_bg.png';
  
  /// Dhuhr (noon) prayer background
  static const String dhuhrBg = '$_imagesPath/dhuhr_prayer_bg.png';
  
  /// Asr (afternoon) prayer background
  static const String asrBg = '$_imagesPath/asr_prayer_bg.png';
  
  /// Maghrib (sunset) prayer background
  static const String maghribBg = '$_imagesPath/maghrib_prayer_bg.png';
  
  /// Isha (night) prayer background
  static const String ishaBg = '$_imagesPath/isha_prayer_bg.png';

  // ============================================================
  // GENERAL IMAGES
  // ============================================================
  
  /// Mosque silhouette
  static const String mosqueSilhouette = '$_imagesPath/mosque_silhouette.png';
  
  /// Qibla compass
  static const String qiblaCompass = '$_imagesPath/qibla_compass.png';
  
  /// Default user avatar
  static const String defaultAvatar = '$_imagesPath/user_avatar_default.png';
  
  /// Prayer done celebration
  static const String prayerCelebration = '$_imagesPath/prayer_done_celebration.png';

  // ============================================================
  // ONBOARDING IMAGES
  // ============================================================
  
  /// Welcome onboarding
  static const String onboardingWelcome = '$_imagesPath/onboarding_welcome.png';
  
  /// Location permission onboarding
  static const String onboardingLocation = '$_imagesPath/onboarding_location.png';
  
  /// Community feature onboarding
  static const String onboardingCommunity = '$_imagesPath/onboarding_community.png';

  // ============================================================
  // EMPTY STATE IMAGES
  // ============================================================
  
  /// Empty prayers state
  static const String emptyPrayers = '$_imagesPath/empty_prayers.png';
  
  /// Empty community state
  static const String emptyCommunity = '$_imagesPath/empty_community.png';

  // ============================================================
  // LOTTIE ANIMATIONS
  // ============================================================
  
  /// Loading animation
  static const String loadingAnimation = '$_animationsPath/loading.json';
  
  /// Success animation
  static const String successAnimation = '$_animationsPath/Success.json';
  
  /// Confetti celebration animation
  static const String confettiAnimation = '$_animationsPath/Confetti.json';
  
  /// Mosque animation
  static const String mosqueAnimation = '$_animationsPath/mosque.json';
  
  /// Dad with father praying animation
  static const String familyPrayingAnimation = '$_animationsPath/dadwithfatherareprayer.json';

  // ============================================================
  // HELPER METHODS
  // ============================================================
  
  /// Get prayer background based on prayer name
  static String getPrayerBackground(String prayerName) {
    switch (prayerName.toLowerCase()) {
      case 'fajr':
        return fajrBg;
      case 'dhuhr':
        return dhuhrBg;
      case 'asr':
        return asrBg;
      case 'maghrib':
        return maghribBg;
      case 'isha':
        return ishaBg;
      default:
        return fajrBg;
    }
  }
}
