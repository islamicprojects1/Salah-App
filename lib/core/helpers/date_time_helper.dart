import 'package:intl/intl.dart';
import 'package:get/get.dart';

/// Date and time formatting utilities.
///
/// All methods are locale-aware (Arabic / English) via [Get.locale].
/// Use [toDateKey] as the single canonical date-string format for caches and Firestore.
class DateTimeHelper {
  const DateTimeHelper._();

  // ============================================================
  // DATE FORMATTERS
  // ============================================================

  /// `dd/MM/yyyy` — human-readable display date.
  static String formatDate(DateTime date) =>
      DateFormat('dd/MM/yyyy').format(date);

  /// `yyyy-MM-dd` — canonical storage format. Use for Firestore fields.
  static String formatDateForStorage(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date);

  /// Canonical cache / map key: `yyyy-MM-dd`.
  ///
  /// Faster than [DateFormat] since it avoids the formatter overhead
  /// and guaranteed to match [formatDateForStorage].
  static String toDateKey(DateTime date) =>
      '${date.year}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// Long, localised date: `"الثلاثاء، 3 فبراير 2025"` / `"Tuesday, February 3, 2025"`.
  static String formatDateReadable(DateTime date) {
    if (_isArabic) return DateFormat('EEEE، d MMMM yyyy', 'ar').format(date);
    return DateFormat('EEEE, MMMM d, yyyy').format(date);
  }

  /// Short localised date: `"الثلاثاء، 3 فبراير"` / `"Tuesday, February 3"`.
  static String formatDateShort(DateTime date) {
    if (_isArabic) return DateFormat('EEEE, d MMMM', 'ar').format(date);
    return DateFormat('EEEE, MMMM d').format(date);
  }

  // ============================================================
  // TIME FORMATTERS
  // ============================================================

  /// 12-hour clock with Arabic (`ص`/`م`) or English (`AM`/`PM`) suffix.
  static String formatTime12(DateTime time) {
    if (_isArabic) {
      final hour = time.hour;
      final minute = time.minute.toString().padLeft(2, '0');
      final period = hour < 12 ? 'ص' : 'م';
      final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$hour12:$minute $period';
    }
    return DateFormat('h:mm a').format(time);
  }

  /// Convenience alias — app always uses 12-hour format.
  static String formatTime(DateTime time) => formatTime12(time);

  // ============================================================
  // DURATION FORMATTERS
  // ============================================================

  /// `"Xh Ym"` / `"X ساعة و Y دقيقة"`.
  static String formatDuration(Duration duration) {
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);

    if (_isArabic) {
      if (h > 0 && m > 0) return '$h ساعة و $m دقيقة';
      if (h > 0) return '$h ساعة';
      return '$m دقيقة';
    }
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  /// Zero-padded countdown: `"HH:MM:SS"`.
  static String formatDurationCountdown(Duration duration) {
    final h = duration.inHours.toString().padLeft(2, '0');
    final m = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  /// `"in 2h 5m"` / `"بعد 2:05"` / `"now"` / `"الآن"`.
  static String formatRemainingTime(Duration duration) {
    if (duration.inHours > 0) {
      final h = duration.inHours;
      final m = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
      return _isArabic ? 'بعد $h:$m' : 'in ${h}h ${m}m';
    }
    if (duration.inMinutes > 0) {
      return _isArabic
          ? 'بعد ${duration.inMinutes} دقيقة'
          : 'in ${duration.inMinutes} min';
    }
    return _isArabic ? 'الآن' : 'now';
  }

  // ============================================================
  // RELATIVE TIME
  // ============================================================

  /// Human-friendly elapsed time: `"Just now"` → `"5 min ago"` → `"2 days ago"` → short date.
  static String getRelativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);

    if (diff.inSeconds < 60) return _isArabic ? 'الآن' : 'Just now';
    if (diff.inMinutes < 60) {
      return _isArabic
          ? 'منذ ${diff.inMinutes} دقيقة'
          : '${diff.inMinutes} min ago';
    }
    if (diff.inHours < 24) {
      return _isArabic
          ? 'منذ ${diff.inHours} ساعة'
          : '${diff.inHours} hours ago';
    }
    if (diff.inDays < 7) {
      return _isArabic ? 'منذ ${diff.inDays} يوم' : '${diff.inDays} days ago';
    }
    return formatDateShort(dateTime);
  }

  // ============================================================
  // UTILITY METHODS
  // ============================================================

  /// True if [date1] and [date2] fall on the same calendar day.
  static bool isSameDay(DateTime date1, DateTime date2) =>
      date1.year == date2.year &&
      date1.month == date2.month &&
      date1.day == date2.day;

  /// True if [date] is today.
  static bool isToday(DateTime date) => isSameDay(date, DateTime.now());

  /// True if [date] is yesterday.
  static bool isYesterday(DateTime date) =>
      isSameDay(date, DateTime.now().subtract(const Duration(days: 1)));

  /// Midnight at the start of [date].
  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Last millisecond of [date].
  static DateTime endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

  /// Localised weekday name: `"Monday"` / `"الإثنين"`.
  static String getDayName(DateTime date) =>
      DateFormat('EEEE', _isArabic ? 'ar' : 'en').format(date);

  /// Localised month name: `"January"` / `"يناير"`.
  static String getMonthName(DateTime date) =>
      DateFormat('MMMM', _isArabic ? 'ar' : 'en').format(date);

  // ============================================================
  // PRIVATE
  // ============================================================

  static bool get _isArabic => Get.locale?.languageCode == 'ar';
}
