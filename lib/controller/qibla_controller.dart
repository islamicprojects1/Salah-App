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
  final RxDouble distanceToKaaba = 0.0.obs;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;
  
  // Compass accuracy: 0 = unreliable, 1 = low, 2 = medium, 3 = high
  final RxInt compassAccuracy = 0.obs;
  final RxBool showCalibration = false.obs;
  
  // Facing Qibla state with hysteresis (prevents flickering)
  final RxBool isFacingQibla = false.obs;
  static const double _enterThreshold = 20.0; // Enter green at 20°
  static const double _exitThreshold = 35.0;  // Exit green at 35°
  
  // Smoothing: keep last N readings for averaging (more = smoother)
  final List<double> _headingBuffer = [];
  static const int _smoothingFactor = 12; // Average of last 12 readings

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

      // 3. Start listening to compass with smoothing
      _compassSubscription = FlutterCompass.events?.listen((event) {
        if (event.heading != null) {
          // Add to buffer for smoothing
          _headingBuffer.add(event.heading!);
          if (_headingBuffer.length > _smoothingFactor) {
            _headingBuffer.removeAt(0);
          }
          
          // Calculate smoothed heading (circular average for angles)
          heading.value = _calculateCircularMean(_headingBuffer);
          
          // Update facing Qibla state with hysteresis
          _updateFacingQiblaState();
        }
        
        // Track compass accuracy
        if (event.accuracy != null) {
          compassAccuracy.value = event.accuracy!.round().clamp(0, 3);
        }
      });

    } catch (e) {
      errorMessage.value = 'خطأ في تشغيل البوصلة: $e';
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Calculate circular mean for angles (handles 0°/360° wraparound)
  double _calculateCircularMean(List<double> angles) {
    if (angles.isEmpty) return 0;
    
    double sinSum = 0;
    double cosSum = 0;
    
    for (final angle in angles) {
      sinSum += math.sin(angle * math.pi / 180);
      cosSum += math.cos(angle * math.pi / 180);
    }
    
    return math.atan2(sinSum / angles.length, cosSum / angles.length) * 180 / math.pi;
  }
  
  /// Update facing Qibla state with hysteresis to prevent flickering
  void _updateFacingQiblaState() {
    if (heading.value == null || qiblaDirection.value == null) return;
    
    double angleDiff = (qiblaDirection.value! - heading.value!) % 360;
    if (angleDiff > 180) angleDiff -= 360;
    if (angleDiff < -180) angleDiff += 360;
    final absAngleDiff = angleDiff.abs();
    
    // Hysteresis: different thresholds for entering and exiting
    if (isFacingQibla.value) {
      // Currently facing Qibla - only exit if deviation exceeds exit threshold
      if (absAngleDiff > _exitThreshold) {
        isFacingQibla.value = false;
      }
    } else {
      // Not facing Qibla - only enter if within enter threshold
      if (absAngleDiff <= _enterThreshold) {
        isFacingQibla.value = true;
      }
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
