import 'package:get/get.dart';
import 'app_routes.dart';
import '../../view/screens/splash/splash_screen.dart';
import '../../view/screens/home/home_screen.dart';
import '../../view/screens/settings/settings_screen.dart';
import '../../view/screens/onboarding/onboarding_screen.dart';
import '../../view/screens/auth/login_screen.dart';
import '../../view/screens/auth/register_screen.dart';
import '../../view/screens/auth/profile_setup_screen.dart';
import '../../view/screens/dashboard/dashboard_screen.dart';
import '../../controller/bindings/settings_binding.dart';
import '../../controller/bindings/auth_binding.dart';
import '../../controller/bindings/dashboard_binding.dart';
import '../../controller/bindings/family_binding.dart';
import '../../view/screens/family/create_family_screen.dart';
import '../../view/screens/family/join_family_screen.dart';
import '../../view/screens/family/family_dashboard_screen.dart';
import '../../view/screens/missed_prayers/missed_prayers_screen.dart';
import '../../controller/missed_prayers_controller.dart';

/// App pages configuration for GetX routing
///
/// Defines all app routes with their screens, bindings, and transitions
class AppPages {
  AppPages._();

  /// Initial route
  static const String initial = AppRoutes.splash;

  /// All app pages/routes
  static final List<GetPage> pages = [
    // Splash Screen
    GetPage(
      name: initial,
      page: () => const SplashScreen(),
      transition: Transition.fade,
    ),

    // Onboarding
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingScreen(),
      binding: AuthBinding(),
      transition: Transition.fade,
    ),

    // Login
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      binding: AuthBinding(),
      transition: Transition.fadeIn,
    ),

    // Register
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterScreen(),
      transition: Transition.rightToLeft,
    ),

    // Profile Setup
    GetPage(
      name: AppRoutes.profileSetup,
      page: () => const ProfileSetupScreen(),
      transition: Transition.rightToLeft,
    ),

    // Dashboard (main screen after login)
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardScreen(),
      binding: DashboardBinding(),
      transition: Transition.fadeIn,
    ),

    // Home Screen (legacy)
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
      transition: Transition.fadeIn,
    ),

    // Settings Screen
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsScreen(),
      binding: SettingsBinding(),
      transition: Transition.rightToLeft,
    ),

    // Family Screens
    GetPage(
      name: AppRoutes.family,
      page: () => const FamilyDashboardScreen(), // Need to create this
      binding: FamilyBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.createFamily,
      page: () => const CreateFamilyScreen(),
      binding: FamilyBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.joinFamily,
      page: () => const JoinFamilyScreen(),
      binding: FamilyBinding(),
      transition: Transition.rightToLeft,
    ),

    // Missed Prayers
    GetPage(
      name: AppRoutes.missedPrayers,
      page: () => const MissedPrayersScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<MissedPrayersController>(() => MissedPrayersController());
      }),
      transition: Transition.downToUp,
    ),
  ];
}
