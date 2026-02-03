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
      
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name if provided
      if (displayName != null && credential.user != null) {
        await credential.user!.updateDisplayName(displayName);
      }
      
      return credential.user;
    } on FirebaseAuthException catch (e) {
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
      
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      return credential.user;
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _getErrorMessage(e.code);
      return null;
    } catch (e) {
      errorMessage.value = e.toString();
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
      print('DEBUG: Starting Google Sign In flow...');
      isLoading.value = true;
      errorMessage.value = '';
      
      // Trigger the Google Sign In flow
      final googleUser = await _googleSignIn.signIn();
      print('DEBUG: Google Sign In returned: $googleUser');
      
      if (googleUser == null) {
        print('DEBUG: Google Sign In user is null (cancelled or failed silently)');
        errorMessage.value = 'فشل تسجيل الدخول مع قوقل';
        return null;
      }
      
      // Get auth details
      print('DEBUG: Fetching auth details...');
      final googleAuth = await googleUser.authentication;
      print('DEBUG: Auth details fetched');
      
      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(credential);
      
      return userCredential.user;
    } catch (e) {
      print('ERROR: AuthService.signInWithGoogle failed: $e');
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
    } on FirebaseAuthException catch (e) {
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
    } on FirebaseAuthException catch (e) {
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
    } on FirebaseAuthException catch (e) {
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
