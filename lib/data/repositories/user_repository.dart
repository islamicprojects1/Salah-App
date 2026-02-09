import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salah/core/services/connectivity_service.dart';
import 'package:salah/core/services/database_helper.dart';
import 'package:salah/core/services/firestore_service.dart';
import 'package:salah/data/models/user_model.dart';
import 'package:salah/data/repositories/base_repository.dart';
import 'package:salah/data/repositories/prayer_repository.dart';

/// Repository for user-related data operations.
/// Uses [ConnectivityService] for online check and [PrayerRepository] for offline queue.
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

  /// Create or update a user in Firestore
  Future<void> saveUser({
    required String userId,
    required UserModel user,
  }) async {
    try {
      await firestore.setUser(userId, user.toFirestore());
      await _cacheUser(userId, user);
    } catch (e) {
      if (!_isOnline) {
        await _prayerRepository.queueUserUpdate(user.toFirestore());
        await _cacheUser(userId, user);
      } else {
        throw Exception('Failed to save user: ${handleError(e)}');
      }
    }
  }

  /// Get a user by ID
  Future<UserModel?> getUser(String userId) async {
    final cachedJson = await _databaseHelper.getCachedUserProfile(userId);
    if (cachedJson != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(cachedJson);
        return UserModel.fromMap(data, userId);
      } catch (_) {
        // Fall through to network
      }
    }

    if (_isOnline) {
      try {
        final doc = await firestore.getUser(userId);
        if (doc.exists) {
          final user = UserModel.fromFirestore(doc);
          await _cacheUser(userId, user);
          return user;
        }
      } catch (_) {
        // Return null on network error
      }
    }

    // 3. Fallback to cache if network failed but we ignored it earlier (unlikely if logic above matches)
    // Actually if cache existed we returned it.
    // If cache failed parsing, we tried network.
    // If network failed, we return null.
    // This is correct behavior for now.

    return null;
  }

  /// Update user profile fields
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
    } catch (_) {
      await _prayerRepository.queueUserUpdate(updates);
    }
  }

  Future<void> _cacheUser(String userId, UserModel user) async {
    await _databaseHelper.cacheUserProfile(
      userId,
      jsonEncode(user.toFirestore()),
    );
  }

  /// Update user's streak (convenience method)
  Future<void> updateStreak({
    required String userId,
    required int newStreak,
  }) async {
    await updateUserProfile(
      userId: userId,
      updates: {'currentStreak': newStreak},
    );
  }

  /// Get user's current streak
  Future<int> getStreak(String userId) async {
    final user = await getUser(userId);
    if (user != null) return user.currentStreak;
    return 0;
  }

  /// Stream of user notifications (e.g. encouragements from family). Used by Dashboard for real-time pokes.
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

  /// Delete user account data
  Future<void> deleteUser(String userId) async {
    try {
      if (_isOnline) {
        await firestore.deleteUser(userId);
      }
      // Clear local cache regardless of online status
      await _databaseHelper.clearAllData();
    } catch (_) {
      // Best effort deletion
    }
  }
}
