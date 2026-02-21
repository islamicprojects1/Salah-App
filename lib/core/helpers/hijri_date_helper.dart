import 'package:get/get.dart';

/// Hijri (Islamic) calendar calculations and formatting.
///
/// Conversion uses the standard Julian Day Number algorithm.
/// Accuracy is ±1 day depending on moon sighting — suitable for display,
/// not for legal/religious determination.
class HijriDateHelper {
  const HijriDateHelper._();

  // ============================================================
  // MONTH NAMES
  // ============================================================

  static const List<String> _monthsAr = [
    'محرم',
    'صفر',
    'ربيع الأول',
    'ربيع الثاني',
    'جمادى الأولى',
    'جمادى الآخرة',
    'رجب',
    'شعبان',
    'رمضان',
    'شوال',
    'ذو القعدة',
    'ذو الحجة',
  ];

  static const List<String> _monthsEn = [
    'Muharram',
    'Safar',
    "Rabi' al-Awwal",
    "Rabi' al-Thani",
    'Jumada al-Awwal',
    'Jumada al-Thani',
    'Rajab',
    "Sha'ban",
    'Ramadan',
    'Shawwal',
    "Dhu al-Qi'dah",
    'Dhu al-Hijjah',
  ];

  // ============================================================
  // PUBLIC API
  // ============================================================

  /// Converts a Gregorian [date] to its Hijri equivalent.
  /// Returns a record `(day, month, year)`.
  static ({int day, int month, int year}) toHijri(DateTime date) {
    final jd = _gregorianToJulian(date.year, date.month, date.day);
    return _julianToHijri(jd);
  }

  /// Full localised Hijri date string.
  ///
  /// Arabic: `"3 رمضان 1446"` — English: `"Ramadan 3, 1446"`.
  static String format(DateTime date) {
    final h = toHijri(date);
    final monthName = _monthName(h.month);
    return _isArabic
        ? '${h.day} $monthName ${h.year}'
        : '$monthName ${h.day}, ${h.year}';
  }

  /// Short Hijri string without the day: `"رمضان 1446"` / `"Ramadan 1446"`.
  static String formatShort(DateTime date) {
    final h = toHijri(date);
    return '${_monthName(h.month)} ${h.year}';
  }

  /// Localised Hijri month name for [month] (1–12).
  /// Returns an empty string for out-of-range values.
  static String monthName(int month) =>
      (month >= 1 && month <= 12) ? _monthName(month) : '';

  /// True if today falls in Ramadan (month 9).
  static bool get isRamadan => toHijri(DateTime.now()).month == 9;

  /// True if today falls in Dhul Hijjah (month 12).
  static bool get isDhulHijjah => toHijri(DateTime.now()).month == 12;

  /// Days remaining in the current Hijri month (0 on the last day).
  static int get daysRemainingInMonth {
    final now = DateTime.now();
    final h = toHijri(now);
    return _daysInMonth(h.month, h.year) - h.day;
  }

  // ============================================================
  // PRIVATE — CALCULATIONS
  // ============================================================

  static int _gregorianToJulian(int year, int month, int day) {
    if (month <= 2) {
      year -= 1;
      month += 12;
    }
    final a = year ~/ 100;
    final b = 2 - a + a ~/ 4;
    return (365.25 * (year + 4716)).floor() +
        (30.6001 * (month + 1)).floor() +
        day +
        b -
        1524;
  }

  static ({int day, int month, int year}) _julianToHijri(int jd) {
    int l = jd - 1948440 + 10632;
    final n = (l - 1) ~/ 10631;
    l = l - 10631 * n + 354;

    final j =
        (((10985 - l) ~/ 5316) * ((50 * l) ~/ 17719)) +
        ((l ~/ 5670) * ((43 * l) ~/ 15238));
    l =
        l -
        (((30 - j) ~/ 15) * ((17719 * j) ~/ 50)) -
        ((j ~/ 16) * ((15238 * j) ~/ 43)) +
        29;

    final month = (24 * l) ~/ 709;
    final day = l - (709 * month) ~/ 24;
    final year = 30 * n + j - 30;

    return (day: day, month: month, year: year);
  }

  /// Days in a Hijri month (29 or 30).
  /// Odd months = 30 days; even months = 29 days,
  /// except month 12 in a leap year = 30 days.
  static int _daysInMonth(int month, int year) {
    if (month % 2 == 1) return 30;
    if (month == 12 && _isLeapYear(year)) return 30;
    return 29;
  }

  /// Hijri leap years follow an 11-in-30 cycle.
  static bool _isLeapYear(int year) {
    const leapRemainders = {2, 5, 7, 10, 13, 16, 18, 21, 24, 26, 29};
    return leapRemainders.contains(year % 30);
  }

  static String _monthName(int month) =>
      _isArabic ? _monthsAr[month - 1] : _monthsEn[month - 1];

  static bool get _isArabic => Get.locale?.languageCode == 'ar';
}
