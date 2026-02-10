import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/constants/storage_keys.dart';
import 'package:salah/core/helpers/input_validators.dart';
import 'package:salah/core/services/auth_service.dart';
import 'package:salah/core/services/firestore_service.dart';
import 'package:salah/core/services/storage_service.dart';
import 'package:salah/data/models/user_model.dart';

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
      final (name, _) = InputValidators.validateDisplayName(nameController.text);
      final birthDate = selectedBirthDate.value ?? DateTime(2000, 1, 1);
      final birthErr = InputValidators.validateBirthDate(birthDate);
      if (birthErr != null) {
        errorMessage.value = birthErr;
        return false;
      }
      final user = await _authService.registerWithEmail(
        email: emailController.text.trim(),
        password: passwordController.text,
        displayName: name ?? '',
      );

      if (user != null) {
        final userModel = UserModel(
          id: user.uid,
          name: name ?? '',
          birthDate: birthDate,
          gender: selectedGender.value == 'male' ? Gender.male : Gender.female,
          email: user.email,
          photoUrl: user.photoURL,
          createdAt: DateTime.now(),
          language: Get.locale?.languageCode ?? 'ar',
        );
        await _firestore.setUser(user.uid, userModel.toFirestore());
        return true;
      } else {
        errorMessage.value = _authService.errorMessage.value.isNotEmpty
            ? _authService.errorMessage.value
            : 'فشل إنشاء الحساب';
        return false;
      }
    } catch (e, _) {
      errorMessage.value = 'خطأ في التسجيل: ${e.toString()}';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Login with email and password. GetX-compatible validation via GetUtils.
  Future<bool> loginWithEmail() async {
    if (!GetUtils.isEmail(emailController.text.trim())) {
      errorMessage.value = 'الرجاء إدخال بريد إلكتروني صحيح';
      return false;
    }
    if (passwordController.text.isEmpty) {
      errorMessage.value = 'الرجاء إدخال كلمة المرور';
      return false;
    }
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final user = await _authService.signInWithEmail(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      if (user != null) return true;
      errorMessage.value = 'خطأ في البريد أو كلمة المرور';
      return false;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> loginWithGoogle() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final user = await _authService.signInWithGoogle();
      return user != null;
    } catch (e) {
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

  Future<bool> updateProfile() async {
    final (name, nameErr) = InputValidators.validateDisplayName(nameController.text);
    if (nameErr != null) {
      errorMessage.value = nameErr;
      return false;
    }
    final birthDate = selectedBirthDate.value;
    if (birthDate != null) {
      final birthErr = InputValidators.validateBirthDate(birthDate);
      if (birthErr != null) {
        errorMessage.value = birthErr;
        return false;
      }
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final user = _authService.currentUser.value;
      if (user == null) return false;

      final userModel = UserModel(
        id: user.uid,
        name: name!,
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
    final (name, nameErr) = InputValidators.validateDisplayName(nameController.text);
    if (nameErr != null) {
      errorMessage.value = nameErr;
      return false;
    }
    if (!GetUtils.isEmail(emailController.text.trim())) {
      errorMessage.value = 'الرجاء إدخال بريد إلكتروني صحيح';
      return false;
    }
    if (!GetUtils.isLengthGreaterOrEqual(passwordController.text, 6)) {
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
