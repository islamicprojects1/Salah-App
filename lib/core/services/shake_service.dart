import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:salah/core/routes/app_routes.dart';

/// Service to handle native shake events via MethodChannel
class ShakeService extends GetxService {
  static const _channel = MethodChannel('com.salah.app/shake');

  // Track if navigation is already in progress to avoid multiple rapid pushes
  bool _isNavigating = false;

  @override
  void onInit() {
    super.onInit();
    _initShakeListener();
  }

  void _initShakeListener() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onShake') {
        _handleShake();
      }
    });
  }

  void _handleShake() {
    // Only navigate if we aren't already on the Qibla screen or navigating to it
    // Check using split to ignore any query parameters if they exist
    final current = Get.currentRoute.split('?').first;
    if (current == AppRoutes.qibla || _isNavigating) return;

    _isNavigating = true;

    // Provide haptic feedback if possible, or just navigate
    HapticFeedback.lightImpact();

    Get.toNamed(AppRoutes.qibla)?.then((_) {
      _isNavigating = false;
    });
  }
}
