import 'package:intl/intl.dart';
import 'package:get/get.dart';

/// Helper class for date and time formatting
class DateTimeHelper {
  DateTimeHelper._();

  // ============================================================
  // DATE FORMATTERS
  // ============================================================
  
  /// Format date as "dd/MM/yyyy"
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Format date as "yyyy-MM-dd" (for storage)
  static String formatDateForStorage(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Date key for cache keys and DB (yyyy-MM-dd). Single source for date string format.
  static String toDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Format date as readable string based on locale
  static String formatDateReadable(DateTime date) {
    final isArabic = Get.locale?.languageCode == 'ar';
    if (isArabic) {
      return DateFormat('EEEE، d MMMM yyyy', 'ar').format(date);
    }
    return DateFormat('EEEE, MMMM d, yyyy').format(date);
  }

  /// Format date as short readable (e.g., "الثلاثاء, 3 فبراير")
  static String formatDateShort(DateTime date) {
    final isArabic = Get.locale?.languageCode == 'ar';
    if (isArabic) {
      return DateFormat('EEEE, d MMMM', 'ar').format(date);
    }
    return DateFormat('EEEE, MMMM d').format(date);
  }

  // ============================================================
  // TIME FORMATTERS
  // ============================================================
  
  /// Format time as readable 12-hour format (Standardized)
  static String formatTime24(DateTime time) {
    return formatTime12(time);
  }

  /// Format time as "h:mm a" (12-hour with AM/PM)
  static String formatTime12(DateTime time) {
    final isArabic = Get.locale?.languageCode == 'ar';
    if (isArabic) {
      final hour = time.hour;
      final minute = time.minute.toString().padLeft(2, '0');
      final period = hour < 12 ? 'ص' : 'م';
      final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$hour12:$minute $period';
    }
    return DateFormat('h:mm a').format(time);
  }

  /// Format time based on user preference (Always 12-hour)
  static String formatTime(DateTime time, {bool use24Hour = false}) {
    return formatTime12(time);
  }

  // ============================================================
  // DURATION FORMATTERS
  // ============================================================
  
  /// Format duration as "Xh Ym"
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    final isArabic = Get.locale?.languageCode == 'ar';
    
    if (hours > 0 && minutes > 0) {
      return isArabic 
          ? '$hours ساعة و $minutes دقيقة'
          : '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return isArabic 
          ? '$hours ساعة'
          : '${hours}h';
    } else {
      return isArabic 
          ? '$minutes دقيقة'
          : '${minutes}m';
    }
  }

  /// Format duration as countdown "00:00:00"
  static String formatDurationCountdown(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    return '${hours.toString().padLeft(2, '0')}:'
           '${minutes.toString().padLeft(2, '0')}:'
           '${seconds.toString().padLeft(2, '0')}';
  }

  /// Format remaining time in human-readable format
  static String formatRemainingTime(Duration duration) {
    final isArabic = Get.locale?.languageCode == 'ar';
    
    if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      return isArabic
          ? 'بعد $hours:${minutes.toString().padLeft(2, '0')}'
          : 'in ${hours}h ${minutes}m';
    } else if (duration.inMinutes > 0) {
      return isArabic
          ? 'بعد ${duration.inMinutes} دقيقة'
          : 'in ${duration.inMinutes} min';
    } else {
      return isArabic ? 'الآن' : 'now';
    }
  }

  // ============================================================
  // RELATIVE TIME
  // ============================================================
  
  /// Get relative time description (e.g., "منذ 5 دقائق")
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    final isArabic = Get.locale?.languageCode == 'ar';
    
    if (difference.inSeconds < 60) {
      return isArabic ? 'الآن' : 'Just now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return isArabic ? 'منذ $mins دقيقة' : '$mins min ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return isArabic ? 'منذ $hours ساعة' : '$hours hours ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return isArabic ? 'منذ $days يوم' : '$days days ago';
    } else {
      return formatDateShort(dateTime);
    }
  }

  // ============================================================
  // UTILITY METHODS
  // ============================================================
  
  /// Check if two dates are the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  /// Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }

  /// Get start of day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Get end of day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  /// Get day name
  static String getDayName(DateTime date) {
    final isArabic = Get.locale?.languageCode == 'ar';
    return DateFormat('EEEE', isArabic ? 'ar' : 'en').format(date);
  }

  /// Get month name
  static String getMonthName(DateTime date) {
    final isArabic = Get.locale?.languageCode == 'ar';
    return DateFormat('MMMM', isArabic ? 'ar' : 'en').format(date);
  }
}
