/// Central validation and sanitisation for user-facing inputs.
///
/// Use in form fields (`validator:` callback) and in repositories
/// before writing to Firestore.
///
/// Every method returns a `(sanitisedValue, errorMessage)` record:
/// - On success: `(value, null)`
/// - On failure: `(null, 'localised error string')`
class InputValidators {
  const InputValidators._();

  // ============================================================
  // CONSTRAINTS
  // ============================================================

  static const int maxDisplayNameLength = 64;
  static const int maxFamilyNameLength = 64;
  static const int inviteCodeLength = 6;
  static final DateTime _minBirthDate = DateTime(1900);
  static final _alphanumeric = RegExp(r'^[A-Z0-9]+$');

  // ============================================================
  // NAME VALIDATORS
  // ============================================================

  /// Validates a user display name.
  ///
  /// Returns the trimmed name on success, or an Arabic error message.
  static (String?, String?) displayName(String? raw) =>
      _validateName(raw, maxDisplayNameLength, 'الرجاء إدخال الاسم');

  /// Validates a family/group name.
  static (String?, String?) familyName(String? raw) => _validateName(
    raw,
    maxFamilyNameLength,
    'الرجاء إدخال اسم العائلة',
    emptyError: 'الرجاء إدخال اسم العائلة',
    tooLongError: 'اسم العائلة يجب ألا يتجاوز $maxFamilyNameLength حرفاً',
  );

  // ============================================================
  // INVITE CODE
  // ============================================================

  /// Validates an invite code: exactly [inviteCodeLength] alphanumeric characters.
  /// Returns the uppercased code on success.
  static (String?, String?) inviteCode(String? raw) {
    final s = (raw?.trim() ?? '').toUpperCase();
    if (s.length != inviteCodeLength) {
      return (null, 'كود الدعوة يجب أن يتكون من $inviteCodeLength أرقام/حروف');
    }
    if (!_alphanumeric.hasMatch(s)) {
      return (null, 'كود الدعوة يجب أن يحتوي على أرقام وحروف فقط');
    }
    return (s, null);
  }

  // ============================================================
  // BIRTH DATE
  // ============================================================

  /// Validates a birth date: must be set, not in the future, not before 1900.
  /// Returns `null` on success (no sanitised value needed — the caller already has the DateTime).
  static String? birthDate(DateTime? date) {
    if (date == null) return 'الرجاء اختيار تاريخ الميلاد';

    final today = _startOfDay(DateTime.now());
    final d = _startOfDay(date);

    if (d.isAfter(today)) return 'تاريخ الميلاد لا يمكن أن يكون في المستقبل';
    if (d.isBefore(_minBirthDate)) return 'تاريخ الميلاد غير صالح';
    return null;
  }

  // ============================================================
  // PRIVATE HELPERS
  // ============================================================

  static (String?, String?) _validateName(
    String? raw,
    int maxLength,
    String emptyMsg, {
    String? emptyError,
    String? tooLongError,
  }) {
    final s = raw?.trim() ?? '';
    if (s.isEmpty) return (null, emptyError ?? emptyMsg);
    if (s.length > maxLength) {
      return (null, tooLongError ?? 'الاسم يجب ألا يتجاوز $maxLength حرفاً');
    }
    return (s, null);
  }

  static DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  // ============================================================
  // DEPRECATED ALIASES (remove after refactor sweep)
  // ============================================================

  @Deprecated('Use InputValidators.displayName()')
  static (String?, String?) validateDisplayName(String? raw) =>
      displayName(raw);

  @Deprecated('Use InputValidators.familyName()')
  static (String?, String?) validateFamilyName(String? raw) => familyName(raw);

  @Deprecated('Use InputValidators.inviteCode()')
  static (String?, String?) validateInviteCode(String? raw) => inviteCode(raw);

  @Deprecated('Use InputValidators.birthDate()')
  static String? validateBirthDate(DateTime? date) => birthDate(date);
}
