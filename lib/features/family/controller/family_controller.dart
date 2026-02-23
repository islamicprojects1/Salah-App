import 'dart:async';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:salah/core/services/connectivity_service.dart';
import 'package:salah/core/di/injection_container.dart';
import 'package:salah/features/family/data/models/group_model.dart';
import 'package:salah/features/family/data/models/member_model.dart';
import 'package:salah/features/family/data/models/family_summary_model.dart';
import 'package:salah/core/constants/enums.dart' hide GroupType;
import 'package:salah/features/family/data/models/repositories/family_repository.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// FAMILY CONTROLLER
// المسار: lib/features/family/controller/family_controller.dart
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

enum FamilyViewState { initial, loading, hasGroup, noGroup, error }

class FamilyController extends GetxController {
  static FamilyController get to => Get.find();

  late final FamilyRepository _repo;
  late final ConnectivityService _connectivity;

  // ══════════════════════════════════════════════════════════════
  // STATE
  // ══════════════════════════════════════════════════════════════

  final viewState = FamilyViewState.initial.obs;
  final group = Rxn<GroupModel>();
  final members = <MemberModel>[].obs;
  final summary = Rxn<FamilySummaryModel>();
  final isActionLoading = false.obs;

  StreamSubscription? _groupSub;
  StreamSubscription? _membersSub;
  StreamSubscription? _summarySub;

  // ══════════════════════════════════════════════════════════════
  // GETTERS
  // ══════════════════════════════════════════════════════════════

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;
  bool get isAdmin => group.value?.adminId == currentUserId;
  bool get hasGroup => group.value != null;

  String? get inviteLink {
    final code = group.value?.inviteCode;
    if (code == null) return null;
    return 'https://qurb.app/join/$code';
  }

  // ══════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ══════════════════════════════════════════════════════════════

  @override
  void onInit() {
    super.onInit();
    _repo = FamilyRepository();
    _connectivity = sl<ConnectivityService>();
    loadGroup();
  }

  @override
  void onClose() {
    _cancelStreams();
    super.onClose();
  }

  // ══════════════════════════════════════════════════════════════
  // LOAD
  // ══════════════════════════════════════════════════════════════

  Future<void> loadGroup() async {
    viewState.value = FamilyViewState.loading;
    try {
      final g = await _repo.fetchMyGroup();
      if (g == null) {
        viewState.value = FamilyViewState.noGroup;
        return;
      }
      group.value = g;
      viewState.value = FamilyViewState.hasGroup;
      _startStreams(g.groupId);
      // فحص خلافة المدير عند فتح التطبيق
      await _repo.checkSuccession(g.groupId);
    } catch (e) {
      Get.log('[FamilyController] loadGroup: $e', isError: true);
      viewState.value = FamilyViewState.error;
    }
  }

  void _startStreams(String groupId) {
    _cancelStreams();
    _groupSub = _repo.watchGroup(groupId).listen((g) {
      if (g != null) group.value = g;
    });
    _membersSub = _repo.watchMembers(groupId).listen((list) {
      members.assignAll(list);
    });
    _summarySub = _repo.watchDailySummary(groupId).listen((s) {
      summary.value = s;
    });
  }

  void _cancelStreams() {
    _groupSub?.cancel();
    _membersSub?.cancel();
    _summarySub?.cancel();
  }

  /// Call before logout so Firestore streams are cancelled before auth is cleared.
  void cancelStreamsForLogout() {
    _cancelStreams();
    group.value = null;
    members.clear();
    summary.value = null;
    viewState.value = FamilyViewState.initial;
  }

  // ══════════════════════════════════════════════════════════════
  // CREATE
  // ══════════════════════════════════════════════════════════════

  Future<bool> createGroup({
    required GroupType type,
    required String name,
  }) async {
    isActionLoading.value = true;
    try {
      final g = await _repo.createGroup(type: type, name: name);
      if (g == null) return false;
      group.value = g;
      viewState.value = FamilyViewState.hasGroup;
      _startStreams(g.groupId);
      await FirebaseMessaging.instance.subscribeToTopic('family_${g.groupId}');
      return true;
    } finally {
      isActionLoading.value = false;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // JOIN
  // ══════════════════════════════════════════════════════════════

  /// يرجع: 'success' | 'already_member' | 'not_found' | 'blocked' | 'offline' | 'error'
  Future<String> joinByCode(String code) async {
    if (!_connectivity.isConnected.value) return 'offline';
    isActionLoading.value = true;
    try {
      final result = await _repo.joinByCode(code);
      if (result == 'success' || result == 'already_member') {
        await loadGroup();
        final groupId = group.value?.groupId;
        if (groupId != null) {
          await FirebaseMessaging.instance.subscribeToTopic('family_$groupId');
        }
      }
      return result;
    } finally {
      isActionLoading.value = false;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // SHADOW
  // ══════════════════════════════════════════════════════════════

  Future<bool> addShadowMember(String name, {String? contact}) async {
    final groupId = group.value?.groupId;
    if (groupId == null) return false;
    isActionLoading.value = true;
    try {
      final ok = await _repo.addShadowMember(
        groupId: groupId,
        name: name,
        contactHint: contact,
      );
      if (ok) await _repo.updateAdminActivity(groupId);
      return ok;
    } finally {
      isActionLoading.value = false;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // ADMIN ACTIONS
  // ══════════════════════════════════════════════════════════════

  Future<bool> kickMember(String targetId) async {
    final groupId = group.value?.groupId;
    if (groupId == null || !isAdmin) return false;
    isActionLoading.value = true;
    try {
      final ok = await _repo.kickMember(groupId, targetId);
      if (ok) await _repo.updateAdminActivity(groupId);
      return ok;
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<bool> kickAndBlock(String targetId) async {
    final groupId = group.value?.groupId;
    if (groupId == null || !isAdmin) return false;
    isActionLoading.value = true;
    try {
      final ok = await _repo.kickAndBlock(groupId, targetId);
      if (ok) await _repo.updateAdminActivity(groupId);
      return ok;
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<bool> unblockUser(String targetId) async {
    final groupId = group.value?.groupId;
    if (groupId == null || !isAdmin) return false;
    return _repo.unblockUser(groupId, targetId);
  }

  Future<bool> transferAdmin(String newAdminId) async {
    final groupId = group.value?.groupId;
    if (groupId == null || !isAdmin) return false;
    isActionLoading.value = true;
    try {
      return await _repo.transferAdmin(groupId, newAdminId);
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<String?> renewInviteCode() async {
    final groupId = group.value?.groupId;
    if (groupId == null || !isAdmin) return null;
    isActionLoading.value = true;
    try {
      final code = await _repo.renewInviteCode(groupId);
      if (code != null) {
        group.value = group.value?.copyWith(inviteCode: code);
      }
      return code;
    } finally {
      isActionLoading.value = false;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // LEAVE / DISSOLVE
  // ══════════════════════════════════════════════════════════════

  Future<bool> leaveGroup() async {
    final groupId = group.value?.groupId;
    if (groupId == null) return false;
    isActionLoading.value = true;
    try {
      final ok = await _repo.leaveGroup(groupId);
      if (ok) {
        await FirebaseMessaging.instance.unsubscribeFromTopic('family_$groupId');
        _resetState();
      }
      return ok;
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<bool> dissolveGroup() async {
    final groupId = group.value?.groupId;
    if (groupId == null || !isAdmin) return false;
    isActionLoading.value = true;
    try {
      final ok = await _repo.dissolveGroup(groupId);
      if (ok) {
        await FirebaseMessaging.instance.unsubscribeFromTopic('family_$groupId');
        _resetState();
      }
      return ok;
    } finally {
      isActionLoading.value = false;
    }
  }

  void _resetState() {
    _cancelStreams();
    group.value = null;
    members.clear();
    summary.value = null;
    viewState.value = FamilyViewState.noGroup;
  }

  // ══════════════════════════════════════════════════════════════
  // INVITE
  // ══════════════════════════════════════════════════════════════

  void copyCode() {
    final code = group.value?.inviteCode;
    if (code == null) return;
    Clipboard.setData(ClipboardData(text: code));
  }

  // ══════════════════════════════════════════════════════════════
  // PRAYER HOOK — يُستدعى من PrayerRepository
  // ══════════════════════════════════════════════════════════════

  Future<void> onPrayerLogged(PrayerName prayer) async {
    final groupId = group.value?.groupId;
    if (groupId == null) return;
    await _repo.onPrayerLogged(groupId, prayer.name);
  }
}
