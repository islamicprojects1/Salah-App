import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:salah/core/routes/app_routes.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SHAKE SERVICE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// ✅ ضروري — يستقبل أحداث اهتزاز الجهاز من الكود الأصلي (Native)
//            ويفتح شاشة القبلة فوراً.
//
// كيف يعمل؟
//   Android/iOS ← يكشف الاهتزاز عبر Accelerometer
//   ← يرسل event عبر MethodChannel("com.salah.app/shake")
//   ← ShakeService يستقبله ويتنقل لشاشة القبلة
//
// لماذا Native وليس Dart؟
//   كشف الاهتزاز الموثوق يحتاج وصول مستمر للـ Accelerometer في الخلفية،
//   وهذا يتطلب كوداً أصلياً في Android/iOS لضمان الدقة وتوفير البطارية.
//
// يُسجَّل في:
//   main.dart → Get.put(ShakeService()) قبل runApp
//
// الاستخدام:
//   لا تحتاج استدعاءه يدوياً — يعمل تلقائياً بعد التسجيل.
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class ShakeService extends GetxService {
  static const _channel = MethodChannel('com.salah.app/shake');

  // ══════════════════════════════════════════════════════════════
  // OBSERVABLE STATE
  // ══════════════════════════════════════════════════════════════

  /// هل ميزة الاهتزاز مفعّلة (يمكن ربطها بإعداد في الـ Settings)
  final isEnabled = true.obs;

  // ══════════════════════════════════════════════════════════════
  // PRIVATE
  // ══════════════════════════════════════════════════════════════

  /// منع التنقل المتعدد عند اهتزازات متتالية سريعة
  bool _isNavigating = false;

  // ══════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ══════════════════════════════════════════════════════════════

  @override
  void onInit() {
    super.onInit();
    _initShakeListener();
  }

  // ══════════════════════════════════════════════════════════════
  // PRIVATE METHODS
  // ══════════════════════════════════════════════════════════════

  void _initShakeListener() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onShake') {
        _handleShake();
      }
    });
  }

  void _handleShake() {
    // لا نتنقل إذا كانت الميزة معطّلة
    if (!isEnabled.value) return;

    // لا نتنقل إذا كنا بالفعل في شاشة القبلة أو في منتصف تنقل
    final currentRoute = Get.currentRoute.split('?').first;
    if (currentRoute == AppRoutes.qibla || _isNavigating) return;

    _isNavigating = true;
    HapticFeedback.lightImpact();

    Get.toNamed(AppRoutes.qibla)?.then((_) {
      _isNavigating = false;
    });
  }

  // ══════════════════════════════════════════════════════════════
  // PUBLIC API
  // ══════════════════════════════════════════════════════════════

  /// تفعيل/تعطيل ميزة الاهتزاز (من إعدادات التطبيق)
  void setEnabled(bool value) => isEnabled.value = value;
}
