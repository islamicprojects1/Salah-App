import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'core/localization/languages.dart';
import 'core/routes/app_pages.dart';
import 'core/services/storage_service.dart';
import 'core/services/theme_service.dart';
import 'core/services/localization_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
