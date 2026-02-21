import 'package:get/get.dart';

/// Validation helpers for auth inputs.
/// Returns translated error messages or null if valid.
class AuthValidation {
  AuthValidation._();

  static String? validateEmail(String email) {
    if (email.trim().isEmpty) return 'enter_email'.tr;
    final emailRegex = RegExp(r'^[\w\-\.+]+@([\w-]+\.)+[\w-]{2,}$');
    if (!emailRegex.hasMatch(email.trim())) return 'invalid_email'.tr;
    return null;
  }

  static String? validatePassword(String password) {
    if (password.isEmpty) return 'enter_password'.tr;
    if (password.length < 6) return 'password_min_length'.tr;
    return null;
  }

  /// Stricter password for registration (optional — use for register flow)
  static String? validateStrongPassword(String password) {
    if (password.isEmpty) return 'enter_password'.tr;
    if (password.length < 8) return 'password_min_8'.tr;
    // Optionally require at least 1 digit
    // if (!RegExp(r'\d').hasMatch(password)) return 'password_needs_number'.tr;
    return null;
  }

  static String? validateName(String? name) {
    if (name == null || name.trim().isEmpty) return 'enter_name'.tr;
    if (name.trim().length < 2) return 'name_min_length'.tr;
    if (name.trim().length > 50) return 'name_max_length'.tr;
    return null;
  }
}
