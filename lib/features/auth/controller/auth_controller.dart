import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/constants/storage_keys.dart';
import 'package:salah/core/di/injection_container.dart';
import 'package:salah/core/feedback/toast_service.dart';
import 'package:salah/core/helpers/input_validators.dart';
import 'package:salah/core/routes/app_routes.dart';
import 'package:salah/core/services/storage_service.dart';
import 'package:salah/features/auth/data/helpers/auth_validation.dart';
import 'package:salah/features/auth/data/models/user_model.dart';
import 'package:salah/features/auth/data/services/auth_service.dart';
import 'package:salah/features/prayer/data/services/firestore_service.dart';

/// Controller for authentication flow
class AuthController extends GetxController {
  // ============================================================
  // DEPENDENCIES
  // ============================================================

  final AuthService _authService = sl<AuthService>();
  final StorageService _storage = sl<StorageService>();
  final FirestoreService _firestore = sl<FirestoreService>();

  // ============================================================
  // OBSERVABLES
  // ============================================================

  final isLoading = false.obs;
  final isGoogleLoading = false.obs;
  final errorMessage = ''.obs;

  // Password visibility toggles
  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;

  // Form controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
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
      final birthDate = selectedBirthDate.value ?? DateTime(2000, 1, 1);
      final birthErr = InputValidators.validateBirthDate(birthDate);
      if (birthErr != null) {
        errorMessage.value = birthErr;
        return false;
      }

      final user = await _authService.registerWithEmail(
        email: emailController.text.trim(),
        password: passwordController.text,
        displayName: nameController.text.trim(),
      );

      if (user != null) {
        final userModel = UserModel(
          id: user.uid,
          name: nameController.text.trim(),
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
        final msg = _authService.errorMessage.value.isNotEmpty
            ? _authService.errorMessage.value
            : 'auth_error_default'.tr;
        errorMessage.value = msg;
        ToastService.error('error'.tr, msg);
        return false;
      }
    } catch (e) {
      final msg = 'auth_error_default'.tr;
      errorMessage.value = msg;
      ToastService.error('error'.tr, msg);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Login with email and password
  Future<bool> loginWithEmail() async {
    clearError();

    final emailErr = AuthValidation.validateEmail(emailController.text.trim());
    if (emailErr != null) {
      errorMessage.value = emailErr;
      return false;
    }
    final passErr = AuthValidation.validatePassword(passwordController.text);
    if (passErr != null) {
      errorMessage.value = passErr;
      return false;
    }

    isLoading.value = true;
    try {
      final user = await _authService.signInWithEmail(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      if (user != null) return true;

      final msg = _authService.errorMessage.value.isNotEmpty
          ? _authService.errorMessage.value
          : 'auth_error_default'.tr;
      errorMessage.value = msg;
      return false;
    } catch (e) {
      errorMessage.value = 'auth_error_default'.tr;
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> loginWithGoogle() async {
    isGoogleLoading.value = true;
    clearError();
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) return true;

      final msg = _authService.errorMessage.value.isNotEmpty
          ? _authService.errorMessage.value
          : 'auth_error_default'.tr;
      errorMessage.value = msg;
      return false;
    } catch (e) {
      final msg = 'auth_error_default'.tr;
      errorMessage.value = msg;
      ToastService.error('error'.tr, msg);
      return false;
    } finally {
      isGoogleLoading.value = false;
    }
  }

  void navigateToRegister() {
    clearFormAndErrors();
    Get.toNamed(AppRoutes.register);
  }

  void navigateToLogin() {
    clearFormAndErrors();
    Get.back();
  }

  void navigateToForgotPassword() {
    if (emailController.text.trim().isEmpty) {
      ToastService.info('forgot_password'.tr, 'enter_email_first'.tr);
      return;
    }
    // TODO: implement forgot password flow
    _authService.sendPasswordResetEmail(emailController.text.trim()).then((
      success,
    ) {
      if (success) {
        ToastService.success('forgot_password'.tr, 'password_reset_sent'.tr);
      }
    });
  }

  /// Toggle password visibility
  void togglePasswordVisibility() =>
      isPasswordVisible.value = !isPasswordVisible.value;

  /// Toggle confirm password visibility
  void toggleConfirmPasswordVisibility() =>
      isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;

  /// Clear error message
  void clearError() => errorMessage.value = '';

  /// Clear form fields and errors
  void clearFormAndErrors() {
    clearError();
    isPasswordVisible.value = false;
    isConfirmPasswordVisible.value = false;
  }

  /// Logout
  Future<void> logout() async {
    await _authService.signOut();
    clearFormAndErrors();
  }

  // ============================================================
  // ONBOARDING
  // ============================================================

  void completeOnboarding() {
    _storage.write(StorageKeys.onboardingCompleted, true);
  }

  // ============================================================
  // PROFILE SETUP
  // ============================================================

  Future<bool> updateProfile() async {
    final nameErr = AuthValidation.validateName(nameController.text);
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
    clearError();

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
      await _authService.updateDisplayName(userModel.name);

      return true;
    } catch (e) {
      errorMessage.value = 'auth_error_default'.tr;
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void setBirthDate(DateTime date) {
    selectedBirthDate.value = date;
    birthDateController.text = '${date.day}/${date.month}/${date.year}';
  }

  void setGender(String gender) => selectedGender.value = gender;

  // ============================================================
  // HELPERS
  // ============================================================

  bool _validateForm() {
    final nameErr = AuthValidation.validateName(nameController.text);
    if (nameErr != null) {
      errorMessage.value = nameErr;
      return false;
    }
    final emailErr = AuthValidation.validateEmail(emailController.text.trim());
    if (emailErr != null) {
      errorMessage.value = emailErr;
      return false;
    }
    final passErr = AuthValidation.validatePassword(passwordController.text);
    if (passErr != null) {
      errorMessage.value = passErr;
      return false;
    }
    if (passwordController.text != confirmPasswordController.text) {
      errorMessage.value = 'passwords_dont_match'.tr;
      return false;
    }
    return true;
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    birthDateController.dispose();
    super.onClose();
  }
}
