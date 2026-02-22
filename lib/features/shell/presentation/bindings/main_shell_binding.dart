import 'package:get/get.dart';
import 'package:salah/features/family/presentation/bindings/family_binding.dart';
import 'package:salah/features/prayer/presentation/bindings/dashboard_binding.dart';
import 'package:salah/features/shell/controller/main_shell_controller.dart';

/// Main shell binding: registers MainShellController + Dashboard + Family.
class MainShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MainShellController>(() => MainShellController(), fenix: true);
    DashboardBinding().dependencies();
    FamilyBinding().dependencies();
  }
}
