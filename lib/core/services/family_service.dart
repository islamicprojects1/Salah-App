import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'dart:math';
import 'package:salah/core/services/auth_service.dart';
import 'package:salah/data/models/family_model.dart';
import 'package:salah/data/models/user_model.dart';

/// Service for managing family groups
class FamilyService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = Get.find<AuthService>();

  final Rxn<FamilyModel> currentFamily = Rxn<FamilyModel>();
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Listen to auth changes to stream family data
    ever(_authService.currentUser, (user) {
      if (user != null) {
        _subscribeToFamily();
      } else {
        currentFamily.value = null;
      }
    });
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
      final ref = await _firestore.collection('families').add(family.toFirestore());
      
      // Update user document with family ID (optional but recommended for fast lookup)
      await _firestore.collection('users').doc(user.uid).set({
        'familyId': ref.id,
      }, SetOptions(merge: true));

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

      // Update user document
      await _firestore.collection('users').doc(user.uid).set({
        'familyId': doc.id,
      }, SetOptions(merge: true));

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

      // Add log to the member's collection
      await _firestore
          .collection('users')
          .doc(memberId)
          .collection('prayer_logs')
          .add({
        'prayer': prayerName,
        'prayedAt': FieldValue.serverTimestamp(),
        'adhanTime': Timestamp.fromDate(prayerTime),
        'addedByLeaderId': user.uid,
        'quality': 'onTime', // Default if parent logs
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
      await _firestore.collection('users').doc(memberId).collection('notifications').add({
        'fromId': user.uid,
        'fromName': user.displayName,
        'message': message,
        'type': 'encouragement',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error sending encouragement: $e');
      return false;
    }
  }

  /// Get today's logs for a specific member
  Stream<QuerySnapshot<Map<String, dynamic>>> getMemberTodayLogs(String userId) {
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

  /// Subscribe to family updates
  void _subscribeToFamily() async {
    final user = _authService.currentUser.value;
    if (user == null) return;

    // Get family ID from user doc first
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final familyId = userDoc.data()?['familyId'];

    if (familyId != null) {
      _firestore.collection('families').doc(familyId).snapshots().listen((doc) {
        if (doc.exists) {
          currentFamily.value = FamilyModel.fromFirestore(doc);
        } else {
          currentFamily.value = null;
        }
      });
    }
  }

  /// Generate 6-char unique code
  Future<String> _generateUniqueCode() async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    
    while (true) {
      final code = String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
      ));

      // Check uniqueness
      final query = await _firestore
          .collection('families')
          .where('inviteCode', isEqualTo: code)
          .count()
          .get();
      
      if (query.count == 0) return code;
    }
  }
}
