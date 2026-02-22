import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:get/get.dart';
import 'package:salah/core/di/injection_container.dart';
import 'package:salah/core/services/location_service.dart';

class QiblaController extends GetxController {
  final LocationService _locationService = sl<LocationService>();

  final Rxn<double> heading = Rxn<double>();
  final Rxn<double> qiblaDirection = Rxn<double>();
  final RxDouble distanceToKaaba = 0.0.obs;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  String get userCity => _locationService.cityName.value;

  /// Returns "CityName Bearing°" e.g. "Amman 160°"
  String get locationAndBearing {
    final city = _locationService.cityName.value;
    final degrees = qiblaDirection.value?.toStringAsFixed(0) ?? '--';
    if (city.isEmpty) return 'Qibla $degrees°';
    return '$city $degrees°';
  }

  // Compass accuracy: 0 = unreliable, 1 = low, 2 = medium, 3 = high
  final RxInt compassAccuracy = 0.obs;
  final RxBool showCalibration = false.obs;

  String get currentHeadingString => heading.value?.toStringAsFixed(0) ?? '--';

  // Facing Qibla state with hysteresis (prevents flickering)
  final RxBool isFacingQibla = false.obs;
  static const double _enterThreshold = 3.0;
  static const double _exitThreshold = 6.0;
  bool _didHapticForFacing = false;

  // Smoothing buffer
  final List<double> _headingBuffer = [];
  static const int _smoothingFactor = 12;

  StreamSubscription? _compassSubscription;

  @override
  void onInit() {
    super.onInit();
    _initQibla();
  }

  Future<void> _initQibla() async {
    try {
      isLoading.value = true;

      if (_locationService.currentPosition.value == null) {
        await _locationService.init();
      }

      final pos = _locationService.currentPosition.value;
      if (pos == null) {
        errorMessage.value = 'تعذر الحصول على الموقع الجغرافي';
        return;
      }

      qiblaDirection.value = _calculateQiblaAngle(pos.latitude, pos.longitude);
      distanceToKaaba.value = _calculateDistance(pos.latitude, pos.longitude);

      _compassSubscription = FlutterCompass.events?.listen((event) {
        if (event.heading != null) {
          _headingBuffer.add(event.heading!);
          if (_headingBuffer.length > _smoothingFactor) {
            _headingBuffer.removeAt(0);
          }
          // FIX: _calculateCircularMean returned atan2 raw (-180..180).
          // Normalised to 0..360 so the heading display is always positive.
          heading.value = _calculateCircularMean(_headingBuffer);
          _updateFacingQiblaState();
        }

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

  /// Circular mean of angles — normalised to [0, 360).
  /// FIX: atan2 returns values in (-180, 180]. Adding 360 and modding ensures
  /// a non-negative result regardless of quadrant.
  double _calculateCircularMean(List<double> angles) {
    if (angles.isEmpty) return 0;

    double sinSum = 0;
    double cosSum = 0;

    for (final angle in angles) {
      final rad = angle * math.pi / 180;
      sinSum += math.sin(rad);
      cosSum += math.cos(rad);
    }

    final meanRad = math.atan2(sinSum / angles.length, cosSum / angles.length);
    // Normalise to 0..360
    return (meanRad * 180 / math.pi + 360) % 360;
  }

  void _updateFacingQiblaState() {
    if (heading.value == null || qiblaDirection.value == null) return;

    double angleDiff = (qiblaDirection.value! - heading.value!) % 360;
    if (angleDiff > 180) angleDiff -= 360;
    if (angleDiff < -180) angleDiff += 360;
    final absAngleDiff = angleDiff.abs();

    if (isFacingQibla.value) {
      if (absAngleDiff > _exitThreshold) {
        isFacingQibla.value = false;
        _didHapticForFacing = false;
      }
    } else {
      if (absAngleDiff <= _enterThreshold) {
        isFacingQibla.value = true;
        if (!_didHapticForFacing) {
          _didHapticForFacing = true;
          HapticFeedback.mediumImpact();
        }
      }
    }
  }

  /// Signed angle from current heading to Qibla (-180..180).
  /// Positive = turn right, negative = turn left.
  double? get angleToQiblaDegrees {
    final h = heading.value;
    final q = qiblaDirection.value;
    if (h == null || q == null) return null;
    double diff = (q - h) % 360;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    return diff;
  }

  Future<void> refreshQibla() async {
    errorMessage.value = '';
    _headingBuffer.clear();
    _compassSubscription?.cancel();
    await _initQibla();
  }

  /// Qibla bearing from North (0–360°). Standard spherical formula.
  double _calculateQiblaAngle(double lat, double lon) {
    const mLat = 21.4225;
    const mLon = 39.8262;

    final phi1 = lat * (math.pi / 180.0);
    final phi2 = mLat * (math.pi / 180.0);
    final deltaLambda = (mLon - lon) * (math.pi / 180.0);

    final y = math.sin(deltaLambda);
    final x =
        math.cos(phi1) * math.tan(phi2) -
        math.sin(phi1) * math.cos(deltaLambda);

    final degrees = math.atan2(y, x) * (180.0 / math.pi);
    return (degrees + 360) % 360;
  }

  /// Distance to Kaaba via Haversine formula (km).
  double _calculateDistance(double lat, double lon) {
    const mLat = 21.4225;
    const mLon = 39.8262;
    const earthRadius = 6371.0;

    final dLat = (mLat - lat) * (math.pi / 180.0);
    final dLon = (mLon - lon) * (math.pi / 180.0);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
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
