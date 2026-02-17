import 'package:get/get.dart';
import 'package:salah/core/di/injection_container.dart';
import 'package:salah/features/auth/data/services/auth_service.dart';
import 'package:salah/features/family/controller/family_controller.dart';
import 'package:salah/features/family/data/models/family_pulse_model.dart';

class NotificationsController extends GetxController {
  final _familyController = Get.find<FamilyController>();

  final _authService = sl<AuthService>();

  /// List of pulse events to display as notifications (filtered for others only)
  List<FamilyPulseEvent> get notifications => _familyController.pulseEvents
      .where((e) => e.userId != _authService.userId)
      .toList();

  /// Mark all as read logic could go here if implemented in FamilyController
  void markAllAsRead() {
    // For now we just use the pulse events which are reactive
  }

  /// Navigation back
  void goBack() {
    Get.back();
  }
}
