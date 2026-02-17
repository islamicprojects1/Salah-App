import 'package:get/get.dart';
import 'package:salah/core/di/injection_container.dart';

import 'package:salah/core/services/location_service.dart';
import 'package:salah/features/auth/data/repositories/user_repository.dart';
import 'package:salah/features/auth/data/services/auth_service.dart';
import 'package:salah/features/family/controller/family_controller.dart';
import 'package:salah/features/prayer/controller/dashboard_controller.dart';
import 'package:salah/features/prayer/controller/qibla_controller.dart';
import 'package:salah/features/prayer/data/repositories/prayer_repository.dart';
import 'package:salah/features/prayer/data/services/live_context_service.dart';
import 'package:salah/features/prayer/data/services/notification_service.dart';
import 'package:salah/features/prayer/data/services/prayer_time_service.dart';
import 'package:salah/features/prayer/data/services/qada_detection_service.dart';
import 'package:salah/features/settings/controller/settings_controller.dart'
    show SettingsController;

/// Dashboard bindings: all dependencies retrieved via [sl] (GetIt locator).
///
/// Repositories and services are lazy singletons in [injection_container].
/// Controllers are registered as GetX lazyPut for route lifecycle.
class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    // Dashboard Controller — all deps via sl
    Get.lazyPut<DashboardController>(
      () => DashboardController(
        prayerService: sl<PrayerTimeService>(),
        locationService: sl<LocationService>(),
        authService: sl<AuthService>(),
        userRepo: sl<UserRepository>(),
        prayerRepo: sl<PrayerRepository>(),
        notificationService: sl<NotificationService>(),
        liveContextService: sl<LiveContextService>(),
        qadaService: sl<QadaDetectionService>(),
      ),
      fenix: true,
    );

    // Feature controllers — lazy with fenix for recreation on re-navigation
    Get.lazyPut<FamilyController>(() => FamilyController(), fenix: true);
    Get.lazyPut<QiblaController>(() => QiblaController(), fenix: true);
    Get.lazyPut<SettingsController>(() => SettingsController(), fenix: true);
  }
}
