import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// CONNECTIVITY SERVICE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// ✅ ضروري — يراقب حالة الاتصال بالإنترنت بشكل تفاعلي (Reactive).
//
// يُستخدَم من قِبَل:
//   • SyncService    — لمعرفة متى يبدأ رفع السجلات المعلّقة إلى Firestore
//   • ConnectionStatusIndicator — عرض شريط الاتصال في الـ UI
//   • PrayerRepository — تقرير ما إذا كان الحفظ يذهب محلياً أو للسحابة
//
// ملاحظة: connectivity_plus تكشف نوع الشبكة (WiFi/Mobile/...)
// لكنها لا تضمن وجود اتصال فعلي بالإنترنت. إذا احتجت التحقق الفعلي
// يمكن إضافة ping بسيط لـ Google DNS.
//
// الاستخدام:
//   ConnectivityService.to.isConnected.value  // Rx<bool>
//   ConnectivityService.to.isOffline
//   ConnectivityService.to.isWifi
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class ConnectivityService extends GetxService {
  // اختصار للوصول السريع
  static ConnectivityService get to => Get.find();

  // ══════════════════════════════════════════════════════════════
  // OBSERVABLE STATE
  // ══════════════════════════════════════════════════════════════

  /// هل يوجد اتصال بالإنترنت حالياً
  final isConnected = true.obs;

  /// نوع الاتصال (WiFi / Mobile / none ...)
  final connectionType = Rxn<ConnectivityResult>();

  // ══════════════════════════════════════════════════════════════
  // PRIVATE
  // ══════════════════════════════════════════════════════════════

  late final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isInitialized = false;

  // ══════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ══════════════════════════════════════════════════════════════

  Future<ConnectivityService> init() async {
    if (_isInitialized) return this;
    _isInitialized = true;

    _connectivity = Connectivity();

    // فحص أولي فوري عند بدء التطبيق
    await _checkConnectivity();

    // الاستماع للتغييرات اللاحقة
    _startListening();

    return this;
  }

  // ══════════════════════════════════════════════════════════════
  // GETTERS
  // ══════════════════════════════════════════════════════════════

  /// اتصال WiFi
  bool get isWifi => connectionType.value == ConnectivityResult.wifi;

  /// اتصال بيانات الجوال
  bool get isMobile => connectionType.value == ConnectivityResult.mobile;

  /// لا يوجد اتصال
  bool get isOffline => !isConnected.value;

  /// نص وصفي لنوع الاتصال (للعرض أو التشخيص)
  String get connectionTypeLabel {
    switch (connectionType.value) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.none:
      case null:
        return 'No Connection';
      default:
        return 'Unknown';
    }
  }

  // ══════════════════════════════════════════════════════════════
  // PUBLIC METHODS
  // ══════════════════════════════════════════════════════════════

  /// فحص الاتصال الآن (مفيد عند الضغط على "إعادة المحاولة")
  Future<bool> checkConnection() async {
    await _checkConnectivity();
    return isConnected.value;
  }

  // ══════════════════════════════════════════════════════════════
  // PRIVATE METHODS
  // ══════════════════════════════════════════════════════════════

  Future<void> _checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);
  }

  void _startListening() {
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final hasConnection =
        results.isNotEmpty && !results.contains(ConnectivityResult.none);

    isConnected.value = hasConnection;
    connectionType.value = hasConnection
        ? results.first
        : ConnectivityResult.none;
  }

  // ══════════════════════════════════════════════════════════════
  // CLEANUP
  // ══════════════════════════════════════════════════════════════

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
