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

      // 2. Calculate Qibla angle
      // 2. Calculate Qibla angle
      qiblaDirection.value = _calculateQiblaAngle(pos.latitude, pos.longitude);

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

  @override
  void onClose() {
    _compassSubscription?.cancel();
    super.onClose();
  }
}
