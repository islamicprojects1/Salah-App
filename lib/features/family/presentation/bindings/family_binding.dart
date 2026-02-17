import 'package:get/get.dart';
import 'package:salah/features/family/controller/family_controller.dart';

/// Binding for family-related screens.
///
/// `FamilyService` is already registered in `DashboardBinding` to keep
/// a single instance for the whole app, so we only ensure the controller here.
class FamilyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FamilyController>(() => FamilyController(), fenix: true);
  }
}
