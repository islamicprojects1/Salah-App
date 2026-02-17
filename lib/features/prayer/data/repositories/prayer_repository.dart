import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salah/core/feedback/app_feedback.dart';
import 'package:salah/features/auth/data/services/auth_service.dart';
import 'package:salah/features/prayer/data/models/prayer_log_model.dart';
import 'package:salah/features/prayer/data/models/sync_queue_models.dart';
import 'package:salah/shared/data/repositories/base_repository.dart';
import 'package:uuid/uuid.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/error/app_logger.dart';
import 'package:salah/core/services/connectivity_service.dart';
import 'package:salah/core/services/database_helper.dart';
import 'package:salah/core/services/sync_service.dart';

/// Repository for prayer-related data and offline sync.
///
/// GetX Clean Architecture: all data fetching (Firestore, SQLite) and sync
/// logic live here. Controllers only call this repository and bind to observables.
/// Sync state is reported via [SyncService]. Connectivitiy triggers sync via
/// GetX Worker in [SyncService].
class PrayerRepository extends BaseRepository {
  final DatabaseHelper _databaseHelper;
  final ConnectivityService _connectivity;
  final SyncService _syncService;
  final AuthService _authService;

  PrayerRepository({
    required super.firestore,
    required DatabaseHelper database,
    required ConnectivityService connectivity,
    required SyncService syncService,
    required AuthService auth,
  }) : _databaseHelper = database,
       _connectivity = connectivity,
       _syncService = syncService,
       _authService = auth;

  /// Whether device is online (reactive via ConnectivityService).
  bool get _isOnline => _connectivity.isConnected.value;

  /// Add a prayer log for a user. Saves locally first (optimistic), then syncs when online.
  /// Returns [true] if synced to server immediately, [false] if saved locally only (queued for later sync).
  Future<bool> addPrayerLog({
    required String userId,
    required PrayerLogModel log,
  }) async {
    try {
      final logMap = log.toMap();
      logMap['userId'] = userId;
      logMap['isSynced'] = 0;

      final localId = await _databaseHelper.insertPrayerLog(logMap);
      bool synced = false;

      if (_isOnline) {
        try {
          final docId = await firestore.addPrayerLog(userId, log.toFirestore());
          await _databaseHelper.markPrayerLogSynced(localId, docId);
          synced = true;
        } catch (e) {
          AppLogger.warning(
            'addPrayerLog: Firestore failed, queuing for sync',
            e,
          );
          await _queueForSync(localId, log);
        }
      } else {
        await _queueForSync(localId, log);
      }
      await _syncService.refreshPendingCount();
      return synced;
    } catch (e) {
      AppLogger.error('addPrayerLog failed', e);
      throw Exception('Failed to add prayer log: ${handleError(e)}');
    }
  }

  static const _syncItemTimeout = Duration(seconds: 15);

  Future<void> _queueForSync(int localId, PrayerLogModel log) async {
    final data = log.toMap();
    data['localId'] = localId;
    data['clientId'] = const Uuid().v4();
    await _addToQueue(SyncItemType.prayerLog, data);
  }

  /// Queue an item for later sync (used by this repo and by [UserRepository]/[AchievementRepository]).
  Future<void> _addToQueue(SyncItemType type, Map<String, dynamic> data) async {
    await _databaseHelper.addToSyncQueue(type.name, jsonEncode(data));
    await _syncService.refreshPendingCount();
  }

  /// Public API for other repositories to queue user updates.
  Future<void> queueUserUpdate(Map<String, dynamic> userData) async {
    await _addToQueue(SyncItemType.userUpdate, userData);
    if (_isOnline) syncAllPending();
  }

  /// Public API for other repositories to queue achievement updates.
  Future<void> queueAchievementUpdate({
    required String userId,
    required String achievementId,
    required Map<String, dynamic> data,
  }) async {
    await _addToQueue(SyncItemType.achievementUpdate, {
      'achievementId': achievementId,
      'data': data,
    });
    if (_isOnline) syncAllPending();
  }

  /// Process all pending sync queue items. Called by [SyncService] when connectivity is restored.
  Future<SyncResult> syncAllPending() async {
    if (!_isOnline) {
      return SyncResult(
        success: false,
        synced: 0,
        failed: 0,
        message: 'No internet connection',
      );
    }
    if (_syncService.state.isSyncing.value) {
      return SyncResult(
        success: false,
        synced: 0,
        failed: 0,
        message: 'Sync already in progress',
      );
    }

    try {
      _syncService.state.setLoading();
      _syncService.syncProgress.value = 0.0;

      final queue = await _getQueue();
      if (queue.isEmpty) {
        _syncService.state.setSuccess();
        return SyncResult(success: true, synced: 0, failed: 0);
      }

      int synced = 0, failed = 0;
      for (int i = 0; i < queue.length; i++) {
        _syncService.setSyncProgress((i + 1) / queue.length);
        final item = queue[i];
        if (_shouldSkipItem(item)) continue;
        final success = await _syncItem(
          item,
        ).timeout(_syncItemTimeout, onTimeout: () => false);
        if (success) {
          synced++;
          await _databaseHelper.removeFromSyncQueue(item.id);
        } else {
          failed++;
          await _databaseHelper.updateSyncRetryCount(item.id);
        }
      }

      await _syncService.refreshPendingCount();
      await _syncService.setLastSyncTime(DateTime.now());

      if (failed == 0) {
        _syncService.state.setSuccess();
      } else {
        _syncService.state.setError('$failed items failed to sync');
        AppLogger.warning('syncAllPending: $failed items failed to sync');
        if (!Get.isSnackbarOpen) {
          AppFeedback.showSnackbar('warning'.tr, 'sync_failed_retry'.tr);
        }
      }
      _syncService.syncProgress.value = 0.0;

      return SyncResult(
        success: failed == 0,
        synced: synced,
        failed: failed,
        message: failed > 0 ? '$failed failed' : null,
      );
    } catch (e) {
      AppLogger.error('syncAllPending failed', e);
      _syncService.state.setError(handleError(e));
      _syncService.syncProgress.value = 0.0;
      if (!Get.isSnackbarOpen) {
        AppFeedback.showSnackbar('warning'.tr, 'sync_failed_retry'.tr);
      }
      return SyncResult(
        success: false,
        synced: 0,
        failed: 0,
        message: handleError(e),
      );
    }
  }

  bool _shouldSkipItem(SyncQueueItem item) {
    if (item.retryCount == 0) return false;
    final delaySeconds =
        (5 * (1 << (item.retryCount > 10 ? 10 : item.retryCount)));
    final nextRetry =
        item.lastAttempt?.add(Duration(seconds: delaySeconds)) ??
        item.createdAt;
    return DateTime.now().isBefore(nextRetry);
  }

  Future<List<SyncQueueItem>> _getQueue() async {
    final items = await _databaseHelper.getSyncQueue();
    return items.map((e) => SyncQueueItem.fromSqlite(e)).toList();
  }

  Future<bool> _syncItem(SyncQueueItem item) async {
    try {
      final userId = _authService.currentUser.value?.uid;
      if (userId == null) return false;

      switch (item.type) {
        case SyncItemType.prayerLog:
          final data = Map<String, dynamic>.from(item.data);
          if (data['prayedAt'] is String) {
            data['prayedAt'] = Timestamp.fromDate(
              DateTime.parse(data['prayedAt'] as String),
            );
          }
          if (data['adhanTime'] is String) {
            data['adhanTime'] = Timestamp.fromDate(
              DateTime.parse(data['adhanTime'] as String),
            );
          }
          final firestoreData = {
            'oderId': data['oderId'],
            'prayer': data['prayer'],
            'prayedAt': data['prayedAt'],
            'adhanTime': data['adhanTime'],
            'quality': data['quality'],
            'timingQuality': data['timingQuality'],
            'note': data['note'],
          };
          final clientId = data['clientId'] as String?;
          final String docId;
          if (clientId != null && clientId.isNotEmpty) {
            await firestore.setPrayerLog(userId, clientId, firestoreData);
            docId = clientId;
          } else {
            docId = await firestore.addPrayerLog(userId, firestoreData);
          }
          if (data['localId'] != null) {
            await _databaseHelper.markPrayerLogSynced(
              data['localId'] as int,
              docId,
            );
          }
          return true;

        case SyncItemType.userUpdate:
          await firestore.updateUser(userId, item.data);
          return true;

        case SyncItemType.reaction:
          await firestore.addReaction(
            senderId: userId,
            receiverId:
                item.data['receiverId'] as String? ??
                item.data['feedItemId'] as String,
            type: item.data['reactionType'] as String,
            prayerName: item.data['prayerName'] as String,
            message: item.data['message'] as String?,
          );
          return true;

        case SyncItemType.groupUpdate:
          await firestore.updateGroup(
            item.data['groupId'] as String,
            item.data['updates'] as Map<String, dynamic>,
          );
          return true;

        case SyncItemType.achievementUpdate:
          await firestore.updateUserAchievement(
            userId,
            item.data['achievementId'] as String,
            item.data['data'] as Map<String, dynamic>,
          );
          return true;
      }
    } on FirebaseException catch (e) {
      // Use global feedback only for user-facing errors; sync retries in background
      if (Get.isSnackbarOpen) return false;
      AppFeedback.showError('Sync error', e.message);
      return false;
    } catch (_) {
      return false;
    }
  }

  /// One-shot fetch of today's prayer logs (e.g. after logging a prayer offline).
  Future<List<PrayerLogModel>> getTodayPrayerLogsOnce(String userId) async {
    final localLogs = await _databaseHelper.getTodayPrayerLogs(userId);
    return _mapLocalLogsToModels(localLogs);
  }

  /// Get today's prayer logs stream. Merges local and remote logs.
  Stream<List<PrayerLogModel>> getTodayPrayerLogs(String userId) async* {
    // 1. Initial local logs
    final localLogs = await _databaseHelper.getTodayPrayerLogs(userId);
    var logs = _mapLocalLogsToModels(localLogs);
    yield logs;

    if (_isOnline) {
      // 2. Continuous Firestore updates
      await for (final snapshot in firestore.getTodayPrayerLogs(userId)) {
        final remoteLogs = snapshot.docs
            .map((doc) => PrayerLogModel.fromFirestore(doc))
            .toList();

        // Merge local unsynced with remote
        final unsynced = await _databaseHelper.getTodayPrayerLogs(userId);
        final unsyncedModels = _mapLocalLogsToModels(unsynced)
            .where((l) => true) // Just to get a list
            .toList();

        // Final list: Remote logs + any local log not yet in remote
        final merged = <String, PrayerLogModel>{};
        for (final l in remoteLogs) {
          merged[l.prayer.name] = l;
        }
        for (final l in unsyncedModels) {
          // If not in remote, add it (preserves local optimistic update)
          if (!merged.containsKey(l.prayer.name)) {
            merged[l.prayer.name] = l;
          }
        }

        yield merged.values.toList();
      }
    }
  }

  Stream<List<PrayerLogModel>> getPrayerLogsByDate({
    required String userId,
    required DateTime date,
  }) {
    if (!_isOnline) {
      return Stream.fromFuture(
        _databaseHelper
            .getPrayerLogs(
              userId: userId,
              startDate: date,
              endDate: date.add(const Duration(days: 1)),
            )
            .then((maps) => _mapLocalLogsToModels(maps)),
      );
    }
    return firestore
        .getPrayerLogsForDate(userId, date)
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PrayerLogModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<List<PrayerLogModel>> getPrayerLogsInRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final localLogs = await _databaseHelper.getPrayerLogs(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );
      if (!_isOnline) return _mapLocalLogsToModels(localLogs);
      return await firestore.getPrayerLogs(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (_) {
      final localLogs = await _databaseHelper.getPrayerLogs(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );
      return _mapLocalLogsToModels(localLogs);
    }
  }

  List<PrayerLogModel> _mapLocalLogsToModels(List<Map<String, dynamic>> maps) {
    return maps.map((map) {
      return PrayerLogModel(
        id: map['id'].toString(),
        oderId: map['user_id'] as String? ?? '',
        prayer: PrayerName.values.firstWhere(
          (e) => e.name == map['prayer'],
          orElse: () => PrayerName.fajr,
        ),
        prayedAt: DateTime.parse(map['prayed_at'] as String),
        adhanTime: DateTime.parse(map['adhan_time'] as String),
        quality: PrayerQuality.values.firstWhere(
          (e) => e.name == map['quality'],
          orElse: () => PrayerQuality.onTime,
        ),
        timingQuality: map['timing_quality'] != null
            ? PrayerTimingQuality.values.firstWhere(
                (e) => e.name == (map['timing_quality'] as String),
                orElse: () => PrayerTimingQuality.onTime,
              )
            : PrayerTimingQuality.onTime,
        note: map['note'] as String?,
      );
    }).toList();
  }

  Future<int> updateStreak(String userId) async {
    try {
      if (!_isOnline) return 0;
      return await firestore.updateStreak(userId);
    } catch (_) {
      return 0;
    }
  }

  Future<int> getCurrentStreak(String userId) async {
    try {
      if (!_isOnline) return 0;
      final userDoc = await firestore.getUser(userId);
      return userDoc.data()?['currentStreak'] as int? ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Check if a prayer was already logged today (prevents duplicate logging).
  Future<bool> hasLoggedPrayerToday(String userId, PrayerName prayer) async {
    final logs = await _databaseHelper.getTodayPrayerLogs(userId);
    return logs.any((m) => (m['prayer'] as String?) == prayer.name);
  }
}
