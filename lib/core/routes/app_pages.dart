import 'package:get/get.dart';
import 'app_routes.dart';
import '../../view/screens/splash/splash_screen.dart';
import '../../view/screens/home/home_screen.dart';
import '../../view/screens/settings/settings_screen.dart';
import '../../controller/bindings/settings_binding.dart';

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
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    // Home Screen
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    
    // Settings Screen
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsScreen(),
      binding: SettingsBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
  ];
}
