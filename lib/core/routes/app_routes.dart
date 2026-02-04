/// App route names as constants
///
/// Use these constants when navigating to avoid typos
class AppRoutes {
  AppRoutes._();

  /// Splash screen - initial loading screen
  static const String splash = '/splash';

  /// Onboarding screens - first time user experience
  static const String onboarding = '/onboarding';

  /// Login screen
  static const String login = '/login';

  /// Register screen
  static const String register = '/register';

  /// Profile setup screen
  static const String profileSetup = '/profile-setup';

  /// Dashboard screen - main app screen
  static const String dashboard = '/dashboard';

  /// Home screen (legacy - use dashboard)
  static const String home = '/home';

  /// Family screen
  static const String family = '/family';
  static const String createFamily = '/family/create';
  static const String joinFamily = '/family/join';

  /// Qibla screen - compass for Qibla direction
  static const String qibla = '/qibla';

  /// Settings screen - app settings and preferences
  static const String settings = '/settings';

  /// Prayer times screen - detailed prayer times view
  static const String prayerTimes = '/prayer-times';

  /// Missed prayers screen - batch logging of unlogged prayers
  static const String missedPrayers = '/missed-prayers';

  /// About screen - app information
  static const String about = '/about';
}
