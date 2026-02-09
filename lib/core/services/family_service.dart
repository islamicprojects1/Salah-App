import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'dart:math';
import 'package:salah/core/services/auth_service.dart';
import 'package:salah/core/services/database_helper.dart';
import 'package:salah/data/models/family_model.dart';
import 'package:salah/data/models/user_model.dart';
import 'package:salah/data/models/family_activity_model.dart';

/// Service for managing family groups
class FamilyService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = Get.find<AuthService>();
  late final DatabaseHelper _database;

  final Rxn<FamilyModel> currentFamily = Rxn<FamilyModel>();
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  /// Stream subscription for family updates - prevents memory leaks
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _familySubscription;

  @override
  void onInit() {
    super.onInit();
    _database = Get.find<DatabaseHelper>();

    // Check if user is already logged in
    if (_authService.currentUser.value != null) {
      _subscribeToFamily();
    }

    // Listen to auth changes to stream family data
    ever(_authService.currentUser, (user) {
      if (user != null) {
        _subscribeToFamily();
      } else {
        _familySubscription?.cancel();
        _familySubscription = null;
        currentFamily.value = null;
      }
    });
  }

  @override
  void onClose() {
    _familySubscription?.cancel();
    super.onClose();
  }

  /// Create a new family
  Future<bool> createFamily(String name) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final user = _authService.currentUser.value;
      if (user == null) throw Exception('يجب تسجيل الدخول أولاً');

      // Generate unique code
      final inviteCode = await _generateUniqueCode();

      final member = MemberModel(
        userId: user.uid,
        role: MemberRole.parent,
        joinedAt: DateTime.now(),
        name: user.displayName,
        photoUrl: user.photoURL,
      );

      final family = FamilyModel(
        id: '', // Will be set by Firestore
        name: name,
        inviteCode: inviteCode,
        adminId: user.uid,
        members: [member],
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      final ref = await _firestore
          .collection('families')
          .add(family.toFirestore());

      // Update user document with family ID for fast lookup
      await _firestore.collection('users').doc(user.uid).set({
        'familyId': ref.id,
      }, SetOptions(merge: true));

      // Update UI immediately so Family tab shows the new family (no empty state)
      final createdFamily = FamilyModel(
        id: ref.id,
        name: name,
        inviteCode: inviteCode,
        adminId: user.uid,
        members: [member],
        createdAt: family.createdAt,
      );
      currentFamily.value = createdFamily;
      _subscribeToFamily();

      return true;
    } catch (e) {
      errorMessage.value = 'حدث خطأ أثناء إنشاء العائلة: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Join an existing family
  Future<bool> joinFamily(String code) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final user = _authService.currentUser.value;
      if (user == null) throw Exception('يجب تسجيل الدخول أولاً');

      // Find family by code
      final query = await _firestore
          .collection('families')
          .where('inviteCode', isEqualTo: code.toUpperCase())
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        errorMessage.value = 'كود العائلة غير صحيح';
        return false;
      }

      final doc = query.docs.first;
      final family = FamilyModel.fromFirestore(doc);

      // Check if already a member
      if (family.members.any((m) => m.userId == user.uid)) {
        errorMessage.value = 'أنت عضو في هذه العائلة بالفعل';
        return false;
      }

      // Add member
      final member = MemberModel(
        userId: user.uid,
        role: MemberRole.child, // Default to child, can be changed by admin
        joinedAt: DateTime.now(),
        name: user.displayName,
        photoUrl: user.photoURL,
      );

      await _firestore.collection('families').doc(doc.id).update({
        'members': FieldValue.arrayUnion([member.toMap()]),
      });

      // Update user document with familyId
      await _firestore.collection('users').doc(user.uid).set({
        'familyId': doc.id,
      }, SetOptions(merge: true));

      // Update UI immediately so Family tab shows the family (no empty state)
      final updatedMembers = [...family.members, member];
      currentFamily.value = FamilyModel(
        id: family.id,
        name: family.name,
        inviteCode: family.inviteCode,
        adminId: family.adminId,
        members: updatedMembers,
        createdAt: family.createdAt,
      );
      _subscribeToFamily();

      return true;
    } catch (e) {
      errorMessage.value = 'حدث خطأ أثناء الانضمام: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Add a child without a phone (Shadow account)
  Future<bool> addChildWithoutPhone({
    required String name,
    required DateTime birthDate,
    required Gender gender,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final family = currentFamily.value;
      if (family == null) throw Exception('يجب أن تكون في عائلة أولاً');

      // Generate a mock ID
      final shadowId = 'shadow_${DateTime.now().millisecondsSinceEpoch}';

      final member = MemberModel(
        userId: shadowId,
        role: MemberRole.child,
        joinedAt: DateTime.now(),
        name: name,
        // photoUrl is null for now
      );

      await _firestore.collection('families').doc(family.id).update({
        'members': FieldValue.arrayUnion([member.toMap()]),
      });

      // Also create a shadow user document to store their data/prayers
      await _firestore.collection('users').doc(shadowId).set({
        'name': name,
        'birthDate': Timestamp.fromDate(birthDate),
        'gender': gender.name,
        'familyId': family.id,
        'isShadow': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      errorMessage.value = 'فشل إضافة الطفل: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Log prayer for a child (Parent permission)
  Future<bool> logPrayerForMember({
    required String memberId,
    required String prayerName,
    required DateTime prayerTime,
  }) async {
    try {
      // Logic would be similar to regular log, but using memberId
      // Ensure the current user is a parent in the same family
      final user = _authService.currentUser.value;
      final family = currentFamily.value;
      if (user == null || family == null) return false;

      final me = family.getMember(user.uid);
      if (me?.role != MemberRole.parent) {
        errorMessage.value = 'الوالدين فقط يمكنهم التسجيل للأبناء';
        return false;
      }

      // Add log to the member's collection (oderId = owner of the log)
      await _firestore
          .collection('users')
          .doc(memberId)
          .collection('prayer_logs')
          .add({
            'oderId': memberId,
            'prayer': prayerName,
            'prayedAt': FieldValue.serverTimestamp(),
            'adhanTime': Timestamp.fromDate(prayerTime),
            'addedByLeaderId': user.uid,
            'quality': 'onTime',
          });

      return true;
    } catch (e) {
      errorMessage.value = 'فشل تسجيل الصلاة: $e';
      return false;
    }
  }

  /// Send encouragement to a member
  Future<bool> sendEncouragement(String memberId, String message) async {
    try {
      final user = _authService.currentUser.value;
      if (user == null) return false;

      // In a real app, this would send an FCM.
      // For now, we'll store a "reaction" in Firestore that the other user listens to.
      await _firestore
          .collection('users')
          .doc(memberId)
          .collection('notifications')
          .add({
            'fromId': user.uid,
            'fromName': user.displayName,
            'message': message,
            'type': 'encouragement',
            'createdAt': FieldValue.serverTimestamp(),
            'isRead': false,
          });

      return true;
    } catch (e) {
      // Encouragement send failed
      return false;
    }
  }

  /// Get today's logs for a specific member
  Stream<QuerySnapshot<Map<String, dynamic>>> getMemberTodayLogs(
    String userId,
  ) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('prayer_logs')
        .where('prayedAt', isGreaterThanOrEqualTo: startOfDay)
        .snapshots();
  }

  /// Get member user data (for streaks, etc)
  Stream<DocumentSnapshot<Map<String, dynamic>>> getMemberData(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }

  /// Call when Family tab is shown so family loads even if auth restored late.
  void refreshFamily() {
    if (_authService.currentUser.value != null) _subscribeToFamily();
  }

  /// Subscribe to family updates with cache-first approach
  void _subscribeToFamily() async {
    final user = _authService.currentUser.value;
    if (user == null) return;

    // Cancel existing subscription to prevent duplicates
    _familySubscription?.cancel();

    // 1. Try loading from local cache first (instant display)
    final cachedFamilyId = await _database.getCachedFamilyId(user.uid);
    if (cachedFamilyId != null) {
      final cachedFamily = await _database.getCachedFamily(cachedFamilyId);
      if (cachedFamily != null) {
        try {
          final familyData = jsonDecode(cachedFamily) as Map<String, dynamic>;
          currentFamily.value = FamilyModel.fromMap(familyData, cachedFamilyId);
        } catch (_) {
          // Cache parsing failed, will load from network
        }
      }
    }

    // 2. Fetch familyId from Firestore (for live updates)
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      var familyId = userDoc.data()?['familyId'] as String?;

      // Auto-Repair: If familyId is missing but we have a valid cached one, verify and restore it
      if (familyId == null && cachedFamilyId != null) {
        try {
          final familyCheck = await _firestore.collection('families').doc(cachedFamilyId).get();
          if (familyCheck.exists) {
            final familyData = FamilyModel.fromFirestore(familyCheck);
            if (familyData.members.any((m) => m.userId == user.uid)) {
              debugPrint('FamilyService: Auto-repairing missing familyId for user ${user.uid}');
              await _firestore.collection('users').doc(user.uid).set({
                'familyId': cachedFamilyId,
              }, SetOptions(merge: true));
              familyId = cachedFamilyId;
            }
          }
        } catch (e) {
          debugPrint('FamilyService: Auto-repair check failed: $e');
        }
      }

      if (familyId != null) {
        // Cache the familyId for next startup
        await _database.cacheFamilyId(user.uid, familyId);

        // Subscribe to live updates
        _familySubscription = _firestore
            .collection('families')
            .doc(familyId)
            .snapshots()
            .listen((doc) async {
              if (doc.exists) {
                final family = FamilyModel.fromFirestore(doc);
                currentFamily.value = family;
                // Update local cache for offline access
                await _database.cacheFamily(
                  familyId!,
                  jsonEncode(family.toJsonCache()),
                );
              } else {
                currentFamily.value = null;
                await _database.clearFamilyCache(user.uid);
              }
            });
      } else {
        // User has no family
        currentFamily.value = null;
        await _database.clearFamilyCache(user.uid);
      }
    } catch (e) {
      // Network error - cache was already loaded above (if available)
      debugPrint('FamilyService: Network error, using cached data: $e');
    }
  }

  /// Generate 6-char unique code
  Future<String> _generateUniqueCode() async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();

    while (true) {
      final code = String.fromCharCodes(
        Iterable.generate(
          6,
          (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
        ),
      );

      // Check uniqueness
      final query = await _firestore
          .collection('families')
          .where('inviteCode', isEqualTo: code)
          .count()
          .get();

      if (query.count == 0) return code;
    }
  }

  /// Create a new activity in the family feed
  Future<void> createActivity({
    required String familyId,
    required ActivityType type,
    required String userId,
    required String userName,
    String? userPhoto,
    required Map<String, dynamic> data,
  }) async {
    try {
      if (familyId.isEmpty) return;

      final activity = {
        'type': type.name,
        'userId': userId,
        'userName': userName,
        'userPhoto': userPhoto,
        'timestamp': FieldValue.serverTimestamp(),
        'data': data,
      };

      await _firestore
          .collection('families')
          .doc(familyId)
          .collection('activities')
          .add(activity);
    } catch (e) {
      debugPrint('FamilyService: Failed to create activity: $e');
    }
  }

  /// Stream activities for the family feed
  Stream<List<FamilyActivityModel>> streamFamilyActivities(String familyId) {
    if (familyId.isEmpty) return Stream.value([]);

    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('activities')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        Timestamp? timestamp = data['timestamp'] as Timestamp?;
        // Handle server timestamp pending write
        if (timestamp == null) {
            timestamp = Timestamp.now();
        }
        
        return FamilyActivityModel(
            id: doc.id,
            type: ActivityType.values.firstWhere(
                (e) => e.name == data['type'],
                orElse: () => ActivityType.prayerLog,
            ),
            userId: data['userId'] ?? '',
            userName: data['userName'] ?? 'Unknown',
            userPhoto: data['userPhoto'],
            timestamp: timestamp.toDate(),
            data: data['data'] as Map<String, dynamic>? ?? {},
        );
      }).toList();
    });
  }
}
