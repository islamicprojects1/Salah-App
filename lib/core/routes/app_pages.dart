import 'package:get/get.dart';
import 'package:salah/controller/bindings/settings/selected_city_binding.dart';
import 'package:salah/core/middleware/onboarding_middleware.dart';
import 'package:salah/view/screens/settings/select_city_screen.dart';
import 'app_routes.dart';
import '../../view/screens/splash/splash_screen.dart';
import '../../view/screens/home/home_screen.dart';
import '../../view/screens/settings/settings_screen.dart';
import '../../view/screens/onboarding/onboarding_screen.dart';
import '../../view/screens/auth/login_screen.dart';
import '../../view/screens/auth/register_screen.dart';
import '../../view/screens/auth/profile_setup_screen.dart';
import '../../view/screens/dashboard/dashboard_screen.dart';
import '../../controller/bindings/settings/settings_binding.dart';
import '../../controller/bindings/auth_binding.dart';
import '../../controller/bindings/dashboard_binding.dart';
import '../../controller/bindings/family_binding.dart';
import '../../view/screens/family/create_family_screen.dart';
import '../../view/screens/family/join_family_screen.dart';
import '../../view/screens/family/family_dashboard_screen.dart';
import '../../view/screens/missed_prayers/missed_prayers_screen.dart';
import '../../controller/missed_prayers_controller.dart';
import '../../view/screens/profile/profile_screen.dart';
import '../../controller/profile_controller.dart';
import '../../view/screens/qibla/qibla_screen.dart';

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
      middlewares: [OnboardingMiddleware()],
      transition: Transition.fade,
    ),

    // Login
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      binding: AuthBinding(),
      transition: Transition.fade, // Smooth fade to login
    ),

    // Register
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterScreen(),
      transition: Transition.cupertino, // Standard push
    ),

    // Profile Setup
    GetPage(
      name: AppRoutes.profileSetup,
      page: () => const ProfileSetupScreen(),
      transition: Transition.cupertino, // Standard push
    ),

    // Profile Screen
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ProfileController>(() => ProfileController());
      }),
      transition: Transition.cupertino, // Standard push
    ),

    // Dashboard (main screen after login)
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardScreen(),
      binding: DashboardBinding(),
      middlewares: [OnboardingMiddleware()],
      transition: Transition.fadeIn, // Smooth entry to main app
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
      transition: Transition.cupertino, // Standard navigation
    ),
    // City Selection Screen
    GetPage(
      name: AppRoutes.selectCity,
      page: () => const SelectCityScreen(),
      transition: Transition.leftToRight, // Standard navigation
      binding: SelectedCityBinding(),
    ),
    // Family Screens
    GetPage(
      name: AppRoutes.family,
      page: () => const FamilyDashboardScreen(),
      binding: FamilyBinding(),
      transition: Transition.cupertino, // Standard navigation
    ),
    GetPage(
      name: AppRoutes.createFamily,
      page: () => const CreateFamilyScreen(),
      binding: FamilyBinding(),
      transition: Transition.cupertino, // Standard navigation
    ),
    GetPage(
      name: AppRoutes.joinFamily,
      page: () => const JoinFamilyScreen(),
      binding: FamilyBinding(),
      transition: Transition.cupertino, // Standard navigation
    ),

    GetPage(
      name: AppRoutes.missedPrayers,
      page: () => const MissedPrayersScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<MissedPrayersController>(() => MissedPrayersController());
      }),
      transition: Transition.downToUp,
    ),
    
    // Qibla
    GetPage(
      name: AppRoutes.qibla,
      page: () => const QiblaScreen(),
      transition: Transition.cupertino,
    ),
  ];
}
