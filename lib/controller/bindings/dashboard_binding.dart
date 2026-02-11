import 'package:get/get.dart';
import 'package:salah/controller/dashboard_controller.dart';
import 'package:salah/controller/family_controller.dart';
import 'package:salah/controller/qibla_controller.dart';
import 'package:salah/controller/settings/settings_controller.dart';
import 'package:salah/core/services/family_service.dart';
import 'package:salah/data/repositories/family_repository.dart';
import 'package:salah/data/repositories/achievement_repository.dart';
import 'package:salah/core/services/live_context_service.dart';

/// Dashboard bindings: repositories are registered in main (PrayerRepository) or lazy here.
/// Controllers get dependencies via Get.find() or constructor injection.
class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    // PrayerRepository is permanent in main; others lazy
    // PrayerRepository is permanent in main; others lazy
    // UserRepository is permanent in main
    Get.lazyPut<FamilyService>(() => FamilyService());
    Get.lazyPut<FamilyRepository>(
      () => FamilyRepository(firestore: Get.find()),
    );
    Get.lazyPut<AchievementRepository>(
      () => AchievementRepository(
        firestore: Get.find(),
        database: Get.find(),
        connectivity: Get.find(),
        prayerRepository: Get.find(),
      ),
    );

    Get.lazyPut<LiveContextService>(
      () => LiveContextService(
        prayerTimeService: Get.find(),
        prayerRepository: Get.find(),
        authService: Get.find(),
      ),
      fenix: true,
    );

    Get.lazyPut<DashboardController>(
      () => DashboardController(
        prayerService: Get.find(),
        locationService: Get.find(),
        authService: Get.find(),
        userRepo: Get.find(),
        prayerRepo: Get.find(),
        notificationService: Get.find(),
        liveContextService: Get.find(),
      ),
      fenix: true,
    );
    Get.lazyPut<FamilyController>(() => FamilyController(), fenix: true);
    Get.lazyPut<QiblaController>(() => QiblaController(), fenix: true);
    Get.lazyPut<SettingsController>(() => SettingsController(), fenix: true);
  }
}
