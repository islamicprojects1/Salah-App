import 'package:get/get.dart';
import 'package:salah/controller/settings_controller.dart';

/// Binding for Settings screen
/// 
/// Initializes SettingsController when navigating to settings
class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SettingsController>(() => SettingsController());
  }
}
