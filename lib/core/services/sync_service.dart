import 'package:get/get.dart';
import 'package:salah/core/constants/storage_keys.dart';
import 'package:salah/core/feedback/sync_status.dart';
import 'package:salah/core/services/connectivity_service.dart';
import 'package:salah/core/services/database_helper.dart';
import 'package:salah/core/services/storage_service.dart';
import 'package:salah/data/repositories/prayer_repository.dart';

/// GetX service that holds reactive sync state and triggers sync on reconnect.
///
/// Sync logic (queue process, Firestore upload) lives in [PrayerRepository].
/// This service only: exposes [SyncState], mirrors [ConnectivityService].isConnected
/// as [isOnline], and uses a GetX Worker to call [PrayerRepository.syncAllPending]
/// when connectivity is restored.
class SyncService extends GetxService {
  late final ConnectivityService _connectivity;
  late final DatabaseHelper _database;
  late final StorageService _storage;

  /// Reactive sync state for UI (Obx/GetX).
  final SyncState state = SyncState();

  /// Sync progress 0.0..1.0 during sync (for optional progress UI).
  final RxDouble syncProgress = 0.0.obs;

  /// Whether device is online. Mirrors [ConnectivityService.isConnected].
  bool get isOnline => _connectivity.isConnected.value;

  /// Observable for reactive UI: Obx(() => syncService.isOnlineObs.value).
  RxBool get isOnlineObs => _connectivity.isConnected;

  Future<SyncService> init() async {
    _connectivity = Get.find<ConnectivityService>();
    _database = Get.find<DatabaseHelper>();
    _storage = Get.find<StorageService>();

    await refreshPendingCount();
    _loadLastSyncTime();

    return this;
  }

  /// Call after [PrayerRepository] is registered. GetX Worker: when connectivity is restored, trigger sync.
  void startConnectivityWorker() {
    ever(_connectivity.isConnected, (connected) {
      if (connected && Get.isRegistered<PrayerRepository>()) {
        Get.find<PrayerRepository>().syncAllPending();
      }
    });
  }

  /// Refresh pending sync count from SQLite (called after queue add/remove).
  Future<void> refreshPendingCount() async {
    state.pendingCount.value = await _database.getSyncQueueCount();
  }

  void _loadLastSyncTime() {
    final timeStr = _storage.read<String>(StorageKeys.lastSyncTimestamp);
    if (timeStr != null) {
      state.lastSyncTime.value = DateTime.tryParse(timeStr);
    }
  }

  /// Called by [PrayerRepository] after a successful sync.
  Future<void> setLastSyncTime(DateTime time) async {
    state.lastSyncTime.value = time;
    await _storage.write(
      StorageKeys.lastSyncTimestamp,
      time.toIso8601String(),
    );
  }

  /// Optional: set progress 0.0..1.0 during sync (for UI).
  void setSyncProgress(double value) {
    syncProgress.value = value;
  }
}
