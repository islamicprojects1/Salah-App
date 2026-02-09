import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:get/get.dart';
import 'package:salah/core/helpers/date_time_helper.dart';

/// SQLite Database Helper
/// يدير قاعدة البيانات المحلية للتطبيق
class DatabaseHelper extends GetxService {
  static const String _databaseName = 'qurb.db';
  static const int _databaseVersion = 2;

  Database? _database;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  Future<DatabaseHelper> init() async {
    _database = await _initDatabase();
    // Ensure all tables exist (fix for migration edge cases)
    await _ensureTablesExist();
    return this;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Database get database {
    if (_database == null) {
      throw Exception('Database not initialized. Call init() first.');
    }
    return _database!;
  }

  // ============================================================
  // TABLE CREATION
  // ============================================================

  Future<void> _onCreate(Database db, int version) async {
    // Prayer logs table (offline cache)
    await db.execute('''
      CREATE TABLE prayer_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id TEXT,
        user_id TEXT NOT NULL,
        prayer TEXT NOT NULL,
        prayed_at TEXT NOT NULL,
        adhan_time TEXT NOT NULL,
        quality TEXT,
        timing_quality TEXT,
        note TEXT,
        is_synced INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Sync queue table
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        data TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        last_attempt TEXT
      )
    ''');

    // Cached prayer times table
    await db.execute('''
      CREATE TABLE cached_prayer_times (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        fajr TEXT,
        sunrise TEXT,
        dhuhr TEXT,
        asr TEXT,
        maghrib TEXT,
        isha TEXT,
        latitude REAL,
        longitude REAL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // User profile cache
    await db.execute('''
      CREATE TABLE cached_user_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL UNIQUE,
        data TEXT NOT NULL,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Achievements cache
    await db.execute('''
      CREATE TABLE achievements (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        icon TEXT,
        category TEXT,
        max_tier INTEGER DEFAULT 1,
        tier_thresholds TEXT,
        reward_points INTEGER DEFAULT 0
      )
    ''');

    // User achievements table
    await db.execute('''
      CREATE TABLE user_achievements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        achievement_id TEXT NOT NULL,
        current_progress INTEGER DEFAULT 0,
        current_tier INTEGER DEFAULT 0,
        is_unlocked INTEGER DEFAULT 0,
        unlocked_at TEXT,
        UNIQUE(user_id, achievement_id)
      )
    ''');

    // Challenges cache
    await db.execute('''
      CREATE TABLE challenges (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        type TEXT,
        target_value INTEGER,
        start_date TEXT,
        end_date TEXT,
        reward_points INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1
      )
    ''');

    // Offline notifications table
    await db.execute('''
      CREATE TABLE pending_notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        body TEXT,
        scheduled_at TEXT,
        payload TEXT,
        is_sent INTEGER DEFAULT 0
      )
    ''');

    // Cached family (user -> family_id) for offline/dashboard
    await db.execute('''
      CREATE TABLE cached_family (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL UNIQUE,
        family_id TEXT NOT NULL,
        family_data TEXT NOT NULL,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create indices for better query performance
    await db.execute('CREATE INDEX idx_prayer_logs_user ON prayer_logs(user_id)');
    await db.execute('CREATE INDEX idx_prayer_logs_date ON prayer_logs(prayed_at)');
    await db.execute('CREATE INDEX idx_prayer_logs_synced ON prayer_logs(is_synced)');
    await db.execute('CREATE INDEX idx_sync_queue_type ON sync_queue(type)');
    await db.execute('CREATE INDEX idx_cached_prayer_times_date ON cached_prayer_times(date)');
    await db.execute('CREATE INDEX idx_cached_family_user ON cached_family(user_id)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration: v1 -> v2: Add cached_family table
    if (oldVersion < 2) {
      // Create table if not exists
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cached_family (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id TEXT NOT NULL UNIQUE,
          family_id TEXT NOT NULL,
          family_data TEXT NOT NULL,
          updated_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');
      
      // Create index if not exists
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_cached_family_user ON cached_family(user_id)
      ''');
    }
  }

  /// Ensures all required tables exist (fixes migration edge cases)
  Future<void> _ensureTablesExist() async {
    final db = database;
    
    // Check if cached_family table exists, create if not
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='cached_family'"
    );
    
    if (tables.isEmpty) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cached_family (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id TEXT NOT NULL UNIQUE,
          family_id TEXT NOT NULL,
          family_data TEXT NOT NULL,
          updated_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');
      
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_cached_family_user ON cached_family(user_id)
      ''');
    }
  }

  // ============================================================
  // PRAYER LOGS OPERATIONS
  // ============================================================

  /// Insert a prayer log
  Future<int> insertPrayerLog(Map<String, dynamic> log) async {
    return await database.insert(
      'prayer_logs',
      {
        'user_id': log['userId'],
        'prayer': log['prayer'],
        'prayed_at': log['prayedAt'],
        'adhan_time': log['adhanTime'],
        'quality': log['quality'],
        'timing_quality': log['timingQuality'],
        'note': log['note'],
        'is_synced': log['isSynced'] ?? 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get unsynced prayer logs
  Future<List<Map<String, dynamic>>> getUnsyncedPrayerLogs() async {
    return await database.query(
      'prayer_logs',
      where: 'is_synced = ?',
      whereArgs: [0],
      orderBy: 'created_at ASC',
    );
  }

  /// Mark prayer log as synced
  Future<void> markPrayerLogSynced(int id, String serverId) async {
    await database.update(
      'prayer_logs',
      {
        'is_synced': 1,
        'server_id': serverId,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get prayer logs for a date range
  Future<List<Map<String, dynamic>>> getPrayerLogs({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await database.query(
      'prayer_logs',
      where: 'user_id = ? AND prayed_at >= ? AND prayed_at < ?',
      whereArgs: [
        userId,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'prayed_at DESC',
    );
  }

  /// Get today's prayer logs
  Future<List<Map<String, dynamic>>> getTodayPrayerLogs(String userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return await getPrayerLogs(
      userId: userId,
      startDate: startOfDay,
      endDate: endOfDay,
    );
  }

  // ============================================================
  // SYNC QUEUE OPERATIONS
  // ============================================================

  /// Add item to sync queue
  Future<int> addToSyncQueue(String type, String data) async {
    return await database.insert('sync_queue', {
      'type': type,
      'data': data,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get all items from sync queue
  Future<List<Map<String, dynamic>>> getSyncQueue() async {
    return await database.query(
      'sync_queue',
      orderBy: 'created_at ASC',
    );
  }

  /// Remove item from sync queue
  Future<void> removeFromSyncQueue(int id) async {
    await database.delete(
      'sync_queue',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Update retry count
  Future<void> updateSyncRetryCount(int id) async {
    await database.rawUpdate('''
      UPDATE sync_queue 
      SET retry_count = retry_count + 1, 
          last_attempt = ?
      WHERE id = ?
    ''', [DateTime.now().toIso8601String(), id]);
  }

  /// Clear sync queue
  Future<void> clearSyncQueue() async {
    await database.delete('sync_queue');
  }

  /// Get sync queue count
  Future<int> getSyncQueueCount() async {
    final result = await database.rawQuery(
      'SELECT COUNT(*) as count FROM sync_queue',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ============================================================
  // PRAYER TIMES CACHE
  // ============================================================

  /// Cache prayer times for a date
  Future<void> cachePrayerTimes({
    required DateTime date,
    required Map<String, String> prayerTimes,
    double? latitude,
    double? longitude,
  }) async {
    final dateStr = DateTimeHelper.toDateKey(date);
    await database.insert(
      'cached_prayer_times',
      {
        'date': dateStr,
        'fajr': prayerTimes['fajr'],
        'sunrise': prayerTimes['sunrise'],
        'dhuhr': prayerTimes['dhuhr'],
        'asr': prayerTimes['asr'],
        'maghrib': prayerTimes['maghrib'],
        'isha': prayerTimes['isha'],
        'latitude': latitude,
        'longitude': longitude,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get cached prayer times for a date
  Future<Map<String, dynamic>?> getCachedPrayerTimes(DateTime date) async {
    final dateStr = DateTimeHelper.toDateKey(date);
    final result = await database.query(
      'cached_prayer_times',
      where: 'date = ?',
      whereArgs: [dateStr],
      limit: 1,
    );
    
    return result.isNotEmpty ? result.first : null;
  }

  /// Clean old cached prayer times (older than 7 days)
  Future<void> cleanOldPrayerTimesCache() async {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final dateStr = DateTimeHelper.toDateKey(sevenDaysAgo);
    await database.delete(
      'cached_prayer_times',
      where: 'date < ?',
      whereArgs: [dateStr],
    );
  }

  // ============================================================
  // USER PROFILE CACHE
  // ============================================================

  /// Cache user profile
  Future<void> cacheUserProfile(String userId, String data) async {
    await database.insert(
      'cached_user_profile',
      {
        'user_id': userId,
        'data': data,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get cached user profile
  Future<String?> getCachedUserProfile(String userId) async {
    final result = await database.query(
      'cached_user_profile',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    
    return result.isNotEmpty ? result.first['data'] as String : null;
  }

  // ============================================================
  // ACHIEVEMENTS OPERATIONS
  // ============================================================

  /// Insert or update achievement definition
  Future<void> insertAchievement(Map<String, dynamic> achievement) async {
    await database.insert(
      'achievements',
      achievement,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all achievements
  Future<List<Map<String, dynamic>>> getAchievements() async {
    return await database.query('achievements');
  }

  /// Insert or update user achievement progress
  Future<void> insertUserAchievement(Map<String, dynamic> userAchievement) async {
    await database.insert(
      'user_achievements',
      userAchievement,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get user achievements
  Future<List<Map<String, dynamic>>> getUserAchievements(String userId) async {
    return await database.query(
      'user_achievements',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  /// Get specific user achievement
  Future<Map<String, dynamic>?> getUserAchievement(String userId, String achievementId) async {
    final results = await database.query(
      'user_achievements',
      where: 'user_id = ? AND achievement_id = ?',
      whereArgs: [userId, achievementId],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  // ============================================================
  // CLEANUP & UTILITIES
  // ============================================================

  /// Close database
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  /// Clear all data (for logout)
  Future<void> clearAllData() async {
    await database.delete('prayer_logs');
    await database.delete('sync_queue');
    await database.delete('cached_prayer_times');
    await database.delete('cached_user_profile');
    await database.delete('user_achievements');
  }

  /// Get database stats
  Future<Map<String, int>> getDatabaseStats() async {
    final prayerLogsCount = Sqflite.firstIntValue(
      await database.rawQuery('SELECT COUNT(*) FROM prayer_logs'),
    ) ?? 0;
    
    final syncQueueCount = Sqflite.firstIntValue(
      await database.rawQuery('SELECT COUNT(*) FROM sync_queue'),
    ) ?? 0;
    
    final cachedDaysCount = Sqflite.firstIntValue(
      await database.rawQuery('SELECT COUNT(*) FROM cached_prayer_times'),
    ) ?? 0;

    return {
      'prayerLogs': prayerLogsCount,
      'syncQueue': syncQueueCount,
      'cachedDays': cachedDaysCount,
    };
  }

  // ============================================================
  // FAMILY CACHE METHODS
  // ============================================================

  /// Get cached family ID for user
  Future<String?> getCachedFamilyId(String userId) async {
    final results = await database.query(
      'cached_family',
      columns: ['family_id'],
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (results.isNotEmpty) {
      return results.first['family_id'] as String?;
    }
    return null;
  }

  /// Get cached family data
  Future<String?> getCachedFamily(String familyId) async {
    final results = await database.query(
      'cached_family',
      columns: ['family_data'],
      where: 'family_id = ?',
      whereArgs: [familyId],
      limit: 1,
    );
    if (results.isNotEmpty) {
      return results.first['family_data'] as String?;
    }
    return null;
  }

  /// Cache family ID for user
  Future<void> cacheFamilyId(String userId, String familyId) async {
    await database.insert(
      'cached_family',
      {
        'user_id': userId,
        'family_id': familyId,
        'family_data': '{}',
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Cache family data
  Future<void> cacheFamily(String familyId, String familyData) async {
    await database.update(
      'cached_family',
      {
        'family_data': familyData,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'family_id = ?',
      whereArgs: [familyId],
    );
  }

  /// Clear family cache for user
  Future<void> clearFamilyCache(String userId) async {
    await database.delete(
      'cached_family',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
}

