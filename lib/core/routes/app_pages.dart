import 'package:get/get.dart';
import 'package:salah/features/settings/presentation/bindings/selected_city_binding.dart';
import 'package:salah/core/middleware/onboarding_middleware.dart';
import 'package:salah/features/settings/presentation/screens/select_city_screen.dart';
import 'package:salah/core/routes/app_routes.dart';
import 'package:salah/features/splash/presentation/screens/splash_screen.dart';
import 'package:salah/features/prayer/presentation/screens/home_screen.dart';
import 'package:salah/features/settings/presentation/screens/settings_screen.dart';
import 'package:salah/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:salah/features/onboarding/presentation/bindings/onboarding_binding.dart';
import 'package:salah/features/auth/presentation/screens/login_screen.dart';
import 'package:salah/features/auth/presentation/screens/register_screen.dart';
import 'package:salah/features/auth/presentation/screens/profile_setup_screen.dart';
import 'package:salah/features/prayer/presentation/screens/dashboard_screen.dart';
import 'package:salah/features/settings/presentation/bindings/settings_binding.dart';
import 'package:salah/features/auth/presentation/bindings/auth_binding.dart';
import 'package:salah/features/prayer/presentation/bindings/dashboard_binding.dart';
import 'package:salah/features/prayer/presentation/screens/missed_prayers_screen.dart';
import 'package:salah/features/prayer/controller/missed_prayers_controller.dart';
import 'package:salah/features/profile/presentation/screens/profile_screen.dart';
import 'package:salah/features/stats/presentation/screens/stats_screen.dart';
import 'package:salah/features/stats/presentation/bindings/stats_binding.dart';
import 'package:salah/features/profile/controller/profile_controller.dart';
import 'package:salah/features/prayer/presentation/screens/qibla_screen.dart';

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
      binding: OnboardingBinding(),
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

    // Register — no binding: uses AuthController from Login (still in stack)
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterScreen(),
      transition: Transition.cupertino,
    ),

    // Profile Setup — no binding: uses AuthController from Login/Register
    GetPage(
      name: AppRoutes.profileSetup,
      page: () => const ProfileSetupScreen(),
      transition: Transition.cupertino,
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

    GetPage(
      name: AppRoutes.missedPrayers,
      page: () => const MissedPrayersScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<MissedPrayersController>(() => MissedPrayersController());
      }),
      transition: Transition.downToUp,
    ),

    GetPage(
      name: AppRoutes.stats,
      page: () => const StatsScreen(),
      binding: StatsBinding(),
      transition: Transition.cupertino,
    ),

    // Qibla
    GetPage(
      name: AppRoutes.qibla,
      page: () => const QiblaScreen(),
      transition: Transition.cupertino,
    ),
  ];
}
