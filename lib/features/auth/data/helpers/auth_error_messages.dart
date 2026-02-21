import 'package:get/get.dart';

/// Maps Firebase Auth error codes to user-friendly translated messages.
class AuthErrorMessages {
  AuthErrorMessages._();

  static String fromCode(String code) {
    switch (code) {
      // Sign-in errors
      case 'user-not-found':
      case 'invalid-credential':
        return 'auth_error_user_not_found'.tr;
      case 'wrong-password':
        return 'auth_error_wrong_password'.tr;
      case 'invalid-email':
        return 'auth_error_invalid_email'.tr;
      case 'user-disabled':
        return 'auth_error_user_disabled'.tr;

      // Registration errors
      case 'email-already-in-use':
        return 'auth_error_email_in_use'.tr;
      case 'weak-password':
        return 'auth_error_weak_password'.tr;
      case 'operation-not-allowed':
        return 'auth_error_not_allowed'.tr;

      // Rate limiting
      case 'too-many-requests':
        return 'auth_error_too_many_requests'.tr;

      // Re-auth required
      case 'requires-recent-login':
        return 'auth_error_requires_recent_login'.tr;

      // Network
      case 'network-request-failed':
        return 'auth_error_network'.tr;

      // Google-specific
      case 'account-exists-with-different-credential':
        return 'auth_error_account_exists_different'.tr;

      default:
        return 'auth_error_default'.tr;
    }
  }
}
