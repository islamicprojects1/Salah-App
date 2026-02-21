import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salah/core/error/app_logger.dart';
import 'package:salah/core/services/connectivity_service.dart';
import 'package:salah/core/services/database_helper.dart';
import 'package:salah/features/auth/data/models/user_model.dart';
import 'package:salah/features/prayer/data/repositories/prayer_repository.dart';
import 'package:salah/shared/data/repositories/base_repository.dart';

/// Repository for user-related data operations.
/// Strategy: cache-first for reads, optimistic writes with queue for offline.
class UserRepository extends BaseRepository {
  final DatabaseHelper _databaseHelper;
  final ConnectivityService _connectivity;
  final PrayerRepository _prayerRepository;

  UserRepository({
    required super.firestore,
    required DatabaseHelper database,
    required ConnectivityService connectivity,
    required PrayerRepository prayerRepository,
  }) : _databaseHelper = database,
       _connectivity = connectivity,
       _prayerRepository = prayerRepository;

  bool get _isOnline => _connectivity.isConnected.value;

  // ============================================================
  // WRITE OPERATIONS
  // ============================================================

  /// Create or update a user in Firestore with local cache backup
  Future<void> saveUser({
    required String userId,
    required UserModel user,
  }) async {
    // Always update cache immediately for instant reads
    await _cacheUser(userId, user);

    if (_isOnline) {
      try {
        await firestore.setUser(userId, user.toFirestore());
      } catch (e) {
        AppLogger.warning('saveUser: Firestore write failed, queuing', e);
        await _prayerRepository.queueUserUpdate(user.toFirestore());
      }
    } else {
      await _prayerRepository.queueUserUpdate(user.toFirestore());
    }
  }

  /// Update specific user profile fields
  Future<void> updateUserProfile({
    required String userId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      if (_isOnline) {
        await firestore.updateUser(userId, updates);
      } else {
        await _prayerRepository.queueUserUpdate(updates);
      }
      // Also update cache with merged data
      await _mergeCachedUser(userId, updates);
    } catch (e) {
      AppLogger.warning('updateUserProfile failed, queuing', e);
      await _prayerRepository.queueUserUpdate(updates);
    }
  }

  // ============================================================
  // READ OPERATIONS
  // ============================================================

  /// Get a user by ID — cache-first, then network
  Future<UserModel?> getUser(String userId) async {
    // 1. Try cache first (fast path)
    final cachedUser = await _getCachedUser(userId);
    if (cachedUser != null) {
      // Refresh from network in background (non-blocking)
      if (_isOnline) {
        _refreshUserFromNetwork(userId).ignore();
      }
      return cachedUser;
    }

    // 2. Cache miss — fetch from network
    if (_isOnline) {
      try {
        final doc = await firestore.getUser(userId);
        if (doc.exists) {
          final user = UserModel.fromFirestore(doc);
          await _cacheUser(userId, user);
          return user;
        }
      } catch (e) {
        AppLogger.warning('getUser: Firestore fetch failed', e);
      }
    }

    return null;
  }

  /// Stream a user document for real-time updates
  Stream<UserModel?> watchUser(String userId) {
    return firestore.getUserStream(userId).map((doc) {
      if (!doc.exists) return null;
      final user = UserModel.fromFirestore(doc);
      // Update cache silently
      _cacheUser(userId, user).ignore();
      return user;
    });
  }

  // ============================================================
  // STREAK HELPERS
  // ============================================================

  Future<void> updateStreak({
    required String userId,
    required int newStreak,
    required int longestStreak,
  }) async {
    await updateUserProfile(
      userId: userId,
      updates: {'currentStreak': newStreak, 'longestStreak': longestStreak},
    );
  }

  Future<int> getStreak(String userId) async {
    final user = await getUser(userId);
    return user?.currentStreak ?? 0;
  }

  // ============================================================
  // NOTIFICATION STREAMS
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> getUserNotificationsStream(
    String userId,
  ) {
    return firestore.getUserNotifications(userId);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getUnreadUserNotificationsStream(
    String userId,
  ) {
    return firestore.getUnreadUserNotifications(userId);
  }

  Future<void> markUserNotificationAsRead({
    required String userId,
    required String notificationId,
  }) async {
    await firestore.markUserNotificationAsRead(userId, notificationId);
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> deleteUser(String userId) async {
    // Clear local cache regardless
    await _databaseHelper.clearAllData();

    if (_isOnline) {
      try {
        await firestore.deleteUser(userId);
      } catch (e) {
        AppLogger.warning('deleteUser: Firestore delete failed', e);
      }
    }
  }

  // ============================================================
  // CACHE HELPERS (PRIVATE)
  // ============================================================

  Future<UserModel?> _getCachedUser(String userId) async {
    try {
      final cachedJson = await _databaseHelper.getCachedUserProfile(userId);
      if (cachedJson == null) return null;
      final data = jsonDecode(cachedJson) as Map<String, dynamic>;
      return UserModel.fromMap(data, userId);
    } catch (e) {
      AppLogger.debug('_getCachedUser: parse error, cache invalidated', e);
      return null;
    }
  }

  Future<void> _cacheUser(String userId, UserModel user) async {
    try {
      await _databaseHelper.cacheUserProfile(userId, jsonEncode(user.toJson()));
    } catch (e) {
      AppLogger.debug('_cacheUser: write failed (non-critical)', e);
    }
  }

  /// Merge partial updates into cached user JSON
  Future<void> _mergeCachedUser(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final cachedJson = await _databaseHelper.getCachedUserProfile(userId);
      if (cachedJson == null) return;
      final data = jsonDecode(cachedJson) as Map<String, dynamic>;
      data.addAll(updates);
      await _databaseHelper.cacheUserProfile(userId, jsonEncode(data));
    } catch (e) {
      AppLogger.debug('_mergeCachedUser: failed (non-critical)', e);
    }
  }

  /// Background network refresh — updates cache silently
  Future<void> _refreshUserFromNetwork(String userId) async {
    try {
      final doc = await firestore.getUser(userId);
      if (doc.exists) {
        final user = UserModel.fromFirestore(doc);
        await _cacheUser(userId, user);
      }
    } catch (_) {
      // Non-critical background operation
    }
  }
}
