import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

  // ============================================================
  // INITIALIZATION
  // ============================================================
  
  /// Initialize the service
  Future<AuthService> init() async {
    _auth = FirebaseAuth.instance;
    _googleSignIn = GoogleSignIn();
    
    // Listen to auth state changes
    _auth.authStateChanges().listen((user) {
      currentUser.value = user;
    });
    
    return this;
  }

  // ============================================================
  // GETTERS
  // ============================================================
  
  /// Check if user is logged in
  bool get isLoggedIn => currentUser.value != null;
  
  /// Get user ID
  String? get userId => currentUser.value?.uid;
  
  /// Get user email
  String? get userEmail => currentUser.value?.email;
  
  /// Get user display name
  String? get userName => currentUser.value?.displayName;
  
  /// Get user photo URL
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
      
      // Validate email format
      final emailError = _validateEmail(email);
      if (emailError != null) {
        errorMessage.value = emailError;
        return null;
      }
      
      // Validate password strength
      final passwordError = _validatePassword(password);
      if (passwordError != null) {
        errorMessage.value = passwordError;
        return null;
      }
      
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      // Update display name if provided
      if (displayName != null && credential.user != null) {
        await credential.user!.updateDisplayName(displayName);
      }
      
      return credential.user;
    } on FirebaseException catch (e) {
      errorMessage.value = _getErrorMessage(e.code);
      return null;
    } catch (e) {
      errorMessage.value = e.toString();
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
      
      // Validate email format
      final emailError = _validateEmail(email);
      if (emailError != null) {
        errorMessage.value = emailError;
        return null;
      }
      
      // Basic password check (not empty)
      if (password.isEmpty) {
        errorMessage.value = 'يرجى إدخال كلمة المرور';
        return null;
      }
      
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      return credential.user;
    } on FirebaseException catch (e) {
      errorMessage.value = _getErrorMessage(e.code);
      return null;
    } catch (e) {
      errorMessage.value = e.toString();
      return null;
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Validate email format
  String? _validateEmail(String email) {
    if (email.isEmpty) {
      return 'يرجى إدخال البريد الإلكتروني';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email.trim())) {
      return 'صيغة البريد الإلكتروني غير صحيحة';
    }
    return null;
  }
  
  /// Validate password strength
  String? _validatePassword(String password) {
    if (password.isEmpty) {
      return 'يرجى إدخال كلمة المرور';
    }
    if (password.length < 8) {
      return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
    }
    return null;
  }

  // ============================================================
  // GOOGLE SIGN IN
  // ============================================================
  
  /// Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      // Trigger the Google Sign In flow
      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        errorMessage.value = 'فشل تسجيل الدخول مع قوقل';
        return null;
      }
      
      final googleAuth = await googleUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(credential);
      
      return userCredential.user;
    } catch (e) {
      errorMessage.value = e.toString();
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
      
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseException catch (e) {
      errorMessage.value = _getErrorMessage(e.code);
      return false;
    } catch (e) {
      errorMessage.value = e.toString();
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
      
      await currentUser.value?.updatePassword(newPassword);
      return true;
    } on FirebaseException catch (e) {
      errorMessage.value = _getErrorMessage(e.code);
      return false;
    } catch (e) {
      errorMessage.value = e.toString();
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
      return false;
    }
  }

  /// Update photo URL
  Future<bool> updatePhotoUrl(String photoUrl) async {
    try {
      await currentUser.value?.updatePhotoURL(photoUrl);
      await currentUser.value?.reload();
      currentUser.value = _auth.currentUser;
      return true;
    } catch (e) {
      return false;
    }
  }

  // ============================================================
  // SIGN OUT
  // ============================================================
  
  /// Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      // Handle error
    }
  }

  /// Delete account
  Future<bool> deleteAccount() async {
    try {
      await currentUser.value?.delete();
      return true;
    } on FirebaseException catch (e) {
      errorMessage.value = _getErrorMessage(e.code);
      return false;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    }
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================
  
  /// Get user-friendly error message
  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'لا يوجد حساب بهذا البريد الإلكتروني';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'email-already-in-use':
        return 'البريد الإلكتروني مستخدم مسبقاً';
      case 'weak-password':
        return 'كلمة المرور ضعيفة';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صالح';
      case 'too-many-requests':
        return 'محاولات كثيرة، حاول لاحقاً';
      case 'requires-recent-login':
        return 'يرجى إعادة تسجيل الدخول';
      default:
        return 'حدث خطأ، حاول مرة أخرى';
    }
  }
}
