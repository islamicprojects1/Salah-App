import 'package:get/get.dart';
import 'package:salah/features/auth/controller/auth_controller.dart';

/// Binding for authentication screens
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    /// Use fenix: true so the controller is recreated if disposed and
    /// the route is re-entered (e.g. logout → login → back to login)
    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
  }
}
