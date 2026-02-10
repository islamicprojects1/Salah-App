import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
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
import 'package:salah/core/services/connectivity_service.dart';
import 'package:salah/core/services/database_helper.dart';
import 'package:salah/core/services/sync_service.dart';
import 'package:salah/core/services/location_service.dart';
import 'package:salah/data/repositories/prayer_repository.dart';
import 'package:salah/data/repositories/user_repository.dart';
import 'package:salah/core/services/prayer_time_service.dart';
import 'package:salah/core/services/family_service.dart';
import 'package:salah/controller/auth_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize services
  await initServices();

  runApp(const SalahApp());

  // Initialize heavy, non-critical services after first frame
  // to avoid blocking initial render (reduces jank on startup).
  WidgetsBinding.instance.addPostFrameCallback((_) {
    initLateServices();
  });
}

/// Initialize all app services
/// Optimized to initialize independent services in parallel for faster startup
Future<void> initServices() async {
  // 1. Storage & Database services (parallel)
  await Future.wait([
    Get.putAsync<StorageService>(() async {
      final service = StorageService();
      return await service.init();
    }),
    Get.putAsync<DatabaseHelper>(() async {
      final service = DatabaseHelper();
      return await service.init();
    }),
  ]);

  // 2. Initialize independent services in parallel
  await Future.wait([
    Get.putAsync<ThemeService>(() async {
      final service = ThemeService();
      return await service.init();
    }),
    Get.putAsync<LocalizationService>(() async {
      final service = LocalizationService();
      return await service.init();
    }),
    Get.putAsync<LocationService>(() => LocationService().init()),
    Get.putAsync<ConnectivityService>(() => ConnectivityService().init()),
  ]);

  // 3. Firestore
  await Get.putAsync<FirestoreService>(() => FirestoreService().init());

  // 4. Auth service (depends on Firestore)
  await Get.putAsync<AuthService>(() => AuthService().init());

  // 5. Sync service – holds sync state; worker started after PrayerRepository is registered
  await Get.putAsync<SyncService>(() => SyncService().init());

  // 6. Prayer repository (permanent) – handles offline sync; SyncService worker calls syncAllPending on reconnect
  Get.put<PrayerRepository>(
    PrayerRepository(
      firestore: Get.find(),
      database: Get.find(),
      connectivity: Get.find(),
      syncService: Get.find(),
      auth: Get.find(),
    ),
    permanent: true,
  );
  Get.find<SyncService>().startConnectivityWorker();

  // 6b. UserRepository (DashboardController needs it)
  Get.put<UserRepository>(
    UserRepository(
      firestore: Get.find(),
      database: Get.find(),
      connectivity: Get.find(),
      prayerRepository: Get.find(),
    ),
    permanent: true,
  );

  // 7. Auth controller (depends on all auth-related services)
  Get.put(AuthController(), permanent: true);
}

/// Initialize heavy services that are not required for the very first frame.
/// Runs right after the first frame is rendered.
Future<void> initLateServices() async {
  await Future.wait([
    Get.putAsync<PrayerTimeService>(() => PrayerTimeService().init()),
    Get.putAsync<NotificationService>(() => NotificationService().init()),
  ]);
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
      // home: AppLoading(),
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
