import 'package:get/get.dart';
import 'package:salah/features/stats/controller/stats_controller.dart';

class StatsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StatsController>(() => StatsController());
  }
}
