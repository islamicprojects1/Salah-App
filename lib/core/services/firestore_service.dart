import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../constants/api_constants.dart';

/// Service for Firestore database operations
class FirestoreService extends GetxService {
  // ============================================================
  // PRIVATE
  // ============================================================
  
  late final FirebaseFirestore _firestore;

  // ============================================================
  // INITIALIZATION
  // ============================================================
  
  /// Initialize the service
  Future<FirestoreService> init() async {
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
  Future<DocumentSnapshot<Map<String, dynamic>>> getGroup(String groupId) async {
    return await _groupsCollection.doc(groupId).get();
  }

  /// Get group stream
  Stream<DocumentSnapshot<Map<String, dynamic>>> getGroupStream(String groupId) {
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
  CollectionReference<Map<String, dynamic>> _prayerLogsCollection(String userId) =>
      _usersCollection
          .doc(userId)
          .collection(ApiConstants.prayerLogsCollection);

  /// Add prayer log
  Future<String> addPrayerLog(String userId, Map<String, dynamic> data) async {
    final doc = await _prayerLogsCollection(userId).add(data);
    return doc.id;
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
  Stream<QuerySnapshot<Map<String, dynamic>>> getTodayPrayerLogs(String userId) {
    return getPrayerLogsForDate(userId, DateTime.now());
  }

  /// Delete prayer log
  Future<void> deletePrayerLog(String userId, String logId) async {
    await _prayerLogsCollection(userId).doc(logId).delete();
  }

  // ============================================================
  // REACTIONS (Social interactions)
  // ============================================================
  
  /// Get reactions collection reference
  CollectionReference<Map<String, dynamic>> get _reactionsCollection =>
      _firestore.collection(ApiConstants.reactionsCollection);

  /// Send reaction (encouragement or reminder)
  Future<void> sendReaction({
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
  Stream<QuerySnapshot<Map<String, dynamic>>> getUnreadReactions(String userId) {
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
