import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/feedback/app_feedback.dart';
import 'package:salah/core/helpers/input_validators.dart';
import 'package:salah/core/routes/app_routes.dart';
import 'package:salah/core/services/auth_service.dart';
import 'package:salah/core/services/family_service.dart';
import 'package:salah/core/services/firestore_service.dart';
import 'package:salah/data/models/family_model.dart';
import 'package:salah/data/models/family_pulse_model.dart';
import 'package:salah/data/models/user_model.dart';

class FamilyController extends GetxController {
  final FamilyService _familyService = Get.find<FamilyService>();
  final AuthService _authService = Get.find<AuthService>();

  // Observables
  bool get isLoading => _familyService.isLoading.value;
  String get errorMessage => _familyService.errorMessage.value;
  FamilyModel? get currentFamily => _familyService.currentFamily.value;
  RxList<FamilyModel> get myFamilies => _familyService.myFamilies;
  bool get hasFamily => currentFamily != null;

  void selectFamily(FamilyModel family) {
    _familyService.selectFamily(family);
  }

  final RxList<FamilyPulseEvent> pulseEvents = <FamilyPulseEvent>[].obs;
  StreamSubscription<List<FamilyPulseEvent>>? _pulseSubscription;

  @override
  void onInit() {
    super.onInit();
    ever(_familyService.currentFamily, (family) {
      if (family != null) {
        loadMembersData();
        _subscribePulse(family.id);
      } else {
        _pulseSubscription?.cancel();
        pulseEvents.clear();
      }
    });
    if (currentFamily != null) _subscribePulse(currentFamily!.id);
  }

  void _subscribePulse(String familyId) {
    _pulseSubscription?.cancel();
    _pulseSubscription = _familyService.getPulseStream(familyId).listen((list) {
      pulseEvents.assignAll(list);
    });
  }

  @override
  void onReady() {
    super.onReady();
    // Ensure family loads when user opens tab (e.g. after app reopen)
    _familyService.refreshFamily();
  }

  final memberProgress = <String, int>{}.obs;
  final memberStreaks = <String, int>{}.obs;

  final List<StreamSubscription<dynamic>> _memberSubscriptions = [];

  final familyNameController = TextEditingController();
  final inviteCodeController = TextEditingController();

  // Actions

  Future<void> createFamily() async {
    final (name, err) = InputValidators.validateFamilyName(
      familyNameController.text,
    );
    if (err != null) {
      AppFeedback.showSnackbar('تنبيه', err);
      return;
    }
    final success = await _familyService.createFamily(name!);
    if (success) {
      Get.back();
      AppFeedback.showSuccess('تم بنجاح', 'تم إنشاء العائلة بنجاح');
    } else {
      AppFeedback.showError('خطأ', errorMessage);
    }
  }

  Future<void> joinFamily() async {
    final (code, err) = InputValidators.validateInviteCode(
      inviteCodeController.text,
    );
    if (err != null) {
      AppFeedback.showSnackbar('تنبيه', err);
      return;
    }
    final success = await _familyService.joinFamily(code!);
    if (success) {
      Get.back();
      AppFeedback.showSuccess('تم بنجاح', 'تم الانضمام للعائلة بنجاح');
    } else {
      AppFeedback.showError('خطأ', errorMessage);
    }
  }

  Future<void> addChild(String name, DateTime birthDate, String gender) async {
    final (validName, nameErr) = InputValidators.validateDisplayName(name);
    if (nameErr != null) {
      AppFeedback.showSnackbar('تنبيه', nameErr);
      return;
    }
    final birthErr = InputValidators.validateBirthDate(birthDate);
    if (birthErr != null) {
      AppFeedback.showSnackbar('تنبيه', birthErr);
      return;
    }
    final success = await _familyService.addChildWithoutPhone(
      name: validName!,
      birthDate: birthDate,
      gender: gender == 'male' ? Gender.male : Gender.female,
    );
    if (success) {
      Get.back();
      AppFeedback.showSuccess('تم بنجاح', 'تم إضافة الطفل بنجاح');
    } else {
      AppFeedback.showError('خطأ', errorMessage);
    }
  }

  void loadMembersData() {
    for (final sub in _memberSubscriptions) {
      sub.cancel();
    }
    _memberSubscriptions.clear();

    final family = currentFamily;
    if (family == null) return;

    for (var member in family.members) {
      _loadSingleMemberData(member.userId);
    }
  }

  void _loadSingleMemberData(String userId) {
    _memberSubscriptions.add(
      _familyService.getMemberTodayLogs(userId).listen((snapshot) {
        memberProgress[userId] = snapshot.docs.length;
      }),
    );
    _memberSubscriptions.add(
      _familyService.getMemberData(userId).listen((doc) {
        if (doc.exists) {
          memberStreaks[userId] = doc.data()?['currentStreak'] ?? 0;
        }
      }),
    );
  }

  /// Parent logs a prayer on behalf of a child (spec: Parent logs for child).
  Future<void> logPrayerForMember({
    required String memberId,
    required String prayerName,
    required DateTime adhanTime,
  }) async {
    final success = await _familyService.logPrayerForMember(
      memberId: memberId,
      prayerName: prayerName,
      prayerTime: adhanTime,
    );
    if (success) {
      AppFeedback.showSuccess('تم', 'تم تسجيل الصلاة عنه');
      loadMembersData();
    } else {
      AppFeedback.showError('خطأ', errorMessage);
    }
  }

  Future<void> pokeMember(String userId, String name) async {
    final success = await _familyService.sendEncouragement(
      userId,
      'شجعك ${_authService.currentUser.value?.displayName ?? 'عضو'} على الصلاة! ✨',
    );
    if (success) {
      final myId = _authService.currentUser.value?.uid;
      if (myId != null) {
        Get.find<FirestoreService>().addAnalyticsEvent(
          userId: myId,
          event: 'encouragement_sent',
          data: {'toUserId': userId},
        );
      }
      AppFeedback.showSuccess('تم', 'تم إرسال تشجيع لـ $name');
    } else {
      AppFeedback.showError('خطأ', errorMessage);
    }
  }

  @override
  void onClose() {
    _pulseSubscription?.cancel();
    for (final sub in _memberSubscriptions) {
      sub.cancel();
    }
    _memberSubscriptions.clear();
    familyNameController.dispose();
    inviteCodeController.dispose();
    super.onClose();
  }
}
