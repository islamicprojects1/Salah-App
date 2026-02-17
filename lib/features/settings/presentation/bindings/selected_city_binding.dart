import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/bindings_interface.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:salah/features/settings/controller/selected_city_controller.dart';

class SelectedCityBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SelectedCityController>(() => SelectedCityController());
  }
}
