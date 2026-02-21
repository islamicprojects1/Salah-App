import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:get/get.dart';
import 'package:salah/core/helpers/date_time_helper.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// DATABASE HELPER
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// ✅ ضروري — قاعدة البيانات المحلية (SQLite) للتطبيق.
//
// الجداول:
//   • prayer_logs          → سجلات الصلاة (offline-first، تُرفَع لـ Firestore لاحقاً)
//   • sync_queue           → طابور المزامنة (عناصر بانتظار الإنترنت)
//   • cached_prayer_times  → مواقيت الصلاة المؤقتة (تُستخدَم offline، تُحذف بعد 7 أيام)
//   • cached_user_profile  → بيانات المستخدم المؤقتة
//   • cached_family        → بيانات العائلة المؤقتة
//   • achievements         → تعريفات الإنجازات
//   • user_achievements    → تقدم المستخدم في الإنجازات
//   • challenges           → التحديات المتاحة
//   • pending_notifications → إشعارات بانتظار الإرسال
//
// الفرق بين DatabaseHelper و StorageService:
//   DatabaseHelper  → سجلات وقوائم كبيرة تحتاج SQL queries وindices
//   StorageService  → إعدادات وبيانات صغيرة (key-value)
//
// الاستخدام:
//   final db = sl<DatabaseHelper>();
//   await db.insertPrayerLog({...});
//   final logs = await db.getTodayPrayerLogs(userId);
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class DatabaseHelper extends GetxService {
  static const String _dbName = 'qurb.db';

  // عند تغيير هيكل أي جدول → ارفع الرقم وأضف migration في _onUpgrade
  static const int _dbVersion = 2;

  Database? _db;
  bool _isInitialized = false;

  // ══════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ══════════════════════════════════════════════════════════════

  Future<DatabaseHelper> init() async {
    if (_isInitialized) return this;
    _isInitialized = true;
    _db = await _openDatabase();
    await _ensureTablesExist();
    return this;
  }

  Future<Database> _openDatabase() async {
    final path = join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Database get database {
    assert(_db != null, 'DatabaseHelper not initialized. Call init() first.');
    return _db!;
  }

  // ══════════════════════════════════════════════════════════════
  // SCHEMA
  // ══════════════════════════════════════════════════════════════

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE prayer_logs (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id     TEXT,
        user_id       TEXT NOT NULL,
        prayer        TEXT NOT NULL,
        prayed_at     TEXT NOT NULL,
        adhan_time    TEXT NOT NULL,
        quality       TEXT,
        timing_quality TEXT,
        note          TEXT,
        is_synced     INTEGER DEFAULT 0,
        created_at    TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at    TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_queue (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        type         TEXT NOT NULL,
        data         TEXT NOT NULL,
        retry_count  INTEGER DEFAULT 0,
        created_at   TEXT DEFAULT CURRENT_TIMESTAMP,
        last_attempt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE cached_prayer_times (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        date      TEXT NOT NULL UNIQUE,
        fajr      TEXT,
        sunrise   TEXT,
        dhuhr     TEXT,
        asr       TEXT,
        maghrib   TEXT,
        isha      TEXT,
        latitude  REAL,
        longitude REAL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE cached_user_profile (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id    TEXT NOT NULL UNIQUE,
        data       TEXT NOT NULL,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE achievements (
        id              TEXT PRIMARY KEY,
        title           TEXT NOT NULL,
        description     TEXT,
        icon            TEXT,
        category        TEXT,
        max_tier        INTEGER DEFAULT 1,
        tier_thresholds TEXT,
        reward_points   INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE user_achievements (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id          TEXT NOT NULL,
        achievement_id   TEXT NOT NULL,
        current_progress INTEGER DEFAULT 0,
        current_tier     INTEGER DEFAULT 0,
        is_unlocked      INTEGER DEFAULT 0,
        unlocked_at      TEXT,
        UNIQUE(user_id, achievement_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE challenges (
        id             TEXT PRIMARY KEY,
        title          TEXT NOT NULL,
        description    TEXT,
        type           TEXT,
        target_value   INTEGER,
        start_date     TEXT,
        end_date       TEXT,
        reward_points  INTEGER DEFAULT 0,
        is_active      INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE pending_notifications (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        type         TEXT NOT NULL,
        title        TEXT NOT NULL,
        body         TEXT,
        scheduled_at TEXT,
        payload      TEXT,
        is_sent      INTEGER DEFAULT 0
      )
    ''');

    await _createFamilyTable(db);
    await _createIndices(db);
  }

  Future<void> _createFamilyTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cached_family (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id     TEXT NOT NULL UNIQUE,
        family_id   TEXT NOT NULL,
        family_data TEXT NOT NULL,
        updated_at  TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future<void> _createIndices(Database db) async {
    await db.execute(
      'CREATE INDEX idx_prayer_logs_user   ON prayer_logs(user_id)',
    );
    await db.execute(
      'CREATE INDEX idx_prayer_logs_date   ON prayer_logs(prayed_at)',
    );
    await db.execute(
      'CREATE INDEX idx_prayer_logs_synced ON prayer_logs(is_synced)',
    );
    await db.execute('CREATE INDEX idx_sync_queue_type    ON sync_queue(type)');
    await db.execute(
      'CREATE INDEX idx_prayer_times_date  ON cached_prayer_times(date)',
    );
    await db.execute(
      'CREATE INDEX idx_cached_family_user ON cached_family(user_id)',
    );
  }

  // ── Migration ────────────────────────────────────────────────

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // v1 → v2: إضافة جدول cached_family
    if (oldVersion < 2) {
      await _createFamilyTable(db);
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_cached_family_user ON cached_family(user_id)',
      );
    }
    // v2 → v3 وما بعدها: أضف migrations هنا
  }

  /// ضمان وجود جميع الجداول (يعالج edge cases في الـ migration)
  Future<void> _ensureTablesExist() async {
    final rows = await database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='cached_family'",
    );
    if (rows.isEmpty) {
      await _createFamilyTable(database);
      await database.execute(
        'CREATE INDEX IF NOT EXISTS idx_cached_family_user ON cached_family(user_id)',
      );
    }
  }

  // ══════════════════════════════════════════════════════════════
  // PRAYER LOGS
  // ══════════════════════════════════════════════════════════════

  /// حفظ سجل صلاة محلياً (is_synced = 0 حتى يُرفَع لـ Firestore)
  Future<int> insertPrayerLog(Map<String, dynamic> log) async {
    return database.insert('prayer_logs', {
      'user_id': log['userId'],
      'prayer': log['prayer'],
      'prayed_at': log['prayedAt'],
      'adhan_time': log['adhanTime'],
      'quality': log['quality'],
      'timing_quality': log['timingQuality'],
      'note': log['note'],
      'is_synced': log['isSynced'] ?? 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// كل السجلات التي لم تُرفَع بعد (للمزامنة)
  Future<List<Map<String, dynamic>>> getUnsyncedPrayerLogs() async {
    return database.query(
      'prayer_logs',
      where: 'is_synced = ?',
      whereArgs: [0],
      orderBy: 'created_at ASC',
    );
  }

  /// تحديد السجل كـ "مُزامَن" بعد الرفع لـ Firestore
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

  /// سجلات صلاة لفترة زمنية محددة
  Future<List<Map<String, dynamic>>> getPrayerLogs({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return database.query(
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

  /// سجلات صلاة اليوم الحالي
  Future<List<Map<String, dynamic>>> getTodayPrayerLogs(String userId) async {
    final now = DateTime.now();
    return getPrayerLogs(
      userId: userId,
      startDate: DateTime(now.year, now.month, now.day),
      endDate: DateTime(now.year, now.month, now.day + 1),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // SYNC QUEUE
  // ══════════════════════════════════════════════════════════════

  Future<int> addToSyncQueue(String type, String data) async {
    return database.insert('sync_queue', {
      'type': type,
      'data': data,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getSyncQueue() async {
    return database.query('sync_queue', orderBy: 'created_at ASC');
  }

  Future<void> removeFromSyncQueue(int id) async {
    await database.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateSyncRetryCount(int id) async {
    await database.rawUpdate(
      'UPDATE sync_queue SET retry_count = retry_count + 1, last_attempt = ? WHERE id = ?',
      [DateTime.now().toIso8601String(), id],
    );
  }

  Future<void> clearSyncQueue() async => database.delete('sync_queue');

  Future<int> getSyncQueueCount() async {
    final result = await database.rawQuery(
      'SELECT COUNT(*) as count FROM sync_queue',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ══════════════════════════════════════════════════════════════
  // PRAYER TIMES CACHE
  // ══════════════════════════════════════════════════════════════

  Future<void> cachePrayerTimes({
    required DateTime date,
    required Map<String, String> prayerTimes,
    double? latitude,
    double? longitude,
  }) async {
    await database.insert('cached_prayer_times', {
      'date': DateTimeHelper.toDateKey(date),
      'fajr': prayerTimes['fajr'],
      'sunrise': prayerTimes['sunrise'],
      'dhuhr': prayerTimes['dhuhr'],
      'asr': prayerTimes['asr'],
      'maghrib': prayerTimes['maghrib'],
      'isha': prayerTimes['isha'],
      'latitude': latitude,
      'longitude': longitude,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Cache prayer times for multiple days (e.g. full month from Aladhan).
  Future<void> cachePrayerTimesBatch({
    required Map<String, Map<String, String>> days,
    required double latitude,
    required double longitude,
  }) async {
    await database.transaction((txn) async {
      for (final entry in days.entries) {
        final pt = entry.value;
        await txn.insert('cached_prayer_times', {
          'date': entry.key,
          'fajr': pt['fajr'],
          'sunrise': pt['sunrise'],
          'dhuhr': pt['dhuhr'],
          'asr': pt['asr'],
          'maghrib': pt['maghrib'],
          'isha': pt['isha'],
          'latitude': latitude,
          'longitude': longitude,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<Map<String, dynamic>?> getCachedPrayerTimes(DateTime date) async {
    final rows = await database.query(
      'cached_prayer_times',
      where: 'date = ?',
      whereArgs: [DateTimeHelper.toDateKey(date)],
      limit: 1,
    );
    return rows.isNotEmpty ? rows.first : null;
  }

  /// حذف مواقيت أقدم من 60 يومًا (يدعم كاش الشهر + الجلب المسبق للشهر التالي)
  Future<void> cleanOldPrayerTimesCache() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 60));
    await database.delete(
      'cached_prayer_times',
      where: 'date < ?',
      whereArgs: [DateTimeHelper.toDateKey(cutoff)],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // USER PROFILE CACHE
  // ══════════════════════════════════════════════════════════════

  Future<void> cacheUserProfile(String userId, String data) async {
    await database.insert('cached_user_profile', {
      'user_id': userId,
      'data': data,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getCachedUserProfile(String userId) async {
    final rows = await database.query(
      'cached_user_profile',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    return rows.isNotEmpty ? rows.first['data'] as String : null;
  }

  // ══════════════════════════════════════════════════════════════
  // ACHIEVEMENTS
  // ══════════════════════════════════════════════════════════════

  Future<void> insertAchievement(Map<String, dynamic> data) async {
    await database.insert(
      'achievements',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAchievements() async {
    return database.query('achievements');
  }

  Future<void> insertUserAchievement(Map<String, dynamic> data) async {
    await database.insert(
      'user_achievements',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getUserAchievements(String userId) async {
    return database.query(
      'user_achievements',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<Map<String, dynamic>?> getUserAchievement(
    String userId,
    String achievementId,
  ) async {
    final rows = await database.query(
      'user_achievements',
      where: 'user_id = ? AND achievement_id = ?',
      whereArgs: [userId, achievementId],
      limit: 1,
    );
    return rows.isNotEmpty ? rows.first : null;
  }

  // ══════════════════════════════════════════════════════════════
  // FAMILY CACHE
  // ══════════════════════════════════════════════════════════════

  Future<String?> getCachedFamilyId(String userId) async {
    final rows = await database.query(
      'cached_family',
      columns: ['family_id'],
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    return rows.isNotEmpty ? rows.first['family_id'] as String? : null;
  }

  Future<String?> getCachedFamily(String familyId) async {
    final rows = await database.query(
      'cached_family',
      columns: ['family_data'],
      where: 'family_id = ?',
      whereArgs: [familyId],
      limit: 1,
    );
    return rows.isNotEmpty ? rows.first['family_data'] as String? : null;
  }

  Future<void> cacheFamilyId(String userId, String familyId) async {
    await database.insert('cached_family', {
      'user_id': userId,
      'family_id': familyId,
      'family_data': '{}',
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

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

  Future<void> clearFamilyCache(String userId) async {
    await database.delete(
      'cached_family',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // CLEANUP & STATS
  // ══════════════════════════════════════════════════════════════

  /// مسح جميع البيانات عند تسجيل الخروج
  Future<void> clearAllData() async {
    await Future.wait([
      database.delete('prayer_logs'),
      database.delete('sync_queue'),
      database.delete('cached_prayer_times'),
      database.delete('cached_user_profile'),
      database.delete('user_achievements'),
      database.delete('cached_family'),
    ]);
  }

  /// إحصائيات سريعة (للتشخيص أو شاشة About)
  Future<Map<String, int>> getDatabaseStats() async {
    final results = await Future.wait([
      database.rawQuery('SELECT COUNT(*) FROM prayer_logs'),
      database.rawQuery('SELECT COUNT(*) FROM sync_queue'),
      database.rawQuery('SELECT COUNT(*) FROM cached_prayer_times'),
    ]);
    return {
      'prayerLogs': Sqflite.firstIntValue(results[0]) ?? 0,
      'syncQueue': Sqflite.firstIntValue(results[1]) ?? 0,
      'cachedDays': Sqflite.firstIntValue(results[2]) ?? 0,
    };
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
