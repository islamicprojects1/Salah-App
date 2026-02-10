import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/services/connectivity_service.dart';
import 'package:salah/core/services/database_helper.dart';
import 'package:salah/data/models/achievement_model.dart';
import 'package:salah/data/repositories/base_repository.dart';
import 'package:salah/data/repositories/prayer_repository.dart';

class AchievementRepository extends BaseRepository {
  final DatabaseHelper _databaseHelper;
  final ConnectivityService _connectivity;
  final PrayerRepository _prayerRepository;

  AchievementRepository({
    required super.firestore,
    required DatabaseHelper database,
    required ConnectivityService connectivity,
    required PrayerRepository prayerRepository,
  }) : _databaseHelper = database,
       _connectivity = connectivity,
       _prayerRepository = prayerRepository;

  bool get _isOnline => _connectivity.isConnected.value;

  // ============================================================
  // ACHIEVEMENTS (DEFINITIONS)
  // ============================================================

  /// Get all achievements
  /// Tries local cache first, then syncs with remote
  Future<List<AchievementModel>> getAchievements() async {
    // 1. Get from local DB
    final localData = await _databaseHelper.getAchievements();
    final localAchievements = localData.map(_mapLocalToAchievement).toList();

    if (_isOnline) {
      try {
        final remoteSnapshots = await firestore.getAchievements();
        final remoteAchievements = remoteSnapshots
            .map((doc) => AchievementModel.fromFirestore(doc))
            .toList();
        await _cacheAchievements(remoteAchievements);
        return remoteAchievements;
      } catch (_) {
        return localAchievements;
      }
    }

    return localAchievements;
  }

  Future<void> _cacheAchievements(List<AchievementModel> achievements) async {
    for (final achievement in achievements) {
      await _databaseHelper.insertAchievement(
        _mapAchievementToLocal(achievement),
      );
    }
  }

  // ============================================================
  // USER PROGRESS
  // ============================================================

  /// Get user's achievements progress
  Future<List<UserAchievement>> getUserAchievements(String userId) async {
    // 1. Get from local DB
    final localData = await _databaseHelper.getUserAchievements(userId);
    final localProgress = localData.map(_mapLocalToUserAchievement).toList();

    if (_isOnline) {
      try {
        final remoteSnapshots = await firestore.getUserAchievements(userId);
        final remoteProgress = remoteSnapshots
            .map((doc) => UserAchievement.fromFirestore(doc))
            .toList();
        await _cacheUserAchievements(remoteProgress);
        return remoteProgress;
      } catch (_) {
        return localProgress;
      }
    }

    return localProgress;
  }

  Future<void> _cacheUserAchievements(
    List<UserAchievement> progressList,
  ) async {
    for (final progress in progressList) {
      await _databaseHelper.insertUserAchievement(
        _mapUserAchievementToLocal(progress),
      );
    }
  }

  /// Update user achievement progress
  Future<void> updateProgress({
    required String userId,
    required UserAchievement progress,
  }) async {
    try {
      // 1. Update local DB (Optimistic)
      await _databaseHelper.insertUserAchievement(
        _mapUserAchievementToLocal(progress),
      );

      // 2. Sync to Firestore
      final data = progress.toFirestore();

      if (_isOnline) {
        await firestore.updateUserAchievement(
          userId,
          progress.achievementId,
          data,
        );
      } else {
        await _prayerRepository.queueAchievementUpdate(
          userId: userId,
          achievementId: progress.achievementId,
          data: data,
        );
      }
    } catch (e) {
      if (e is FirebaseException) {
        await _prayerRepository.queueAchievementUpdate(
          userId: userId,
          achievementId: progress.achievementId,
          data: progress.toFirestore(),
        );
      } else {
        rethrow;
      }
    }
  }

  // ============================================================
  // MAPPERS
  // ============================================================

  AchievementModel _mapLocalToAchievement(Map<String, dynamic> map) {
    return AchievementModel(
      id: map['id'],
      title: map['title'],
      titleEn: '',
      description: map['description'] ?? '',
      descriptionEn: '',
      emoji: map['icon'] ?? '🏆',
      category: _parseCategory(map['category']),
      tierThresholds: _parseTierThresholdsJson(map['tier_thresholds']),
      createdAt: DateTime.now(),
      isActive: true,
    );
  }

  Map<String, dynamic> _mapAchievementToLocal(AchievementModel achievement) {
    return {
      'id': achievement.id,
      'title': achievement.title,
      'description': achievement.description,
      'icon': achievement.emoji,
      'category': achievement.category.name,
      'max_tier': 1,
      'tier_thresholds': jsonEncode(
        achievement.tierThresholds.map((k, v) => MapEntry(k.name, v)),
      ),
      'reward_points': 0,
    };
  }

  UserAchievement _mapLocalToUserAchievement(Map<String, dynamic> map) {
    return UserAchievement(
      id: '',
      achievementId: map['achievement_id'],
      userId: map['user_id'],
      currentTier: _parseTier(map['current_tier']),
      currentProgress: map['current_progress'] ?? 0,
      unlockedAt: map['unlocked_at'] != null
          ? DateTime.parse(map['unlocked_at'])
          : null,
      lastUpdated: null,
    );
  }

  Map<String, dynamic> _mapUserAchievementToLocal(UserAchievement progress) {
    return {
      'user_id': progress.userId,
      'achievement_id': progress.achievementId,
      'current_progress': progress.currentProgress,
      'current_tier': progress.currentTier.index,
      'is_unlocked': progress.isUnlocked ? 1 : 0,
      'unlocked_at': progress.unlockedAt?.toIso8601String(),
    };
  }

  AchievementCategory _parseCategory(String? category) {
    return AchievementCategory.values.firstWhere(
      (e) => e.name == category,
      orElse: () => AchievementCategory.special,
    );
  }

  Map<AchievementTier, int> _parseTierThresholdsJson(String? jsonStr) {
    if (jsonStr == null) return {};
    try {
      final Map<String, dynamic> map = jsonDecode(jsonStr);
      return map.map(
        (k, v) => MapEntry(
          AchievementTier.values.firstWhere(
            (e) => e.name == k,
            orElse: () => AchievementTier.bronze,
          ),
          v as int,
        ),
      );
    } catch (_) {
      return {};
    }
  }

  AchievementTier _parseTier(dynamic tier) {
    if (tier is int) {
      if (tier >= 0 && tier < AchievementTier.values.length) {
        return AchievementTier.values[tier];
      }
    }
    return AchievementTier.bronze;
  }
}
