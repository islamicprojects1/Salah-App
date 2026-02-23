import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/api_constants.dart';
import 'package:salah/features/prayer/data/models/prayer_log_model.dart';

/// Service for Firestore database operations
class FirestoreService extends GetxService {
  // ============================================================
  // PRIVATE
  // ============================================================

  late final FirebaseFirestore _firestore;

  bool _isInitialized = false;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  /// Initialize the service
  Future<FirestoreService> init() async {
    if (_isInitialized) return this;
    _isInitialized = true;
    _firestore = FirebaseFirestore.instance;

    // Enable offline persistence
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    return this;
  }

  // ============================================================
  // USERS
  // ============================================================

  /// Get users collection reference
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection(ApiConstants.usersCollection);

  /// Create or update user document
  Future<void> setUser(String userId, Map<String, dynamic> data) async {
    await _usersCollection.doc(userId).set(data, SetOptions(merge: true));
  }

  /// Get user document
  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String userId) async {
    return await _usersCollection.doc(userId).get();
  }

  /// Get user stream
  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStream(String userId) {
    return _usersCollection.doc(userId).snapshots();
  }

  /// Update user document
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _usersCollection.doc(userId).update(data);
  }

  /// Delete user document
  Future<void> deleteUser(String userId) async {
    await _usersCollection.doc(userId).delete();
  }

  /// Calculate and update user streak.
  ///
  /// "Prayer day" starts at 03:00 (not midnight) so that Isha prayed after
  /// midnight still belongs to the same prayer day as the preceding Fajr.
  Future<int> updateStreak(String userId) async {
    try {
      final now = DateTime.now();
      int streak = 0;

      // Anchor the prayer-day base: if it's before 3 AM, we're still in
      // yesterday's prayer day (Isha may not have been prayed yet).
      final prayerDayBase = _prayerDayStart(now);

      for (int i = 0; i < 30; i++) {
        final dayStart = prayerDayBase.subtract(Duration(days: i));
        final dayEnd = dayStart.add(const Duration(hours: 24));

        final snapshot = await _prayerLogsCollection(userId)
            .where('prayedAt', isGreaterThanOrEqualTo: dayStart)
            .where('prayedAt', isLessThan: dayEnd)
            .get();

        final completedPrayers = snapshot.docs
            .map((d) => d.data()['prayer'] as String)
            .toSet();
        // Remove non-obligatory sunrise / شروق
        completedPrayers.remove('sunrise');
        completedPrayers.remove('الشروق');

        if (completedPrayers.length >= 5) {
          streak++;
        } else if (i == 0) {
          // Current prayer day isn't finished yet — don't break the streak.
          continue;
        } else {
          break;
        }
      }

      await updateUser(userId, {'currentStreak': streak});
      return streak;
    } catch (e) {
      return 0;
    }
  }

  /// Returns the start of the current "prayer day" (03:00 AM boundary).
  /// Before 3 AM we're still in the previous day's prayer cycle.
  static DateTime _prayerDayStart(DateTime moment) {
    final cutoff = DateTime(moment.year, moment.month, moment.day, 3);
    if (moment.isBefore(cutoff)) {
      final prev = moment.subtract(const Duration(days: 1));
      return DateTime(prev.year, prev.month, prev.day, 3);
    }
    return cutoff;
  }

  /// Get real-time notifications for a user
  Stream<QuerySnapshot<Map<String, dynamic>>> getUserNotifications(
    String userId,
  ) {
    return _usersCollection
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getUnreadUserNotifications(
    String userId,
  ) {
    return _usersCollection
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots();
  }

  Future<void> markUserNotificationAsRead(
    String userId,
    String notificationId,
  ) async {
    await _usersCollection
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> addAnalyticsEvent({
    required String userId,
    required String event,
    Map<String, dynamic>? data,
  }) async {
    await _firestore.collection(ApiConstants.analyticsCollection).add({
      'userId': userId,
      'event': event,
      'data': data ?? {},
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // GROUPS
  // ============================================================

  /// Get groups collection reference
  CollectionReference<Map<String, dynamic>> get _groupsCollection =>
      _firestore.collection(ApiConstants.groupsCollection);

  /// Create group
  Future<String> createGroup(Map<String, dynamic> data) async {
    final doc = await _groupsCollection.add(data);
    return doc.id;
  }

  /// Get group document
  Future<DocumentSnapshot<Map<String, dynamic>>> getGroup(
    String groupId,
  ) async {
    return await _groupsCollection.doc(groupId).get();
  }

  /// Get group stream
  Stream<DocumentSnapshot<Map<String, dynamic>>> getGroupStream(
    String groupId,
  ) {
    return _groupsCollection.doc(groupId).snapshots();
  }

  /// Update group
  Future<void> updateGroup(String groupId, Map<String, dynamic> data) async {
    await _groupsCollection.doc(groupId).update(data);
  }

  /// Delete group
  Future<void> deleteGroup(String groupId) async {
    await _groupsCollection.doc(groupId).delete();
  }

  /// Get user's groups
  Stream<QuerySnapshot<Map<String, dynamic>>> getUserGroups(String userId) {
    return _groupsCollection
        .where('memberIds', arrayContains: userId)
        .snapshots();
  }

  // ============================================================
  // PRAYER LOGS
  // ============================================================

  /// Get prayer logs collection for a user
  CollectionReference<Map<String, dynamic>> _prayerLogsCollection(
    String userId,
  ) => _usersCollection
      .doc(userId)
      .collection(ApiConstants.prayerLogsCollection);

  /// Add prayer log (server-generated doc id).
  Future<String> addPrayerLog(String userId, Map<String, dynamic> data) async {
    final doc = await _prayerLogsCollection(userId).add(data);
    return doc.id;
  }

  /// Set prayer log with a fixed doc id (idempotent sync: same clientId overwrites).
  Future<void> setPrayerLog(
    String userId,
    String docId,
    Map<String, dynamic> data,
  ) async {
    await _prayerLogsCollection(userId).doc(docId).set(data);
  }

  /// Get prayer logs for a specific date
  Stream<QuerySnapshot<Map<String, dynamic>>> getPrayerLogsForDate(
    String userId,
    DateTime date,
  ) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _prayerLogsCollection(userId)
        .where('prayedAt', isGreaterThanOrEqualTo: startOfDay)
        .where('prayedAt', isLessThan: endOfDay)
        .snapshots();
  }

  /// Get today's prayer logs
  Stream<QuerySnapshot<Map<String, dynamic>>> getTodayPrayerLogs(
    String userId,
  ) {
    return getPrayerLogsForDate(userId, DateTime.now());
  }

  /// Delete prayer log
  Future<void> deletePrayerLog(String userId, String logId) async {
    await _prayerLogsCollection(userId).doc(logId).delete();
  }

  /// Get prayer logs for a specific date range
  Future<List<PrayerLogModel>> getPrayerLogs({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final snapshot = await _prayerLogsCollection(userId)
        .where('prayedAt', isGreaterThanOrEqualTo: startDate)
        .where('prayedAt', isLessThan: endDate)
        .get();

    return snapshot.docs
        .map((doc) => PrayerLogModel.fromFirestore(doc))
        .toList();
  }

  // ============================================================
  // REACTIONS (Social interactions)
  // ============================================================

  /// Get reactions collection reference
  CollectionReference<Map<String, dynamic>> get _reactionsCollection =>
      _firestore.collection(ApiConstants.reactionsCollection);

  /// Send reaction (encouragement or reminder)
  Future<void> addReaction({
    required String senderId,
    required String receiverId,
    required String type, // 'encouragement' or 'reminder'
    required String prayerName,
    String? message,
  }) async {
    await _reactionsCollection.add({
      'senderId': senderId,
      'receiverId': receiverId,
      'type': type,
      'prayerName': prayerName,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  /// Get user's unread reactions
  Stream<QuerySnapshot<Map<String, dynamic>>> getUnreadReactions(
    String userId,
  ) {
    return _reactionsCollection
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Mark reaction as read
  Future<void> markReactionAsRead(String reactionId) async {
    await _reactionsCollection.doc(reactionId).update({'isRead': true});
  }

  // ============================================================
  // BATCH OPERATIONS
  // ============================================================

  /// Get batch for multiple writes
  WriteBatch get batch => _firestore.batch();

  /// Commit batch
  Future<void> commitBatch(WriteBatch batch) async {
    await batch.commit();
  }

  // ============================================================
  // ACHIEVEMENTS
  // ============================================================

  /// Get achievements collection
  CollectionReference<Map<String, dynamic>> get _achievementsCollection =>
      _firestore.collection(ApiConstants.achievementsCollection);

  /// Get user achievements collection
  CollectionReference<Map<String, dynamic>> _userAchievementsCollection(
    String userId,
  ) => _usersCollection
      .doc(userId)
      .collection(ApiConstants.userAchievementsCollection);

  /// Get all achievements (definitions)
  Future<List<DocumentSnapshot<Map<String, dynamic>>>> getAchievements() async {
    final snapshot = await _achievementsCollection
        .where('isActive', isEqualTo: true)
        .get();
    return snapshot.docs;
  }

  /// Get user's achievements progress
  Future<List<DocumentSnapshot<Map<String, dynamic>>>> getUserAchievements(
    String userId,
  ) async {
    final snapshot = await _userAchievementsCollection(userId).get();
    return snapshot.docs;
  }

  /// Update user achievement
  Future<void> updateUserAchievement(
    String userId,
    String achievementId,
    Map<String, dynamic> data,
  ) async {
    await _userAchievementsCollection(
      userId,
    ).doc(achievementId).set(data, SetOptions(merge: true));
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  /// Convert Firestore timestamp to DateTime
  DateTime? timestampToDateTime(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    return null;
  }

  /// Convert DateTime to Firestore timestamp
  Timestamp dateTimeToTimestamp(DateTime dateTime) {
    return Timestamp.fromDate(dateTime);
  }
}
