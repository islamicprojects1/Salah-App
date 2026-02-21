import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// PERMISSION SERVICE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// ✅ ضروري — نقطة مركزية لطلب وتتبّع صلاحيات التطبيق.
//
// الصلاحيات المُدارة:
//   • الموقع       → لحساب مواقيت الصلاة واتجاه القبلة
//   • الإشعارات    → لإرسال تنبيهات الصلاة
//   • الإنذار الدقيق (Android 12+) → لجدولة إشعارات الصلاة بدقة
//
// يُستخدَم في:
//   • OnboardingController  — طلب الصلاحيات في أول تشغيل
//   • SettingsController    — إعادة الطلب من الإعدادات
//   • LocationService       — قبل جلب الموقع
//
// الاستخدام:
//   final granted = await PermissionService.to.requestLocationPermission();
//   PermissionService.to.isNotificationGranted
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class PermissionService extends GetxService {
  static PermissionService get to => Get.find();

  // ══════════════════════════════════════════════════════════════
  // OBSERVABLE STATE
  // ══════════════════════════════════════════════════════════════

  final locationStatus = PermissionStatus.denied.obs;
  final notificationStatus = PermissionStatus.denied.obs;

  // ══════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ══════════════════════════════════════════════════════════════

  Future<PermissionService> init() async {
    await checkAllPermissions();
    return this;
  }

  /// فحص حالة جميع الصلاحيات دون طلبها
  Future<void> checkAllPermissions() async {
    locationStatus.value = await Permission.location.status;
    notificationStatus.value = await Permission.notification.status;
  }

  // ══════════════════════════════════════════════════════════════
  // LOCATION
  // ══════════════════════════════════════════════════════════════

  bool get isLocationGranted => locationStatus.value.isGranted;
  bool get isLocationPermanentlyDenied =>
      locationStatus.value.isPermanentlyDenied;

  /// طلب صلاحية الموقع.
  /// إذا كانت مرفوضة نهائياً → يفتح إعدادات التطبيق.
  /// يرجع true إذا مُنحت.
  Future<bool> requestLocationPermission() async {
    final current = await Permission.location.status;

    if (current.isGranted) {
      locationStatus.value = current;
      return true;
    }

    if (current.isPermanentlyDenied) {
      await openAppSettings();
      // نعيد فحص الحالة بعد عودة المستخدم من الإعدادات
      locationStatus.value = await Permission.location.status;
      return locationStatus.value.isGranted;
    }

    final result = await Permission.location.request();
    locationStatus.value = result;
    return result.isGranted;
  }

  /// طلب صلاحية الموقع الدقيق (أفضل دقة للقبلة).
  Future<bool> requestPreciseLocationPermission() async {
    final result = await Permission.locationWhenInUse.request();
    locationStatus.value = result;
    return result.isGranted;
  }

  // ══════════════════════════════════════════════════════════════
  // NOTIFICATIONS
  // ══════════════════════════════════════════════════════════════

  bool get isNotificationGranted => notificationStatus.value.isGranted;
  bool get isNotificationPermanentlyDenied =>
      notificationStatus.value.isPermanentlyDenied;

  /// طلب صلاحية الإشعارات.
  /// إذا كانت مرفوضة نهائياً → يفتح إعدادات التطبيق.
  Future<bool> requestNotificationPermission() async {
    final current = await Permission.notification.status;

    if (current.isGranted) {
      notificationStatus.value = current;
      return true;
    }

    if (current.isPermanentlyDenied) {
      await openAppSettings();
      notificationStatus.value = await Permission.notification.status;
      return notificationStatus.value.isGranted;
    }

    final result = await Permission.notification.request();
    notificationStatus.value = result;
    return result.isGranted;
  }

  // ══════════════════════════════════════════════════════════════
  // EXACT ALARM (Android 12+)
  // ══════════════════════════════════════════════════════════════

  /// صلاحية الإنذار الدقيق — ضرورية لجدولة إشعارات الصلاة في Android 12+.
  /// بدونها قد تتأخر الإشعارات أو لا تصل في الوقت المحدد.
  Future<bool> requestExactAlarmPermission() async {
    final current = await Permission.scheduleExactAlarm.status;
    if (current.isGranted) return true;

    final result = await Permission.scheduleExactAlarm.request();
    return result.isGranted;
  }

  // ══════════════════════════════════════════════════════════════
  // COMBINED
  // ══════════════════════════════════════════════════════════════

  /// هل جميع الصلاحيات الأساسية مُمنوحة؟
  bool get areAllGranted => isLocationGranted && isNotificationGranted;

  /// طلب جميع الصلاحيات المطلوبة دفعة واحدة (للـ Onboarding).
  /// يرجع true إذا مُنحت الموقع والإشعارات معاً.
  Future<bool> requestAllPermissions() async {
    final location = await requestLocationPermission();
    final notification = await requestNotificationPermission();
    await requestExactAlarmPermission(); // لا نشترط نجاحها
    return location && notification;
  }

  // ══════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════

  /// فتح إعدادات التطبيق (لو رفض المستخدم الصلاحية نهائياً)
  Future<void> openSettings() => openAppSettings();
}
