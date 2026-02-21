import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/di/injection_container.dart';
import 'package:salah/core/localization/languages.dart';
import 'package:salah/core/routes/app_pages.dart';
import 'package:salah/features/settings/data/services/theme_service.dart';
import 'package:salah/features/settings/data/services/localization_service.dart';

/// Root application widget.
///
/// Uses [GetMaterialApp] for routing and reactive theme/locale binding.
/// All services are retrieved via the [sl] locator.
class SalahApp extends StatelessWidget {
  const SalahApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = sl<ThemeService>();
    final localizationService = sl<LocalizationService>();

    return Obx(() => GetMaterialApp(
      // App info
      title: 'app_title'.tr,
      debugShowCheckedModeBanner: false,

      // Theme - reactive
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

      // Builder: reactive RTL/LTR so language change updates direction everywhere
      builder: (context, child) {
        return Obx(() => Directionality(
              textDirection: localizationService.isRTL
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: child ?? const SizedBox.shrink(),
            ));
      },
    ));
  }
}
