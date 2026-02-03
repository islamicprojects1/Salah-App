import 'package:get/get.dart';
import 'package:salah/controller/family_controller.dart';
import 'package:salah/core/services/family_service.dart';

class FamilyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FamilyService>(() => FamilyService());
    Get.lazyPut<FamilyController>(() => FamilyController());
  }
}
