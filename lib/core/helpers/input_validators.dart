/// Central validation and sanitization for user inputs.
/// Use in UI and in repositories before writing to Firestore.
class InputValidators {
  InputValidators._();

  static const int maxDisplayNameLength = 64;
  static const int maxFamilyNameLength = 64;
  static const int inviteCodeLength = 6;

  /// Returns trimmed name and null, or (null, error message).
  static (String?, String?) validateDisplayName(String? raw) {
    final s = raw?.trim() ?? '';
    if (s.isEmpty) return (null, 'الرجاء إدخال الاسم');
    if (s.length > maxDisplayNameLength) {
      return (null, 'الاسم يجب ألا يتجاوز $maxDisplayNameLength حرفاً');
    }
    return (s, null);
  }

  /// Returns trimmed family name and null, or (null, error message).
  static (String?, String?) validateFamilyName(String? raw) {
    final s = raw?.trim() ?? '';
    if (s.isEmpty) return (null, 'الرجاء إدخال اسم العائلة');
    if (s.length > maxFamilyNameLength) {
      return (null, 'اسم العائلة يجب ألا يتجاوز $maxFamilyNameLength حرفاً');
    }
    return (s, null);
  }

  /// Invite code: exactly [inviteCodeLength] alphanumeric characters (case-insensitive).
  static (String?, String?) validateInviteCode(String? raw) {
    final s = (raw?.trim() ?? '').toUpperCase();
    if (s.length != inviteCodeLength) {
      return (null, 'كود الدعوة يجب أن يتكون من $inviteCodeLength أرقام/حروف');
    }
    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(s)) {
      return (null, 'كود الدعوة يجب أن يحتوي على أرقام وحروف فقط');
    }
    return (s, null);
  }

  /// Birth date: not in future; optionally clamp to reasonable range (e.g. 1900–today).
  static String? validateBirthDate(DateTime? date) {
    if (date == null) return 'الرجاء اختيار تاريخ الميلاد';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d.isAfter(today)) return 'تاريخ الميلاد لا يمكن أن يكون في المستقبل';
    final minDate = DateTime(1900, 1, 1);
    if (d.isBefore(minDate)) return 'تاريخ الميلاد غير صالح';
    return null;
  }
}
