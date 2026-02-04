import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:salah/core/services/location_service.dart';

class QiblaController extends GetxController {
  final LocationService _locationService = Get.find<LocationService>();

  final Rxn<double> heading = Rxn<double>();
  final Rxn<double> qiblaDirection = Rxn<double>();
  final RxDouble distanceToKaaba = 0.0.obs; // Distance in kilometers
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  StreamSubscription? _compassSubscription;

  @override
  void onInit() {
    super.onInit();
    _initQibla();
  }

  Future<void> _initQibla() async {
    try {
      isLoading.value = true;
      
      // 1. Ensure we have location
      if (_locationService.currentPosition.value == null) {
        await _locationService.init();
      }

      final pos = _locationService.currentPosition.value;
      if (pos == null) {
        errorMessage.value = 'تعذر الحصول على الموقع الجغرافي';
        return;
      }

      // 2. Calculate Qibla angle and distance
      qiblaDirection.value = _calculateQiblaAngle(pos.latitude, pos.longitude);
      distanceToKaaba.value = _calculateDistance(pos.latitude, pos.longitude);

      // 3. Start listening to compass
      _compassSubscription = FlutterCompass.events?.listen((event) {
        heading.value = event.heading;
      });

    } catch (e) {
      errorMessage.value = 'خطأ في تشغيل البوصلة: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh qibla direction (called from retry button)
  Future<void> refreshQibla() async {
    errorMessage.value = '';
    await _initQibla();
  }

  double _calculateQiblaAngle(double lat, double lon) {
    // Makkah coordinates
    const mLat = 21.4225;
    const mLon = 39.8262;

    final phi1 = lat * (math.pi / 180.0);
    final phi2 = mLat * (math.pi / 180.0);
    final deltaLambda = (mLon - lon) * (math.pi / 180.0);

    final y = math.sin(deltaLambda);
    final x = math.cos(phi1) * math.tan(phi2) - math.sin(phi1) * math.cos(deltaLambda);
    
    double qibla = math.atan2(y, x);
    return qibla * (180.0 / math.pi);
  }

  /// Calculate distance to Kaaba using Haversine formula
  double _calculateDistance(double lat, double lon) {
    const mLat = 21.4225;
    const mLon = 39.8262;
    const earthRadius = 6371.0; // km

    final dLat = (mLat - lat) * (math.pi / 180.0);
    final dLon = (mLon - lon) * (math.pi / 180.0);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat * (math.pi / 180.0)) *
            math.cos(mLat * (math.pi / 180.0)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  @override
  void onClose() {
    _compassSubscription?.cancel();
    super.onClose();
  }
}
