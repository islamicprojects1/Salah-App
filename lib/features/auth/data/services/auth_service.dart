import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:salah/core/error/app_logger.dart';
import 'package:salah/features/auth/data/helpers/auth_error_messages.dart';
import 'package:salah/features/auth/data/helpers/auth_validation.dart';

/// Service for managing authentication with Firebase
class AuthService extends GetxService {
  // ============================================================
  // PRIVATE
  // ============================================================

  late final FirebaseAuth _auth;
  late final GoogleSignIn _googleSignIn;

  // ============================================================
  // OBSERVABLE STATE
  // ============================================================

  final currentUser = Rxn<User>();
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  bool _isInitialized = false;

  /// Initialize the service
  Future<AuthService> init() async {
    if (_isInitialized) return this;
    _isInitialized = true;
    _auth = FirebaseAuth.instance;
    _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

    // Listen to auth state changes
    _auth.authStateChanges().listen((user) {
      currentUser.value = user;
      if (user != null) {
        _updateFcmToken();
      }
    });

    return this;
  }

  // ============================================================
  // GETTERS
  // ============================================================

  bool get isLoggedIn => currentUser.value != null;
  String? get userId => currentUser.value?.uid;
  String? get userEmail => currentUser.value?.email;
  String? get userName => currentUser.value?.displayName;
  String? get userPhotoUrl => currentUser.value?.photoURL;

  // ============================================================
  // EMAIL/PASSWORD AUTHENTICATION
  // ============================================================

  /// Register with email and password
  Future<User?> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final emailError = AuthValidation.validateEmail(email);
      if (emailError != null) {
        errorMessage.value = emailError;
        return null;
      }

      final passwordError = AuthValidation.validatePassword(password);
      if (passwordError != null) {
        errorMessage.value = passwordError;
        return null;
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (displayName != null && credential.user != null) {
        await credential.user!.updateDisplayName(displayName);
        // Reload to get updated display name
        await credential.user!.reload();
      }

      return _auth.currentUser;
    } on FirebaseAuthException catch (e) {
      errorMessage.value = AuthErrorMessages.fromCode(e.code);
      AppLogger.warning('registerWithEmail failed: ${e.code}', e);
      return null;
    } catch (e) {
      errorMessage.value = 'auth_error_default'.tr;
      AppLogger.error('registerWithEmail unexpected error', e);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Sign in with email and password
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final emailError = AuthValidation.validateEmail(email);
      if (emailError != null) {
        errorMessage.value = emailError;
        return null;
      }

      if (password.isEmpty) {
        errorMessage.value = 'enter_password'.tr;
        return null;
      }

      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      return credential.user;
    } on FirebaseAuthException catch (e) {
      errorMessage.value = AuthErrorMessages.fromCode(e.code);
      AppLogger.warning('signInWithEmail failed: ${e.code}', e);
      return null;
    } catch (e) {
      errorMessage.value = 'auth_error_default'.tr;
      AppLogger.error('signInWithEmail unexpected error', e);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // GOOGLE SIGN IN
  // ============================================================

  /// Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Sign out first to force account picker
      await _googleSignIn.signOut();

      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled — not an error
        errorMessage.value = '';
        return null;
      }

      final googleAuth = await googleUser.authentication;

      if (googleAuth.accessToken == null && googleAuth.idToken == null) {
        errorMessage.value = 'auth_error_google_cancelled'.tr;
        return null;
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      errorMessage.value = AuthErrorMessages.fromCode(e.code);
      AppLogger.warning('signInWithGoogle Firebase error: ${e.code}', e);
      return null;
    } on PlatformException catch (e) {
      final code = e.code;
      final msg = e.message ?? '';
      if (code == 'sign_in_failed' &&
          (msg.contains('10') || msg.contains('DEVELOPER_ERROR'))) {
        errorMessage.value = 'auth_error_google_developer'.tr;
        AppLogger.warning('signInWithGoogle DEVELOPER_ERROR: add SHA-1 to Firebase Console', e);
      } else if (msg.contains('canceled') ||
          msg.contains('cancelled') ||
          msg.contains('12501')) {
        errorMessage.value = '';
      } else {
        errorMessage.value = 'auth_error_default'.tr;
        AppLogger.warning('signInWithGoogle PlatformException: $code', e);
      }
      return null;
    } catch (e) {
      // Check for user cancellation
      final msg = e.toString();
      if (msg.contains('canceled') ||
          msg.contains('cancelled') ||
          msg.contains('sign_in_canceled')) {
        errorMessage.value = '';
        return null;
      }
      errorMessage.value = 'auth_error_default'.tr;
      AppLogger.error('signInWithGoogle unexpected error', e);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // PASSWORD MANAGEMENT
  // ============================================================

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final emailError = AuthValidation.validateEmail(email);
      if (emailError != null) {
        errorMessage.value = emailError;
        return false;
      }

      await _auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage.value = AuthErrorMessages.fromCode(e.code);
      return false;
    } catch (e) {
      errorMessage.value = 'auth_error_default'.tr;
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Update password
  Future<bool> updatePassword(String newPassword) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final passwordError = AuthValidation.validatePassword(newPassword);
      if (passwordError != null) {
        errorMessage.value = passwordError;
        return false;
      }

      await currentUser.value?.updatePassword(newPassword);
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage.value = AuthErrorMessages.fromCode(e.code);
      return false;
    } catch (e) {
      errorMessage.value = 'auth_error_default'.tr;
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // PROFILE MANAGEMENT
  // ============================================================

  /// Update display name
  Future<bool> updateDisplayName(String displayName) async {
    try {
      await currentUser.value?.updateDisplayName(displayName);
      await currentUser.value?.reload();
      currentUser.value = _auth.currentUser;
      return true;
    } catch (e) {
      AppLogger.warning('updateDisplayName failed', e);
      return false;
    }
  }

  /// Update profile (name and photo)
  Future<bool> updateProfile({String? displayName, String? photoURL}) async {
    try {
      if (displayName != null) {
        await currentUser.value?.updateDisplayName(displayName);
      }
      if (photoURL != null) {
        await currentUser.value?.updatePhotoURL(photoURL);
      }

      await currentUser.value?.reload();
      currentUser.value = _auth.currentUser;
      return true;
    } catch (e) {
      errorMessage.value = 'auth_error_default'.tr;
      AppLogger.warning('updateProfile failed', e);
      return false;
    }
  }

  // ============================================================
  // SIGN OUT
  // ============================================================

  /// Sign out from all providers
  Future<void> signOut() async {
    try {
      final isGoogleUser =
          currentUser.value?.providerData.any(
            (p) => p.providerId == 'google.com',
          ) ??
          false;

      if (isGoogleUser) {
        await _googleSignIn.signOut();
      }
      await _auth.signOut();
    } catch (e) {
      AppLogger.debug('AuthService.signOut error (non-critical)', e);
    }
  }

  /// Delete account
  Future<bool> deleteAccount() async {
    try {
      await currentUser.value?.delete();
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage.value = AuthErrorMessages.fromCode(e.code);
      return false;
    } catch (e) {
      errorMessage.value = 'auth_error_default'.tr;
      return false;
    }
  }

  /// Refresh current user token
  Future<String?> refreshToken() async {
    try {
      return await currentUser.value?.getIdToken(true);
    } catch (e) {
      AppLogger.warning('refreshToken failed', e);
      return null;
    }
  }

  /// Update FCM token in Firestore
  Future<void> _updateFcmToken() async {
    return; // TODO: restore when FcmService is re-implemented
  }
}
