import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:salah/core/services/database_helper.dart';
import 'package:salah/core/services/connectivity_service.dart';
import 'package:salah/core/di/injection_container.dart';
import 'package:salah/features/family/data/models/group_model.dart';
import 'package:salah/features/family/data/models/member_model.dart';
import 'package:salah/features/family/data/models/family_summary_model.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// FAMILY REPOSITORY
// المسار: lib/features/family/data/repositories/family_repository.dart
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class FamilyRepository {
  static const String _groupsCol = 'groups';
  static const String _membersCol = 'members';
  static const String _dailyCol = 'daily';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final DatabaseHelper _db;
  late final ConnectivityService _connectivity;

  FamilyRepository() {
    _db = sl<DatabaseHelper>();
    _connectivity = sl<ConnectivityService>();
  }

  String? get _userId => _auth.currentUser?.uid;
  String get _displayName =>
      _auth.currentUser?.displayName ??
      _auth.currentUser?.email ??
      _auth.currentUser?.uid ??
      '';

  // ══════════════════════════════════════════════════════════════
  // CODE GENERATION
  // ══════════════════════════════════════════════════════════════

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(8, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  Future<String> _uniqueCode() async {
    String code;
    int tries = 0;
    do {
      code = _generateCode();
      final snap = await _firestore
          .collection(_groupsCol)
          .where('inviteCode', isEqualTo: code)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) break;
      tries++;
    } while (tries < 5);
    return code;
  }

  // ══════════════════════════════════════════════════════════════
  // CREATE GROUP
  // ══════════════════════════════════════════════════════════════

  Future<GroupModel?> createGroup({
    required GroupType type,
    required String name,
  }) async {
    final uid = _userId;
    if (uid == null) return null;

    try {
      final code = await _uniqueCode();
      final now = DateTime.now();
      final groupRef = _firestore.collection(_groupsCol).doc();

      final group = GroupModel(
        groupId: groupRef.id,
        name: name.trim(),
        type: type,
        inviteCode: code,
        inviteCodeExpiresAt: now.add(const Duration(days: 30)),
        createdAt: now,
        createdBy: uid,
        adminId: uid,
        lastAdminActivity: now,
        blockedUserIds: [],
        memberIds: [uid],
        memberCount: 1,
      );

      final member = MemberModel(
        userId: uid,
        role: 'admin',
        displayName: _displayName,
        joinedAt: now,
      );

      final batch = _firestore.batch();
      batch.set(groupRef, group.toMap());
      batch.set(groupRef.collection(_membersCol).doc(uid), member.toMap());
      await batch.commit();

      await _db.cacheFamilyId(uid, groupRef.id);
      await _db.cacheFamily(groupRef.id, jsonEncode(group.toJson()));
      return group;
    } catch (e) {
      Get.log('[FamilyRepo] createGroup: $e', isError: true);
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // JOIN GROUP
  // ══════════════════════════════════════════════════════════════

  /// يرجع: 'success' | 'already_member' | 'not_found' | 'blocked' | 'error'
  Future<String> joinByCode(String code) async {
    final uid = _userId;
    if (uid == null) return 'error';

    try {
      final snap = await _firestore
          .collection(_groupsCol)
          .where('inviteCode', isEqualTo: code.trim().toUpperCase())
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return 'not_found';

      final doc = snap.docs.first;
      final group = GroupModel.fromMap(doc.data(), doc.id);

      if (group.isInviteCodeExpired) return 'expired';
      if (group.blockedUserIds.contains(uid)) return 'blocked';

      // Idempotency check
      final existing = await doc.reference
          .collection(_membersCol)
          .doc(uid)
          .get();
      if (existing.exists) {
        final m = MemberModel.fromMap(existing.data()!, uid);
        if (m.isActive) return 'already_member';
      }

      final member = MemberModel(
        userId: uid,
        role: 'member',
        displayName: _displayName,
        joinedAt: DateTime.now(),
      );

      final batch = _firestore.batch();
      batch.set(
        doc.reference.collection(_membersCol).doc(uid),
        member.toMap(),
        SetOptions(merge: true),
      );
      batch.update(doc.reference, {
        'memberCount': FieldValue.increment(1),
        'memberIds': FieldValue.arrayUnion([uid]),
      });
      await batch.commit();

      await _db.cacheFamilyId(uid, group.groupId);
      await _db.cacheFamily(group.groupId, jsonEncode(group.toJson()));
      return 'success';
    } catch (e) {
      Get.log('[FamilyRepo] joinByCode: $e', isError: true);
      return 'error';
    }
  }

  // ══════════════════════════════════════════════════════════════
  // FETCH / WATCH GROUP
  // ══════════════════════════════════════════════════════════════

  Future<GroupModel?> fetchMyGroup() async {
    final uid = _userId;
    if (uid == null) return null;

    // 1. محاولة الكاش المحلي
    final cachedId = await _db.getCachedFamilyId(uid);
    if (cachedId != null) {
      if (_connectivity.isConnected.value) {
        _refreshInBackground(cachedId);
      }
      final raw = await _db.getCachedFamily(cachedId);
      if (raw != null && raw != '{}') {
        try {
          return GroupModel.fromMap(
            jsonDecode(raw) as Map<String, dynamic>,
            cachedId,
          );
        } catch (_) {}
      }
    }

    // 2. جلب من Firestore مباشرة
    if (!_connectivity.isConnected.value) return null;
    return _fetchFromFirestore(uid);
  }

  Future<GroupModel?> _fetchFromFirestore(String uid) async {
    try {
      // نبحث عن مجموعة فيها عضوية نشطة لهذا المستخدم
      final memberDocs = await _firestore
          .collectionGroup(_membersCol)
          .where('userId', isEqualTo: uid)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (memberDocs.docs.isEmpty) return null;

      final groupId = memberDocs.docs.first.reference.parent.parent?.id;
      if (groupId == null) return null;

      final groupDoc = await _firestore
          .collection(_groupsCol)
          .doc(groupId)
          .get();
      if (!groupDoc.exists) return null;

      final group = GroupModel.fromMap(groupDoc.data()!, groupId);
      await _db.cacheFamilyId(uid, groupId);
      await _db.cacheFamily(groupId, jsonEncode(group.toJson()));
      return group;
    } catch (e) {
      Get.log('[FamilyRepo] fetchFromFirestore: $e', isError: true);
      return null;
    }
  }

  void _refreshInBackground(String groupId) async {
    try {
      final doc = await _firestore.collection(_groupsCol).doc(groupId).get();
      if (doc.exists) {
        await _db.cacheFamily(groupId, jsonEncode(doc.data()));
      }
    } catch (_) {}
  }

  Stream<GroupModel?> watchGroup(String groupId) {
    return _firestore
        .collection(_groupsCol)
        .doc(groupId)
        .snapshots()
        .map((s) => s.exists ? GroupModel.fromMap(s.data()!, s.id) : null);
  }

  // ══════════════════════════════════════════════════════════════
  // MEMBERS
  // ══════════════════════════════════════════════════════════════

  Stream<List<MemberModel>> watchMembers(String groupId) {
    return _firestore
        .collection(_groupsCol)
        .doc(groupId)
        .collection(_membersCol)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => MemberModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  Future<List<MemberModel>> fetchMembers(String groupId) async {
    try {
      final snap = await _firestore
          .collection(_groupsCol)
          .doc(groupId)
          .collection(_membersCol)
          .where('isActive', isEqualTo: true)
          .get();
      return snap.docs.map((d) => MemberModel.fromMap(d.data(), d.id)).toList();
    } catch (e) {
      Get.log('[FamilyRepo] fetchMembers: $e', isError: true);
      return [];
    }
  }

  // ══════════════════════════════════════════════════════════════
  // DAILY SUMMARY X/Y
  // ══════════════════════════════════════════════════════════════

  String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  Stream<FamilySummaryModel?> watchDailySummary(String groupId) {
    final key = _todayKey();
    return _firestore
        .collection(_groupsCol)
        .doc(groupId)
        .collection(_dailyCol)
        .doc(key)
        .snapshots()
        .map(
          (s) => s.exists
              ? FamilySummaryModel.fromMap(s.data()!, key)
              : FamilySummaryModel(date: key, prayedCount: 0, totalMembers: 0),
        );
  }

  /// يُستدعى بعد تسجيل أي صلاة من المستخدم
  /// [prayerName] اسم الصلاة (e.g. 'fajr') لعرض حالة الصلاة لكل عضو
  Future<void> onPrayerLogged(String groupId, String prayerName) async {
    final uid = _userId;
    if (uid == null) return;

    try {
      final today = _todayKey();

      // 1. تحديث حالة صلوات العضو في المجموعة (مرئي لجميع الأعضاء)
      final memberRef = _firestore
          .collection(_groupsCol)
          .doc(groupId)
          .collection(_membersCol)
          .doc(uid);

      await _firestore.runTransaction((txn) async {
        final snap = await txn.get(memberRef);
        final storedDate = snap.data()?['todayPrayersDate'] as String?;

        if (storedDate == today) {
          // نفس اليوم — أضف الصلاة إن لم تكن موجودة
          txn.update(memberRef, {
            'todayPrayers': FieldValue.arrayUnion([prayerName]),
          });
        } else {
          // يوم جديد — أعد الضبط
          txn.update(memberRef, {
            'todayPrayersDate': today,
            'todayPrayers': [prayerName],
          });
        }
      });

      // 2. تحديث الملخص اليومي للمجموعة (العضو يُحسب مرة واحدة فقط)
      final dailyRef = _firestore
          .collection(_groupsCol)
          .doc(groupId)
          .collection(_dailyCol)
          .doc(today);

      final loggedRef = dailyRef.collection('logged_today').doc(uid);
      final alreadyLogged = await loggedRef.get();
      if (alreadyLogged.exists) return;

      final groupDoc = await _firestore
          .collection(_groupsCol)
          .doc(groupId)
          .get();
      final total = (groupDoc.data()?['memberCount'] as num?)?.toInt() ?? 0;

      final batch = _firestore.batch();
      batch.set(dailyRef, {
        'prayedCount': FieldValue.increment(1),
        'totalMembers': total,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      batch.set(loggedRef, {'at': FieldValue.serverTimestamp()});
      await batch.commit();
    } catch (e) {
      Get.log('[FamilyRepo] onPrayerLogged: $e', isError: true);
    }
  }

  // ══════════════════════════════════════════════════════════════
  // REAL-TIME STATUS — prayingNow / waitingFor
  // ══════════════════════════════════════════════════════════════

  /// يُعيَّن عندما يبدأ المستخدم الصلاة (الضغط على زر "بدأت الصلاة")
  Future<void> setPrayingNow(String groupId, String prayerName) async {
    final uid = _userId;
    if (uid == null) return;
    try {
      await _firestore
          .collection(_groupsCol)
          .doc(groupId)
          .collection(_membersCol)
          .doc(uid)
          .update({
        'prayingNow': {
          'prayerName': prayerName,
          'startedAt': FieldValue.serverTimestamp(),
        },
        'waitingFor': null,
      });
    } catch (e) {
      Get.log('[FamilyRepo] setPrayingNow: $e', isError: true);
    }
  }

  /// يُمسَح بعد تسجيل الصلاة أو مرور 20 دقيقة (يُمسَح من الـ backend أيضاً)
  Future<void> clearPrayingNow(String groupId) async {
    final uid = _userId;
    if (uid == null) return;
    try {
      await _firestore
          .collection(_groupsCol)
          .doc(groupId)
          .collection(_membersCol)
          .doc(uid)
          .update({'prayingNow': null});
    } catch (e) {
      Get.log('[FamilyRepo] clearPrayingNow: $e', isError: true);
    }
  }

  /// يُعيَّن عندما يضغط المستخدم "أنا مستعد" — null يمسحه
  Future<void> setWaitingFor(String groupId, String? prayerName) async {
    final uid = _userId;
    if (uid == null) return;
    try {
      await _firestore
          .collection(_groupsCol)
          .doc(groupId)
          .collection(_membersCol)
          .doc(uid)
          .update({'waitingFor': prayerName});
    } catch (e) {
      Get.log('[FamilyRepo] setWaitingFor: $e', isError: true);
    }
  }

  // ══════════════════════════════════════════════════════════════
  // SHADOW MEMBERS
  // ══════════════════════════════════════════════════════════════

  Future<bool> addShadowMember({
    required String groupId,
    required String name,
    String? contactHint,
  }) async {
    if (name.trim().isEmpty) return false;
    try {
      // فحص تكرار الاسم
      final dup = await _firestore
          .collection(_groupsCol)
          .doc(groupId)
          .collection(_membersCol)
          .where('displayName', isEqualTo: name.trim())
          .where('isShadow', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      if (dup.docs.isNotEmpty) return false;

      final ref = _firestore
          .collection(_groupsCol)
          .doc(groupId)
          .collection(_membersCol)
          .doc();

      final member = MemberModel(
        userId: ref.id,
        role: 'member',
        displayName: name.trim(),
        joinedAt: DateTime.now(),
        isShadow: true,
        shadowContactHint: contactHint,
      );

      final batch = _firestore.batch();
      batch.set(ref, member.toMap());
      batch.update(_firestore.collection(_groupsCol).doc(groupId), {
        'memberCount': FieldValue.increment(1),
      });
      await batch.commit();
      return true;
    } catch (e) {
      Get.log('[FamilyRepo] addShadow: $e', isError: true);
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // ADMIN ACTIONS
  // ══════════════════════════════════════════════════════════════

  Future<bool> kickMember(String groupId, String targetId) async {
    try {
      final batch = _firestore.batch();
      final groupRef = _firestore.collection(_groupsCol).doc(groupId);
      batch.update(groupRef.collection(_membersCol).doc(targetId), {
        'isActive': false,
      });
      batch.update(groupRef, {
        'memberCount': FieldValue.increment(-1),
        'memberIds': FieldValue.arrayRemove([targetId]),
      });
      await batch.commit();
      return true;
    } catch (e) {
      Get.log('[FamilyRepo] kick: $e', isError: true);
      return false;
    }
  }

  Future<bool> kickAndBlock(String groupId, String targetId) async {
    try {
      final batch = _firestore.batch();
      final groupRef = _firestore.collection(_groupsCol).doc(groupId);
      batch.update(groupRef.collection(_membersCol).doc(targetId), {
        'isActive': false,
      });
      batch.update(groupRef, {
        'blockedUserIds': FieldValue.arrayUnion([targetId]),
        'memberCount': FieldValue.increment(-1),
        'memberIds': FieldValue.arrayRemove([targetId]),
      });
      await batch.commit();
      return true;
    } catch (e) {
      Get.log('[FamilyRepo] kickAndBlock: $e', isError: true);
      return false;
    }
  }

  Future<bool> unblockUser(String groupId, String targetId) async {
    try {
      await _firestore.collection(_groupsCol).doc(groupId).update({
        'blockedUserIds': FieldValue.arrayRemove([targetId]),
      });
      return true;
    } catch (e) {
      Get.log('[FamilyRepo] unblock: $e', isError: true);
      return false;
    }
  }

  Future<bool> transferAdmin(String groupId, String newAdminId) async {
    final uid = _userId;
    if (uid == null) return false;
    try {
      final batch = _firestore.batch();
      final groupRef = _firestore.collection(_groupsCol).doc(groupId);
      batch.update(groupRef.collection(_membersCol).doc(uid), {
        'role': 'member',
      });
      batch.update(groupRef.collection(_membersCol).doc(newAdminId), {
        'role': 'admin',
      });
      batch.update(groupRef, {
        'adminId': newAdminId,
        'lastAdminActivity': FieldValue.serverTimestamp(),
      });
      await batch.commit();
      return true;
    } catch (e) {
      Get.log('[FamilyRepo] transferAdmin: $e', isError: true);
      return false;
    }
  }

  Future<String?> renewInviteCode(String groupId) async {
    try {
      final code = await _uniqueCode();
      await _firestore.collection(_groupsCol).doc(groupId).update({
        'inviteCode': code,
        'inviteCodeExpiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 30)),
        ),
        'lastAdminActivity': FieldValue.serverTimestamp(),
      });
      return code;
    } catch (e) {
      Get.log('[FamilyRepo] renewCode: $e', isError: true);
      return null;
    }
  }

  Future<bool> leaveGroup(String groupId) async {
    final uid = _userId;
    if (uid == null) return false;
    try {
      final groupRef = _firestore.collection(_groupsCol).doc(groupId);

      // Check if the leaving user is admin before removing them
      final groupDoc = await groupRef.get();
      final isAdmin =
          groupDoc.exists && (groupDoc.data()?['adminId'] as String?) == uid;

      final batch = _firestore.batch();
      batch.update(groupRef.collection(_membersCol).doc(uid), {
        'isActive': false,
      });
      batch.update(groupRef, {
        'memberCount': FieldValue.increment(-1),
        'memberIds': FieldValue.arrayRemove([uid]),
      });
      await batch.commit();
      await _db.clearFamilyCache(uid);

      // Admin left — promote the next oldest active member automatically
      if (isAdmin) {
        await _autoSucceedAdmin(groupId, uid);
      }

      return true;
    } catch (e) {
      Get.log('[FamilyRepo] leave: $e', isError: true);
      return false;
    }
  }

  /// يُرقّي أقدم عضو نشط لمنصب المشرف عند غياب المشرف الحالي.
  Future<void> _autoSucceedAdmin(
    String groupId,
    String currentAdminId,
  ) async {
    try {
      final members = await _firestore
          .collection(_groupsCol)
          .doc(groupId)
          .collection(_membersCol)
          .where('isActive', isEqualTo: true)
          .where('isShadow', isEqualTo: false)
          .orderBy('joinedAt')
          .get();

      final candidates =
          members.docs.where((d) => d.id != currentAdminId).toList();
      if (candidates.isEmpty) return; // لا يوجد أعضاء آخرون

      final newAdminId = candidates.first.id;
      final batch = _firestore.batch();
      final groupRef = _firestore.collection(_groupsCol).doc(groupId);
      batch.update(groupRef.collection(_membersCol).doc(newAdminId), {
        'role': 'admin',
      });
      batch.update(groupRef, {
        'adminId': newAdminId,
        'lastAdminActivity': FieldValue.serverTimestamp(),
      });
      await batch.commit();
    } catch (e) {
      Get.log('[FamilyRepo] autoSucceed: $e', isError: true);
    }
  }

  Future<bool> dissolveGroup(String groupId) async {
    final uid = _userId;
    if (uid == null) return false;
    try {
      final members = await _firestore
          .collection(_groupsCol)
          .doc(groupId)
          .collection(_membersCol)
          .where('isActive', isEqualTo: true)
          .get();
      final batch = _firestore.batch();
      for (final m in members.docs) {
        batch.update(m.reference, {'isActive': false});
      }
      batch.delete(_firestore.collection(_groupsCol).doc(groupId));
      await batch.commit();
      await _db.clearFamilyCache(uid);
      return true;
    } catch (e) {
      Get.log('[FamilyRepo] dissolve: $e', isError: true);
      return false;
    }
  }

  Future<void> updateAdminActivity(String groupId) async {
    try {
      await _firestore.collection(_groupsCol).doc(groupId).update({
        'lastAdminActivity': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  // ══════════════════════════════════════════════════════════════
  // ADMIN SUCCESSION — 90 يوم عدم نشاط
  // ══════════════════════════════════════════════════════════════

  Future<void> checkSuccession(String groupId) async {
    try {
      final doc = await _firestore.collection(_groupsCol).doc(groupId).get();
      if (!doc.exists) return;

      final group = GroupModel.fromMap(doc.data()!, groupId);
      final last = group.lastAdminActivity;
      if (last == null) return;
      if (DateTime.now().difference(last).inDays < 90) return;

      await _autoSucceedAdmin(groupId, group.adminId);
    } catch (e) {
      Get.log('[FamilyRepo] succession: $e', isError: true);
    }
  }
}
