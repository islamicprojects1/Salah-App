/// App route names as constants
/// 
/// Use these constants when navigating to avoid typos
abstract class AppRoutes {
  AppRoutes._();
  
  /// Splash screen - initial loading screen
  static const String splash = '/splash';
  
  /// Home screen - main app screen with prayer times
  static const String home = '/home';
  
  /// Settings screen - app settings and preferences
  static const String settings = '/settings';
  
  /// Onboarding screens - first time user experience
  static const String onboarding = '/onboarding';
  
  /// Qibla screen - compass for Qibla direction
  static const String qibla = '/qibla';
  
  /// Prayer times screen - detailed prayer times view
  static const String prayerTimes = '/prayer-times';
  
  /// About screen - app information
  static const String about = '/about';
}
