import 'package:get/get.dart';
import 'package:salah/core/constants/enums.dart';

/// Pairs a [SyncStatus] with an optional human-readable [message].
class SyncStatusResult {
  const SyncStatusResult(this.status, [this.message]);

  final SyncStatus status;
  final String? message;

  bool get isIdle => status == SyncStatus.idle;
  bool get isLoading => status == SyncStatus.loading;
  bool get isSuccess => status == SyncStatus.success;
  bool get isError => status == SyncStatus.error;

  @override
  String toString() =>
      'SyncStatusResult(${status.name}${message != null ? ', $message' : ''})';
}

/// Reactive sync state intended to be embedded in a [GetxService].
///
/// Expose the observables and bind with `Obx` in your UI:
/// ```dart
/// Obx(() => Text(syncState.status.value.isLoading ? 'Syncing…' : 'Done'))
/// ```
class SyncState {
  final Rx<SyncStatusResult> status = Rx<SyncStatusResult>(
    const SyncStatusResult(SyncStatus.idle),
  );

  final RxInt pendingCount = 0.obs;
  final Rxn<DateTime> lastSyncTime = Rxn<DateTime>();
  final RxBool isSyncing = false.obs;

  // ============================================================
  // STATE TRANSITIONS
  // ============================================================

  void setLoading() {
    status.value = const SyncStatusResult(SyncStatus.loading);
    isSyncing.value = true;
  }

  void setSuccess() {
    status.value = const SyncStatusResult(SyncStatus.success);
    isSyncing.value = false;
    lastSyncTime.value = DateTime.now();
  }

  void setError([String? message]) {
    status.value = SyncStatusResult(SyncStatus.error, message);
    isSyncing.value = false;
  }

  void setIdle() {
    status.value = const SyncStatusResult(SyncStatus.idle);
    isSyncing.value = false;
  }

  // ============================================================
  // HELPERS
  // ============================================================

  /// Resets everything to the initial idle state.
  void reset() {
    setIdle();
    pendingCount.value = 0;
    lastSyncTime.value = null;
  }
}
