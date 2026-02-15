import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:salah/controller/auth_controller.dart';
import 'package:salah/core/localization/languages.dart';
import 'package:salah/core/services/auth_service.dart';
import 'package:salah/core/services/cloudinary_service.dart';
import 'package:salah/core/services/connectivity_service.dart';
import 'package:salah/core/services/firestore_service.dart';
import 'package:salah/core/services/location_service.dart';
import 'package:salah/core/services/notification_service.dart';
import 'package:salah/core/services/storage_service.dart';
import 'package:salah/core/services/fcm_service.dart';
import 'package:salah/data/repositories/prayer_repository.dart';
import 'firebase_options.dart';

import 'package:salah/core/routes/app_pages.dart';
import 'package:salah/core/services/theme_service.dart';
import 'package:salah/core/services/localization_service.dart';
import 'package:salah/core/services/database_helper.dart';
import 'package:salah/core/services/sync_service.dart';
import 'package:salah/data/repositories/user_repository.dart';
import 'package:salah/core/services/prayer_time_service.dart';
import 'package:salah/core/services/audio_service.dart';
import 'package:salah/core/services/shake_service.dart';
import 'package:salah/core/services/qada_detection_service.dart';

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

Future<void> initServices() async {
  // 1. Foundation (Sequential & Awaited)
  // These are the core dependencies for everything else.
  final storage = await StorageService().init();
  Get.put(storage, permanent: true);

  final db = await DatabaseHelper().init();
  Get.put(db, permanent: true);

  // 2. UI Foundation (Parallel - they only depend on Storage)
  await Future.wait([
    ThemeService().init().then((s) => Get.put(s, permanent: true)),
    LocalizationService().init().then((s) => Get.put(s, permanent: true)),
  ]);

  // 3. Independent Services (Parallel)
  await Future.wait([
    LocationService().init().then((s) => Get.put(s, permanent: true)),
    ConnectivityService().init().then((s) => Get.put(s, permanent: true)),
    CloudinaryService().init().then((s) => Get.put(s, permanent: true)),
  ]);

  // 4. Data Layer (Awaited sequentially due to internal dependencies)
  final firestore = await FirestoreService().init();
  Get.put(firestore, permanent: true);

  final auth = await AuthService().init();
  Get.put(auth, permanent: true);

  final syncService = await SyncService().init();
  Get.put(syncService, permanent: true);

  // 5. Repositories
  final prayerRepo = PrayerRepository(
    firestore: Get.find(),
    database: Get.find(),
    connectivity: Get.find(),
    syncService: Get.find(),
    auth: Get.find(),
  );
  Get.put<PrayerRepository>(prayerRepo, permanent: true);

  final userRepo = UserRepository(
    firestore: Get.find(),
    database: Get.find(),
    connectivity: Get.find(),
    prayerRepository: Get.find(),
  );
  Get.put<UserRepository>(userRepo, permanent: true);

  // 6. Controllers & Workers
  Get.put(AuthController(), permanent: true);

  // 7. Critical Domain Services (Added here to avoid race conditions in bindings)
  await Future.wait([
    PrayerTimeService().init().then((s) => Get.put(s, permanent: true)),
    NotificationService().init().then((s) => Get.put(s, permanent: true)),
    FcmService().init().then((s) => Get.put(s, permanent: true)),
  ]);

  // Start background workers
  syncService.startConnectivityWorker();
}

Future<void> initLateServices() async {
  // Late services are those that aren't needed for the initial Dashboard render
  // but should be ready shortly after.
  await Future.wait([
    AudioService().init().then((s) => Get.put(s, permanent: true)),
    // ShakeService is sync or doesn't have an init() that needs awaiting
    Future.sync(() => Get.put(ShakeService(), permanent: true)),
  ]);

  // Cold start recovery: register QadaDetectionService and trigger initial check
  if (!Get.isRegistered<QadaDetectionService>() &&
      Get.isRegistered<PrayerTimeService>() &&
      Get.isRegistered<PrayerRepository>() &&
      Get.isRegistered<AuthService>() &&
      Get.isRegistered<StorageService>()) {
    final qadaService = QadaDetectionService(
      prayerTimeService: Get.find<PrayerTimeService>(),
      prayerRepo: Get.find<PrayerRepository>(),
      authService: Get.find<AuthService>(),
      storageService: Get.find<StorageService>(),
    );
    Get.put(qadaService, permanent: true);
    // Defer the initial check to avoid blocking late init
    Future.delayed(const Duration(seconds: 2), () {
      qadaService.checkForUnloggedPrayers();
    });
  }
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
      title: 'app_title'.tr,
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
