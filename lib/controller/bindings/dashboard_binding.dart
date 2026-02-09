import 'package:get/get.dart';
import 'package:salah/controller/dashboard_controller.dart';
import 'package:salah/controller/family_controller.dart';
import 'package:salah/controller/qibla_controller.dart';
import 'package:salah/controller/settings_controller.dart';
import 'package:salah/data/repositories/family_repository.dart';
import 'package:salah/data/repositories/achievement_repository.dart';

/// Dashboard bindings: repositories are registered in main (PrayerRepository) or lazy here.
/// Controllers get dependencies via Get.find() or constructor injection.
class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    // PrayerRepository is permanent in main; others lazy
    // PrayerRepository is permanent in main; others lazy
    // UserRepository is permanent in main
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

    Get.lazyPut<DashboardController>(
      () => DashboardController(
        prayerService: Get.find(),
        locationService: Get.find(),
        authService: Get.find(),
        userRepo: Get.find(),
        prayerRepo: Get.find(),
        notificationService: Get.find(),
      ),
      fenix: true,
    );
    Get.lazyPut<FamilyController>(() => FamilyController(), fenix: true);
    Get.lazyPut<QiblaController>(() => QiblaController(), fenix: true);
    Get.lazyPut<SettingsController>(() => SettingsController(), fenix: true);
  }
}

