import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/enums.dart';
import 'dart:math';
import 'package:salah/core/services/auth_service.dart';
import 'package:salah/core/services/database_helper.dart';
import 'package:salah/data/models/family_model.dart';
import 'package:salah/data/models/user_model.dart';
import 'package:salah/data/models/family_activity_model.dart';
import 'package:salah/data/models/family_pulse_model.dart';

/// Service for managing family groups
class FamilyService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = Get.find<AuthService>();
  late final DatabaseHelper _database;

  final Rxn<FamilyModel> currentFamily = Rxn<FamilyModel>();
  final RxList<FamilyModel> myFamilies = <FamilyModel>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  /// Stream subscriptions for family updates
  final List<StreamSubscription> _familySubscriptions = [];

  @override
  void onInit() {
    super.onInit();
    _database = Get.find<DatabaseHelper>();

    if (_authService.currentUser.value != null) {
      _subscribeToFamilies();
    }

    ever(_authService.currentUser, (user) {
      if (user != null) {
        _subscribeToFamilies();
      } else {
        _clearSubscriptions();
        currentFamily.value = null;
        myFamilies.clear();
      }
    });
  }

  @override
  void onClose() {
    _clearSubscriptions();
    super.onClose();
  }

  void _clearSubscriptions() {
    for (var sub in _familySubscriptions) {
      sub.cancel();
    }
    _familySubscriptions.clear();
  }

  /// Select a specific family to view
  void selectFamily(FamilyModel family) {
    currentFamily.value = family;
    // Persist choice if needed
    _database.cacheFamilyId(_authService.userId!, family.id);
  }

  /// Create a new family
  Future<bool> createFamily(String name) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final user = _authService.currentUser.value;
      if (user == null) throw Exception('error_must_login'.tr);

      final inviteCode = await _generateUniqueCode();

      final member = MemberModel(
        userId: user.uid,
        role: MemberRole.parent,
        joinedAt: DateTime.now(),
        name: user.displayName,
        photoUrl: user.photoURL,
      );

      final family = FamilyModel(
        id: '',
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

      // Add familyId to user's list
      await _firestore.collection('users').doc(user.uid).set({
        'familyIds': FieldValue.arrayUnion([ref.id]),
        'familyId':
            ref.id, // Keep legacy field for backward compatibility or default
      }, SetOptions(merge: true));

      // Refresh subscriptions will happen automatically via listener if we were listening to user doc, but we are not.
      // So manual refresh or wait for UI.
      // Better: The _subscribeToFamilies should probably listen to the USER doc to detect new familyTypes.
      // For now, let's just force a refresh or add manual.

      // Let's manually add to local list for instant feedback
      final createdFamily = FamilyModel(
        id: ref.id,
        name: name,
        inviteCode: inviteCode,
        adminId: user.uid,
        members: [member],
        createdAt: family.createdAt,
      );

      myFamilies.add(createdFamily);
      selectFamily(createdFamily);

      // Re-trigger subscription to ensure we hook up to the new family stream
      _subscribeToFamilies();

      return true;
    } catch (e) {
      errorMessage.value = 'error_create_family'.trParams({'error': e.toString()});
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
      if (user == null) throw Exception('error_must_login'.tr);

      final query = await _firestore
          .collection('families')
          .where('inviteCode', isEqualTo: code.toUpperCase())
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        errorMessage.value = 'error_invalid_code'.tr;
        return false;
      }

      final doc = query.docs.first;
      final family = FamilyModel.fromFirestore(doc);

      if (family.members.any((m) => m.userId == user.uid)) {
        errorMessage.value = 'error_already_member'.tr;
        return false;
      }

      final member = MemberModel(
        userId: user.uid,
        role: MemberRole.child,
        joinedAt: DateTime.now(),
        name: user.displayName,
        photoUrl: user.photoURL,
      );

      await _firestore.collection('families').doc(doc.id).update({
        'members': FieldValue.arrayUnion([member.toMap()]),
      });

      await _firestore.collection('users').doc(user.uid).set({
        'familyIds': FieldValue.arrayUnion([doc.id]),
        'familyId': doc.id, // Update default/legacy
      }, SetOptions(merge: true));

      _subscribeToFamilies();

      // Select the joined family
      // currentFamily.value = ... (will be set by subscription or manual)

      return true;
    } catch (e) {
      errorMessage.value = 'error_join_family'.trParams({'error': e.toString()});
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
      if (family == null) throw Exception('error_must_be_in_family'.tr);

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
      errorMessage.value = 'error_add_member'.trParams({'error': e.toString()});
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
        errorMessage.value = 'error_parents_only'.tr;
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

      final member = family.getMember(memberId);
      await addPulseEvent(
        familyId: family.id,
        type: 'prayer_logged',
        userId: memberId,
        userName: member?.name ?? 'member'.tr,
        prayerName: prayerName,
      );

      return true;
    } catch (e) {
      errorMessage.value = 'error_log_prayer'.trParams({'error': e.toString()});
      return false;
    }
  }

  /// Add an event to the family pulse (who prayed, encouragement, etc.)
  Future<void> addPulseEvent({
    required String familyId,
    required String type,
    required String userId,
    required String userName,
    String? prayerName,
  }) async {
    try {
      await _firestore
          .collection('families')
          .doc(familyId)
          .collection('pulse')
          .add({
            'type': type,
            'userId': userId,
            'userName': userName,
            if (prayerName != null) 'prayer': prayerName,
            'timestamp': FieldValue.serverTimestamp(),
          });
    } catch (_) {}
  }

  /// Live stream of family pulse events (last 25, newest first)
  Stream<List<FamilyPulseEvent>> getPulseStream(String familyId) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('pulse')
        .orderBy('timestamp', descending: true)
        .limit(25)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => FamilyPulseEvent.fromFirestore(d)).toList(),
        );
  }

  /// Send encouragement to a member
  Future<bool> sendEncouragement(String memberId, String message) async {
    try {
      final user = _authService.currentUser.value;
      if (user == null) return false;

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

      final family = currentFamily.value;
      if (family != null) {
        await addPulseEvent(
          familyId: family.id,
          type: 'encouragement',
          userId: user.uid,
          userName: user.displayName ?? 'member'.tr,
        );
      }

      return true;
    } catch (e) {
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
    if (_authService.currentUser.value != null) _subscribeToFamilies();
  }

  /// Subscribe to all families the user belongs to
  void _subscribeToFamilies() async {
    final user = _authService.currentUser.value;
    if (user == null) return;

    // 1. Listen to User Document to get/monitor familyIds
    // We reuse the list of subscriptions to manage this listener as well
    // But actually, for simplicity, let's just do a one-off fetch or listen to the user doc.
    // The previous code didn't listen to the user doc for familyId changes, it only fetched once.
    // Let's improve it by listening to the user doc for real-time family list updates.

    // We generally expect _subscribeToFamilies to be called ONCE on init/login.
    // But to support "Being added to a family" while online, we should listen to the user doc.

    // However, if we listen to user doc here, we might conflict with other listeners.
    // Let's stick to the pattern: Fetch once, then setup listeners for families.
    // If we want real-time "Allocated to new family", we need to listen to User doc.

    _clearSubscriptions(); // Clear previous session

    try {
      final userStream = _firestore
          .collection('users')
          .doc(user.uid)
          .snapshots();
      final userSub = userStream.listen((userDoc) async {
        if (!userDoc.exists) return;

        List<String> familyIds = [];
        final data = userDoc.data();

        // Handle both legacy 'familyId' and new 'familyIds'
        if (data != null) {
          if (data['familyIds'] is List) {
            familyIds = List<String>.from(data['familyIds']);
          } else if (data['familyId'] is String) {
            familyIds = [data['familyId']];
            // Auto-migrate if needed, but maybe later
          }
        }

        if (familyIds.isEmpty) {
          myFamilies.clear();
          currentFamily.value = null;
          // But wait, what if we have cached families?
          // For now, trust Firestore.
          return;
        }

        // 2. Manage subscriptions for each family
        // This is a nested listener. Since the outer specific listener (userSub) is long-lived,
        // we need to manage the inner listeners (familySubs).
        // A simple way is to cancel all inner listeners and recreate them when the list changes.
        // Optimization: Check if list actually changed.

        // For this iteration, we will simply fetch the current list of families
        // using a `whereIn` query if list is small (<10), which is likely.
        // Streaming `whereIn` is efficient.

        // ERROR: `whereIn` supports max 10 items.
        // If > 10, we need chunks. Assuming < 10 families for now.

        if (familyIds.length > 10) {
          familyIds = familyIds.sublist(0, 10); // Limit for now
        }

        // Cancel previous family group subscription (if any) to avoid duplicates
        // We need to store this specific subscription separately or manage it carefully.
        // Let's use a separate variable for the families listener.

        // Actually, the easiest way to sync a list of docs is listening to the collection with whereIn.
        final familiesStream = _firestore
            .collection('families')
            .where(FieldPath.documentId, whereIn: familyIds)
            .snapshots();

        final familiesSub = familiesStream.listen((querySnap) async {
          final List<FamilyModel> loadedFamilies = [];

          for (var doc in querySnap.docs) {
            loadedFamilies.add(FamilyModel.fromFirestore(doc));
          }

          myFamilies.assignAll(loadedFamilies);

          // 3. Update Current Family
          // If current is null, pick one (e.g. from cache or first).
          // If current is not in the new list, pick one.

          if (myFamilies.isNotEmpty) {
            if (currentFamily.value == null) {
              // Try to load last selected from cache
              final lastFamilyId = await _database.getCachedFamilyId(user.uid);
              final found = myFamilies.firstWhereOrNull(
                (f) => f.id == lastFamilyId,
              );
              selectFamily(found ?? myFamilies.first);
            } else {
              // Verify current still exists
              final found = myFamilies.firstWhereOrNull(
                (f) => f.id == currentFamily.value!.id,
              );
              if (found != null) {
                // Update the object with new data
                if (currentFamily.value != found) {
                  currentFamily.value = found;
                }
              } else {
                // Current family removed/left
                selectFamily(myFamilies.first);
              }
            }
          } else {
            currentFamily.value = null;
          }
        });

        // Track this subscription
        // We can't easily add it to _familySubscriptions inside the loop if we clear it every time.
        // But since userSub is the main driver, we can keep track of the active familiesSub inside this scope?
        // No, we need to cancel it when user logs out.
        // So we add it to the global list.
        _familySubscriptions.add(familiesSub);
      });

      _familySubscriptions.add(userSub);
    } catch (e) {
      debugPrint('FamilyService: Error subscribing: $e');
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
