import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/services/family_service.dart';
import 'package:salah/core/services/auth_service.dart';
import 'package:salah/data/models/family_model.dart';
import 'package:salah/data/models/user_model.dart';
import 'package:salah/core/routes/app_routes.dart';

class FamilyController extends GetxController {
  final FamilyService _familyService = Get.find<FamilyService>();
  final AuthService _authService = Get.find<AuthService>();
  
  // Observables
  bool get isLoading => _familyService.isLoading.value;
  String get errorMessage => _familyService.errorMessage.value;
  FamilyModel? get currentFamily => _familyService.currentFamily.value;
  bool get hasFamily => currentFamily != null;

  @override
  void onInit() {
    super.onInit();
    // Listen to family changes to load member data
    ever(_familyService.currentFamily, (family) {
      if (family != null) {
        loadMembersData();
      }
    });
  }

  // Real-time progress for members
  final memberProgress = <String, int>{}.obs; // userId -> count of prayers today
  final memberStreaks = <String, int>{}.obs; // userId -> streak

  // Text Controllers
  final familyNameController = TextEditingController();
  final inviteCodeController = TextEditingController();

  // Actions
  
  /// Create a new family
  Future<void> createFamily() async {
    if (familyNameController.text.trim().isEmpty) {
      Get.snackbar('تنبيه', 'الرجاء إدخال اسم العائلة',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final success = await _familyService.createFamily(familyNameController.text.trim());
    
    if (success) {
      Get.offNamed(AppRoutes.dashboard); // Or navigate to Family Dashboard
      Get.snackbar('تم بنجاح', 'تم إنشاء العائلة بنجاح');
    } else {
      Get.snackbar('خطأ', errorMessage);
    }
  }

  /// Join a family
  Future<void> joinFamily() async {
    if (inviteCodeController.text.trim().length != 6) {
      Get.snackbar('تنبيه', 'كود الدعوة يجب أن يتكون من 6 أرقام/حروف',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final success = await _familyService.joinFamily(inviteCodeController.text.trim());
    
    if (success) {
      Get.offNamed(AppRoutes.dashboard);
      Get.snackbar('تم بنجاح', 'تم الانضمام للعائلة بنجاح');
    } else {
      Get.snackbar('خطأ', errorMessage);
    }
  }

  /// Add a child without phone
  Future<void> addChild(String name, DateTime birthDate, String gender) async {
    final success = await _familyService.addChildWithoutPhone(
      name: name,
      birthDate: birthDate,
      gender: gender == 'male' ? Gender.male : Gender.female,
    );

    if (success) {
      Get.back(); // Close dialog/screen
      Get.snackbar('تم بنجاح', 'تم إضافة الطفل بنجاح');
    } else {
      Get.snackbar('خطأ', errorMessage);
    }
  }

  /// Load progress for all members
  void loadMembersData() {
    final family = currentFamily;
    if (family == null) return;

    for (var member in family.members) {
      _loadSingleMemberData(member.userId);
    }
  }

  void _loadSingleMemberData(String userId) {
    // This could be optimized to a single query if all members are in same family
    // For now, load each one simple-way
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    
    _familyService.getMemberTodayLogs(userId).listen((snapshot) {
        memberProgress[userId] = snapshot.docs.length;
    });
    
    _familyService.getMemberData(userId).listen((doc) {
        if (doc.exists) {
            memberStreaks[userId] = doc.data()?['currentStreak'] ?? 0;
        }
    });
  }

  /// Poke/Encourage a member
  Future<void> pokeMember(String userId, String name) async {
    final success = await _familyService.sendEncouragement(
      userId, 
      'شجعك ${Get.find<AuthService>().currentUser.value?.displayName ?? 'عضو'} على الصلاة! ✨',
    );
    if (success) {
      Get.snackbar('تم', 'تم إرسال تشجيع لـ $name');
    }
  }

  @override
  void onClose() {
    familyNameController.dispose();
    inviteCodeController.dispose();
    super.onClose();
  }
}
