import 'package:get/get.dart';
import 'package:salah/features/onboarding/controller/onboarding_controller.dart';

/// Binding for onboarding feature dependencies
class OnboardingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OnboardingController>(
      () => OnboardingController(),
      fenix: true,
    );
  }
}
