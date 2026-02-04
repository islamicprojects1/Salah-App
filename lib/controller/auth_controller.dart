import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/services/firestore_service.dart';
import 'package:salah/data/models/user_model.dart';
import 'package:salah/core/services/auth_service.dart';
import 'package:salah/core/services/storage_service.dart';
import 'package:salah/core/constants/storage_keys.dart';

/// Controller for authentication flow
class AuthController extends GetxController {
  // ============================================================
  // DEPENDENCIES
  // ============================================================

  final AuthService _authService = Get.find<AuthService>();
  final StorageService _storage = Get.find<StorageService>();
  final FirestoreService _firestore = Get.find<FirestoreService>();

  // ============================================================
  // OBSERVABLES
  // ============================================================

  final isLoading = false.obs;
  final errorMessage = ''.obs;

  // Form controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final birthDateController = TextEditingController();

  // Profile setup
  final selectedGender = ''.obs;
  final selectedBirthDate = Rx<DateTime?>(null);

  // ============================================================
  // GETTERS
  // ============================================================

  bool get isLoggedIn => _authService.isLoggedIn;
  bool get isFirstTime =>
      !(_storage.read<bool>(StorageKeys.onboardingCompleted) ?? false);

  // ============================================================
  // AUTH METHODS
  // ============================================================

  /// Register with email and password
  Future<bool> registerWithEmail() async {
    if (!_validateForm()) return false;

    isLoading.value = true;
    errorMessage.value = '';

    try {
      print('DEBUG: Starting registration for ${emailController.text.trim()}');
      
      final user = await _authService.registerWithEmail(
        email: emailController.text.trim(),
        password: passwordController.text,
        displayName: nameController.text.trim(),
      );

      print('DEBUG: Registration result - user: ${user?.uid}');

      if (user != null) {
        print('DEBUG: Creating Firestore user document...');
        
        // Create user document in Firestore immediately
        final userModel = UserModel(
          id: user.uid,
          name: nameController.text.trim(),
          birthDate: selectedBirthDate.value ?? DateTime(2000, 1, 1),
          gender: selectedGender.value == 'male' ? Gender.male : Gender.female,
          email: user.email,
          photoUrl: user.photoURL,
          createdAt: DateTime.now(),
          language: Get.locale?.languageCode ?? 'ar',
        );

        await _firestore.setUser(user.uid, userModel.toFirestore());
        print('DEBUG: User document created successfully');
        return true;
      } else {
        print('DEBUG: Registration failed - authService error: ${_authService.errorMessage.value}');
        errorMessage.value = _authService.errorMessage.value.isNotEmpty 
            ? _authService.errorMessage.value 
            : 'فشل إنشاء الحساب';
        return false;
      }
    } catch (e, stackTrace) {
      print('DEBUG: Registration exception - $e');
      print('DEBUG: Stack trace - $stackTrace');
      errorMessage.value = 'خطأ في التسجيل: ${e.toString()}';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Login with email and password
  Future<bool> loginWithEmail() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      errorMessage.value = 'الرجاء إدخال البريد وكلمة المرور';
      return false;
    }

    print('DEBUG: loginWithEmail started for ${emailController.text}');
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final user = await _authService.signInWithEmail(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (user != null) {
        return true;
      } else {
        errorMessage.value = 'خطأ في البريد أو كلمة المرور';
        return false;
      }
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      print('DEBUG: loginWithEmail finished. Result: ${errorMessage.value.isEmpty}');
      isLoading.value = false;
    }
  }

  /// Login with Google
  Future<bool> loginWithGoogle() async {
    print('DEBUG: loginWithGoogle started');
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final user = await _authService.signInWithGoogle();
      print('DEBUG: loginWithGoogle finished. User: $user');
      return user != null;
    } catch (e) {
      print('ERROR: Google Sign In failed: $e');
      errorMessage.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Logout
  Future<void> logout() async {
    await _authService.signOut();
  }

  // ============================================================
  // ONBOARDING
  // ============================================================

  /// Mark onboarding as completed
  void completeOnboarding() {
    _storage.write(StorageKeys.onboardingCompleted, true);
  }

  // ============================================================
  // PROFILE SETUP
  // ============================================================

  /// Update user profile
  Future<bool> updateProfile() async {
    if (nameController.text.isEmpty) {
      errorMessage.value = 'الرجاء إدخال الاسم';
      return false;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final user = _authService.currentUser.value;
      if (user == null) return false;

      final userModel = UserModel(
        id: user.uid,
        name: nameController.text.trim(),
        birthDate: selectedBirthDate.value ?? DateTime(2000),
        gender: selectedGender.value == 'male' ? Gender.male : Gender.female,
        email: user.email,
        photoUrl: user.photoURL,
        createdAt: DateTime.now(),
        language: Get.locale?.languageCode ?? 'ar',
      );

      await _firestore.setUser(user.uid, userModel.toFirestore());

      // Update display name in Firebase Auth too
      await _authService.updateDisplayName(userModel.name);

      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Set birth date
  void setBirthDate(DateTime date) {
    selectedBirthDate.value = date;
    birthDateController.text = '${date.day}/${date.month}/${date.year}';
  }

  /// Set gender
  void setGender(String gender) {
    selectedGender.value = gender;
  }

  // ============================================================
  // HELPERS
  // ============================================================

  bool _validateForm() {
    if (nameController.text.isEmpty) {
      errorMessage.value = 'الرجاء إدخال الاسم';
      return false;
    }
    if (emailController.text.isEmpty) {
      errorMessage.value = 'الرجاء إدخال البريد الإلكتروني';
      return false;
    }
    if (passwordController.text.length < 6) {
      errorMessage.value = 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
      return false;
    }
    return true;
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    birthDateController.dispose();
    super.onClose();
  }
}
