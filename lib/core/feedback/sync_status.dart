import 'package:get/get.dart';
import 'package:salah/core/constants/enums.dart';

/// Extension to use SyncStatus with optional error message.
class SyncStatusResult {
  final SyncStatus status;
  final String? message;

  const SyncStatusResult(this.status, [this.message]);

  bool get isIdle => status == SyncStatus.idle;
  bool get isLoading => status == SyncStatus.loading;
  bool get isSuccess => status == SyncStatus.success;
  bool get isError => status == SyncStatus.error;
}

/// Reactive sync state holder for use in services/repositories.
///
/// Expose this in a GetxService so UI can bind with Obx:
///   final syncStatus = Rx<SyncStatusResult>(SyncStatusResult(SyncStatus.idle));
///   final pendingSyncCount = 0.obs;
///   final lastSyncTime = Rxn<DateTime>();
class SyncState {
  final Rx<SyncStatusResult> status =
      Rx<SyncStatusResult>(const SyncStatusResult(SyncStatus.idle));
  final RxInt pendingCount = 0.obs;
  final Rxn<DateTime> lastSyncTime = Rxn<DateTime>();
  final RxBool isSyncing = false.obs;

  void setLoading() {
    status.value = const SyncStatusResult(SyncStatus.loading);
    isSyncing.value = true;
  }

  void setSuccess() {
    status.value = const SyncStatusResult(SyncStatus.success);
    isSyncing.value = false;
  }

  void setError([String? message]) {
    status.value = SyncStatusResult(SyncStatus.error, message);
    isSyncing.value = false;
  }

  void setIdle() {
    status.value = const SyncStatusResult(SyncStatus.idle);
    isSyncing.value = false;
  }
}
