import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

// ============================================================
// Core Infrastructure
// ============================================================
import 'package:salah/core/services/storage_service.dart';
import 'package:salah/core/services/database_helper.dart';
import 'package:salah/core/services/connectivity_service.dart';
import 'package:salah/core/services/location_service.dart';
import 'package:salah/core/services/cloudinary_service.dart';

// ============================================================
// Core Services
// ============================================================
import 'package:salah/features/settings/data/services/localization_service.dart';
import 'package:salah/features/prayer/data/services/firestore_service.dart';
import 'package:salah/features/auth/data/services/auth_service.dart';
import 'package:salah/core/services/sync_service.dart';
import 'package:salah/features/prayer/data/services/prayer_time_service.dart';
import 'package:salah/features/prayer/data/services/notification_service.dart';
import 'package:salah/core/services/audio_service.dart';
import 'package:salah/core/services/shake_service.dart';
import 'package:salah/features/prayer/data/services/qada_detection_service.dart';
import 'package:salah/features/prayer/data/services/live_context_service.dart';
import 'package:salah/features/prayer/data/services/smart_notification_service.dart';

// ============================================================
// Data Layer
// ============================================================
import 'package:salah/features/prayer/data/repositories/prayer_repository.dart';
import 'package:salah/features/auth/data/repositories/user_repository.dart';

// ============================================================
// Controllers
// ============================================================
import 'package:salah/features/auth/controller/auth_controller.dart';
import 'package:salah/features/settings/data/services/theme_service.dart';

/// Global service locator instance.
///
/// Use `sl<T>()` to retrieve any registered dependency.
/// Register order matters: foundation → core → feature → controllers.
final sl = GetIt.instance;

/// Initialize all application dependencies.
///
/// Called once in `main()` before `runApp()`.
/// Services are registered in dependency order:
/// 1. **Foundation** (Storage, Database, Connectivity) — eager, awaited
/// 2. **Core Services** (Theme, Localization, Location, Auth) — eager, awaited
/// 3. **Data Layer** (Firestore, Sync, Repositories) — lazy
/// 4. **Feature Services** (Prayer, Notification, Family) — lazy
/// 5. **Controllers** — lazy
Future<void> initInjection() async {
  // ============================================================
  // 1. FOUNDATION (Sequential — everything depends on these)
  // ============================================================

  final storage = await StorageService().init();
  sl.registerSingleton<StorageService>(storage);

  final db = await DatabaseHelper().init();
  sl.registerSingleton<DatabaseHelper>(db);

  final connectivity = await ConnectivityService().init();
  sl.registerSingleton<ConnectivityService>(connectivity);

  // ============================================================
  // 2. CORE SERVICES (Parallel where possible)
  // ============================================================

  // UI Foundation (depend only on Storage)
  final results = await Future.wait([
    ThemeService().init(),
    LocalizationService().init(),
    LocationService().init(),
    CloudinaryService().init(),
  ]);
  sl.registerSingleton<ThemeService>(results[0] as ThemeService);
  sl.registerSingleton<LocalizationService>(results[1] as LocalizationService);
  sl.registerSingleton<LocationService>(results[2] as LocationService);
  sl.registerSingleton<CloudinaryService>(results[3] as CloudinaryService);

  // Firestore (no deps, but needed by Auth)
  final firestore = await FirestoreService().init();
  sl.registerSingleton<FirestoreService>(firestore);

  // Auth (needs FirestoreService for FCM token; listeners start immediately)
  final auth = await AuthService().init();
  sl.registerSingleton<AuthService>(auth);

  // ============================================================
  // 3. DATA LAYER (Lazy — only created when first accessed)
  // ============================================================

  // Sync Service (depends on Connectivity, Database, Storage)
  sl.registerLazySingleton<SyncService>(() {
    final sync = SyncService();
    // init() is called lazily; startConnectivityWorker() called after repo ready
    return sync;
  });

  // Prayer Repository (depends on Firestore, Database, Connectivity, Sync, Auth)
  sl.registerLazySingleton<PrayerRepository>(
    () => PrayerRepository(
      firestore: sl<FirestoreService>(),
      database: sl<DatabaseHelper>(),
      connectivity: sl<ConnectivityService>(),
      syncService: sl<SyncService>(),
      auth: sl<AuthService>(),
    ),
  );

  // User Repository (depends on Firestore, Database, Connectivity, PrayerRepo)
  sl.registerLazySingleton<UserRepository>(
    () => UserRepository(
      firestore: sl<FirestoreService>(),
      database: sl<DatabaseHelper>(),
      connectivity: sl<ConnectivityService>(),
      prayerRepository: sl<PrayerRepository>(),
    ),
  );

  // ============================================================
  // 4. FEATURE SERVICES (Lazy — created on-demand)
  // ============================================================

  // Prayer Time calculation
  sl.registerLazySingleton<PrayerTimeService>(() => PrayerTimeService());

  // Notifications (local)
  sl.registerLazySingleton<NotificationService>(() => NotificationService());

  // Smart Notification scheduling
  sl.registerLazySingleton<SmartNotificationService>(
    () => SmartNotificationService(),
  );

  // Qada Detection (depends on PrayerTimeService, PrayerRepo, Auth, Storage)
  sl.registerLazySingleton<QadaDetectionService>(
    () => QadaDetectionService(
      prayerTimeService: sl<PrayerTimeService>(),
      prayerRepo: sl<PrayerRepository>(),
      authService: sl<AuthService>(),
      storageService: sl<StorageService>(),
    ),
  );

  // Live Context (depends on PrayerTimeService, PrayerRepo, Auth)
  sl.registerLazySingleton<LiveContextService>(
    () => LiveContextService(
      prayerTimeService: sl<PrayerTimeService>(),
      prayerRepository: sl<PrayerRepository>(),
      authService: sl<AuthService>(),
    ),
  );

  // Audio & Shake (lazy — not needed at startup)
  sl.registerLazySingleton<AudioService>(() => AudioService());
  sl.registerLazySingleton<ShakeService>(() => ShakeService());

  // ============================================================
  // 5. CONTROLLERS (registered with GetX for route lifecycle)
  // ============================================================

  // AuthController is permanent — survives route changes
  Get.put(AuthController(), permanent: true);
}

/// Initialize services that need async init *after* first frame.
///
/// Called via `addPostFrameCallback` to avoid blocking initial render.
/// These services have `init()` methods that need to be awaited
/// but aren't critical for showing the first screen.
Future<void> initLateServices() async {
  // Initialize SyncService (needs async init)
  final sync = sl<SyncService>();
  await sync.init();
  sync.startConnectivityWorker();

  // Initialize prayer-dependent services in parallel
  await Future.wait<void>([
    sl<PrayerTimeService>().init(),
    sl<NotificationService>().init(),
  ]);

  // Live Context Engine (current prayer, countdown, today summary)
  await sl<LiveContextService>().init();

  // Audio (lazy init after first frame)
  await sl<AudioService>().init();

  // Qada detection (deferred check)
  Future.delayed(const Duration(seconds: 2), () {
    sl<QadaDetectionService>().checkForUnloggedPrayers();
  });
}
