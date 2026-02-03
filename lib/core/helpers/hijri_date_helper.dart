import 'package:get/get.dart';

/// Helper class for Hijri (Islamic) calendar calculations
class HijriDateHelper {
  HijriDateHelper._();

  /// Hijri month names in Arabic
  static const List<String> _monthsArabic = [
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

  /// Hijri month names in English
  static const List<String> _monthsEnglish = [
    'Muharram',
    'Safar',
    'Rabi\' al-Awwal',
    'Rabi\' al-Thani',
    'Jumada al-Awwal',
    'Jumada al-Thani',
    'Rajab',
    'Sha\'ban',
    'Ramadan',
    'Shawwal',
    'Dhu al-Qi\'dah',
    'Dhu al-Hijjah',
  ];

  /// Convert Gregorian date to Hijri
  /// Returns a map with 'day', 'month', 'year' keys
  static Map<String, int> gregorianToHijri(DateTime gregorian) {
    // Julian Day Number calculation
    int jd = _gregorianToJulian(
      gregorian.year,
      gregorian.month,
      gregorian.day,
    );
    
    return _julianToHijri(jd);
  }

  /// Get formatted Hijri date string
  static String getHijriDateString(DateTime gregorian) {
    final hijri = gregorianToHijri(gregorian);
    final isArabic = Get.locale?.languageCode == 'ar';
    
    final day = hijri['day']!;
    final month = hijri['month']!;
    final year = hijri['year']!;
    
    final monthName = isArabic 
        ? _monthsArabic[month - 1]
        : _monthsEnglish[month - 1];
    
    if (isArabic) {
      return '$day $monthName $year';
    }
    return '$monthName $day, $year';
  }

  /// Get Hijri month name
  static String getHijriMonthName(int month) {
    final isArabic = Get.locale?.languageCode == 'ar';
    if (month < 1 || month > 12) return '';
    return isArabic ? _monthsArabic[month - 1] : _monthsEnglish[month - 1];
  }

  /// Get short Hijri date (e.g., "رجب 1447" or "Rajab 1447")
  static String getHijriDateShort(DateTime gregorian) {
    final hijri = gregorianToHijri(gregorian);
    final isArabic = Get.locale?.languageCode == 'ar';
    
    final month = hijri['month']!;
    final year = hijri['year']!;
    
    final monthName = isArabic 
        ? _monthsArabic[month - 1]
        : _monthsEnglish[month - 1];
    
    return '$monthName $year';
  }

  /// Check if current date is in Ramadan
  static bool isRamadan() {
    final hijri = gregorianToHijri(DateTime.now());
    return hijri['month'] == 9;
  }

  /// Check if current date is in Dhul Hijjah
  static bool isDhulHijjah() {
    final hijri = gregorianToHijri(DateTime.now());
    return hijri['month'] == 12;
  }

  /// Get days remaining in current Hijri month
  static int getDaysRemainingInMonth() {
    final now = DateTime.now();
    final hijri = gregorianToHijri(now);
    final daysInMonth = _getHijriMonthDays(hijri['month']!, hijri['year']!);
    return daysInMonth - hijri['day']!;
  }

  // ============================================================
  // PRIVATE CALCULATION METHODS
  // ============================================================
  
  /// Convert Gregorian date to Julian Day Number
  static int _gregorianToJulian(int year, int month, int day) {
    if (month <= 2) {
      year -= 1;
      month += 12;
    }
    
    int a = (year / 100).floor();
    int b = 2 - a + (a / 4).floor();
    
    return (365.25 * (year + 4716)).floor() +
           (30.6001 * (month + 1)).floor() +
           day + b - 1524;
  }

  /// Convert Julian Day Number to Hijri date
  static Map<String, int> _julianToHijri(int jd) {
    int l = jd - 1948440 + 10632;
    int n = ((l - 1) / 10631).floor();
    l = l - 10631 * n + 354;
    
    int j = (((10985 - l) / 5316).floor() * ((50 * l) / 17719).floor()) +
            ((l / 5670).floor() * ((43 * l) / 15238).floor());
    l = l - (((30 - j) / 15).floor() * ((17719 * j) / 50).floor()) -
            ((j / 16).floor() * ((15238 * j) / 43).floor()) + 29;
    
    int month = ((24 * l) / 709).floor();
    int day = l - ((709 * month) / 24).floor();
    int year = 30 * n + j - 30;
    
    return {
      'day': day,
      'month': month,
      'year': year,
    };
  }

  /// Get number of days in a Hijri month
  static int _getHijriMonthDays(int month, int year) {
    // Odd months have 30 days, even months have 29 days
    // Exception: 12th month has 30 days in leap years
    if (month % 2 == 1) {
      return 30;
    } else if (month == 12 && _isHijriLeapYear(year)) {
      return 30;
    }
    return 29;
  }

  /// Check if Hijri year is a leap year
  static bool _isHijriLeapYear(int year) {
    // Hijri calendar has 11 leap years in a 30-year cycle
    // Leap years: 2, 5, 7, 10, 13, 16, 18, 21, 24, 26, 29
    int yearInCycle = year % 30;
    return [2, 5, 7, 10, 13, 16, 18, 21, 24, 26, 29].contains(yearInCycle);
  }
}
