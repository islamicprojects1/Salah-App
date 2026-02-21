import 'package:get/get.dart';
import 'package:salah/core/constants/storage_keys.dart';
import 'package:salah/core/feedback/sync_status.dart';
import 'package:salah/core/services/connectivity_service.dart';
import 'package:salah/core/services/database_helper.dart';
import 'package:salah/core/services/storage_service.dart';
import 'package:salah/core/di/injection_container.dart';
import 'package:salah/features/prayer/data/repositories/prayer_repository.dart';
import 'package:salah/features/prayer/data/services/notification_service.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SYNC SERVICE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// ✅ ضروري — يُنسِّق بين الاتصال والمزامنة، ويعرض الحالة للـ UI.
//
// مسؤولياته الثلاث:
//   1. يعكس حالة [ConnectivityService.isConnected] كـ observable للـ UI
//   2. يراقب استعادة الاتصال ويُشغّل المزامنة التلقائية (GetX Worker)
//   3. يحتفظ بـ [SyncState]: عدد العناصر المعلّقة، آخر مزامنة، تقدم الرفع
//
// ما لا يفعله (مسؤولية PrayerRepository):
//   - منطق رفع السجلات إلى Firestore
//   - معالجة الأخطاء وإعادة المحاولة
//   - تحديث قاعدة البيانات المحلية
//
// يُستخدَم في:
//   • ConnectionStatusIndicator  — عرض شريط الاتصال
//   • DashboardController        — تحديث الـ UI بعد المزامنة
//   • PrayerRepository           — استدعاء setLastSyncTime / refreshPendingCount
//
// الاستخدام:
//   SyncService.to.isOnline
//   SyncService.to.isOnlineObs   // للـ Obx
//   SyncService.to.state.pendingCount.value
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class SyncService extends GetxService {
  static SyncService get to => Get.find();

  // ══════════════════════════════════════════════════════════════
  // DEPENDENCIES
  // ══════════════════════════════════════════════════════════════

  late final ConnectivityService _connectivity;
  late final DatabaseHelper _database;
  late final StorageService _storage;

  // ══════════════════════════════════════════════════════════════
  // STATE
  // ══════════════════════════════════════════════════════════════

  /// حالة المزامنة — يقرأها الـ UI عبر Obx
  final SyncState state = SyncState();

  /// تقدم الرفع من 0.0 إلى 1.0 (اختياري للـ UI)
  final syncProgress = 0.0.obs;

  // ══════════════════════════════════════════════════════════════
  // GETTERS
  // ══════════════════════════════════════════════════════════════

  /// هل الجهاز متصل بالإنترنت؟ (للاستخدام غير التفاعلي)
  bool get isOnline => _connectivity.isConnected.value;

  /// Observable للاستخدام داخل Obx
  RxBool get isOnlineObs => _connectivity.isConnected;

  bool _isInitialized = false;

  // ══════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ══════════════════════════════════════════════════════════════

  Future<SyncService> init() async {
    if (_isInitialized) return this;
    _isInitialized = true;

    _connectivity = sl<ConnectivityService>();
    _database = sl<DatabaseHelper>();
    _storage = sl<StorageService>();

    // تحميل آخر وقت مزامنة من التخزين المحلي
    _loadLastSyncTime();

    // جلب عدد العناصر المعلّقة من SQLite
    await refreshPendingCount();

    return this;
  }

  /// يُستدعى بعد تسجيل PrayerRepository في الـ DI.
  /// يبدأ مراقبة الاتصال ويُشغّل المزامنة التلقائية عند الاستعادة.
  void startConnectivityWorker() {
    ever(_connectivity.isConnected, (bool connected) {
      if (!connected) return;

      // عند استعادة الاتصال: ارفع السجلات المعلّقة وأعد جدولة الإشعارات
      if (sl.isRegistered<PrayerRepository>()) {
        sl<PrayerRepository>().syncAllPending();
      }

      // إعادة جدولة الإشعارات لأن المواقيت قد تكون تغيّرت أثناء الانقطاع
      if (sl.isRegistered<NotificationService>()) {
        sl<NotificationService>().rescheduleAllForToday();
      }
    });
  }

  // ══════════════════════════════════════════════════════════════
  // PUBLIC API — يستدعيها PrayerRepository
  // ══════════════════════════════════════════════════════════════

  /// تحديث عدد العناصر المعلّقة (بعد إضافة/حذف من قائمة الانتظار)
  Future<void> refreshPendingCount() async {
    state.pendingCount.value = await _database.getSyncQueueCount();
  }

  /// تسجيل وقت آخر مزامنة ناجحة (يستدعيها PrayerRepository)
  Future<void> setLastSyncTime(DateTime time) async {
    state.lastSyncTime.value = time;
    await _storage.write(StorageKeys.lastSyncTimestamp, time.toIso8601String());
  }

  /// تحديث تقدم الرفع (للـ UI الاختياري)
  void setSyncProgress(double value) =>
      syncProgress.value = value.clamp(0.0, 1.0);

  /// ضبط حالة "جاري المزامنة"
  void setSyncing(bool value) => state.isSyncing.value = value;

  // ══════════════════════════════════════════════════════════════
  // PRIVATE
  // ══════════════════════════════════════════════════════════════

  void _loadLastSyncTime() {
    final stored = _storage.read<String>(StorageKeys.lastSyncTimestamp);
    if (stored != null) {
      state.lastSyncTime.value = DateTime.tryParse(stored);
    }
  }
}
