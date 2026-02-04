import 'package:get/get.dart';
import 'package:salah/controller/dashboard_controller.dart';
import 'package:salah/controller/family_controller.dart';
import 'package:salah/controller/qibla_controller.dart';
import 'package:salah/controller/settings_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    // Use fenix: true to keep controllers alive during navigation
    Get.lazyPut<DashboardController>(() => DashboardController(), fenix: true);
    Get.lazyPut<FamilyController>(() => FamilyController(), fenix: true);
    Get.lazyPut<QiblaController>(() => QiblaController(), fenix: true);
    Get.lazyPut<SettingsController>(() => SettingsController(), fenix: true);
  }
}

