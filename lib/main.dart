import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:salah/core/localization/languages.dart';
import 'package:salah/core/routes/app_pages.dart';
import 'package:salah/core/services/storage_service.dart';
import 'package:salah/core/services/theme_service.dart';
import 'package:salah/core/services/localization_service.dart';
import 'package:salah/core/services/auth_service.dart';
import 'package:salah/core/services/firestore_service.dart';
import 'package:salah/core/services/notification_service.dart';
import 'package:salah/core/services/location_service.dart';
import 'package:salah/core/services/prayer_time_service.dart';
import 'package:salah/core/services/family_service.dart';
import 'package:salah/controller/auth_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize GetStorage
  await GetStorage.init();
  
  // Initialize services
  await initServices();
  
  runApp(const SalahApp());
}

/// Initialize all app services
Future<void> initServices() async {
  // Storage service (must be first)
  await Get.putAsync<StorageService>(() async {
    final service = StorageService();
    return await service.init();
  });
  
  // Theme service
  await Get.putAsync<ThemeService>(() async {
    final service = ThemeService();
    return await service.init();
  });
  
  // Localization service
  await Get.putAsync<LocalizationService>(() async {
    final service = LocalizationService();
    return await service.init();
  });

  // Firestore service
  await Get.putAsync<FirestoreService>(() => FirestoreService().init());

  // Auth service
  await Get.putAsync<AuthService>(() => AuthService().init());

  // Location service
  await Get.putAsync<LocationService>(() => LocationService().init());

  // Prayer time service
  await Get.putAsync<PrayerTimeService>(() => PrayerTimeService().init());

  // Notification service
  await Get.putAsync<NotificationService>(() => NotificationService().init());

  // Family service
  Get.put(FamilyService(), permanent: true);
  
  // Auth controller
  Get.put(AuthController(), permanent: true);
}

/// Main app widget
class SalahApp extends StatelessWidget {
  const SalahApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Get.find<ThemeService>();
    final localizationService = Get.find<LocalizationService>();
    
    return GetMaterialApp(
      // App info
      title: 'صلاة',
      debugShowCheckedModeBanner: false,
      
      // Theme
      theme: themeService.lightTheme,
      darkTheme: themeService.darkTheme,
      themeMode: themeService.themeMode,
      
      // Localization
      translations: Languages(),
      locale: localizationService.currentLocale,
      fallbackLocale: LocalizationService.fallbackLocale,
      
      // Routing
      initialRoute: AppPages.initial,
      getPages: AppPages.pages,
      
      // Default transition
      defaultTransition: Transition.cupertino,
      
      // Builder for global settings
      builder: (context, child) {
        return Directionality(
          textDirection: localizationService.isRTL 
              ? TextDirection.rtl 
              : TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
