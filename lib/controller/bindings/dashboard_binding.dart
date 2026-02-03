import 'package:get/get.dart';
import 'package:salah/controller/dashboard_controller.dart';
import 'package:salah/controller/family_controller.dart';
import 'package:salah/controller/qibla_controller.dart';
import 'package:salah/controller/settings_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DashboardController>(() => DashboardController());
    Get.lazyPut<FamilyController>(() => FamilyController());
    Get.lazyPut<QiblaController>(() => QiblaController());
    Get.lazyPut<SettingsController>(() => SettingsController());
  }
}
