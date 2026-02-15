import 'package:get/get.dart';
import 'package:salah/controller/family_controller.dart';
import 'package:salah/core/services/auth_service.dart';
import 'package:salah/data/models/family_model.dart';
import 'package:salah/data/models/family_pulse_model.dart';

class NotificationsController extends GetxController {
  final _familyController = Get.find<FamilyController>();

  final _authService = Get.find<AuthService>();

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
