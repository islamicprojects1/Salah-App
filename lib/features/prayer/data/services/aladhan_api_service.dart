import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:salah/core/constants/aladhan_constants.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/error/app_logger.dart';
import 'package:salah/core/helpers/prayer_names.dart';
import 'package:salah/features/prayer/data/models/prayer_time_model.dart';

/// Fetches prayer times from Aladhan API.
///
/// Calendar endpoint returns full month in one call.
/// Used by [PrayerTimeService] when online.
class AladhanApiService {
  static const _timeout = Duration(seconds: 15);

  /// Fetch prayer times for a full month.
  ///
  /// [latitude], [longitude] — user location
  /// [month], [year] — 1-based month, full year
  /// [method] — Aladhan method ID (e.g. 23 for Jordan)
  ///
  /// Returns list of (dateKey, List<PrayerTimeModel>) for each day.
  /// Empty list on failure.
  Future<Map<String, List<PrayerTimeModel>>> fetchMonth({
    required double latitude,
    required double longitude,
    required int month,
    required int year,
    required int method,
  }) async {
    try {
      final uri = Uri.parse('$aladhanBaseUrl/calendar').replace(
        queryParameters: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'month': month.toString(),
          'year': year.toString(),
          'method': method.toString(),
        },
      );

      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode != 200) {
        AppLogger.warning(
          'Aladhan API calendar failed',
          'status=${response.statusCode}',
        );
        return {};
      }

      final body = json.decode(response.body) as Map<String, dynamic>;
      final data = body['data'] as List<dynamic>?;
      if (data == null || data.isEmpty) return {};

      final result = <String, List<PrayerTimeModel>>{};

      for (final day in data) {
        final dayMap = day as Map<String, dynamic>;
        final date = dayMap['date'] as Map<String, dynamic>?;
        final gregorian = date?['gregorian'] as Map<String, dynamic>?;
        final dateStr = gregorian?['date'] as String?; // DD-MM-YYYY
        final timings = dayMap['timings'] as Map<String, dynamic>?;
        if (dateStr == null || timings == null) continue;

        final dateKey = _parseDateKey(dateStr);
        if (dateKey == null) continue;

        final list = _parseTimingsToModels(timings, dateKey);
        if (list.isNotEmpty) result[dateKey] = list;
      }

      return result;
    } catch (e, st) {
      AppLogger.error('AladhanApiService.fetchMonth failed', e, st);
      return {};
    }
  }

  /// Parse DD-MM-YYYY to yyyy-MM-dd
  String? _parseDateKey(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length != 3) return null;
    final day = parts[0].padLeft(2, '0');
    final month = parts[1].padLeft(2, '0');
    final year = parts[2];
    return '$year-$month-$day';
  }

  /// Parse API timings (e.g. "05:51 (GMT+2)") to List<PrayerTimeModel>
  List<PrayerTimeModel> _parseTimingsToModels(
    Map<String, dynamic> timings,
    String dateKey,
  ) {
    final parts = dateKey.split('-');
    if (parts.length != 3) return [];
    final year = int.tryParse(parts[0]) ?? 0;
    final month = int.tryParse(parts[1]) ?? 0;
    final day = int.tryParse(parts[2]) ?? 0;
    if (year == 0 || month == 0 || day == 0) return [];

    DateTime parseTime(String value) {
      final t = (value as String).split(' ').first.trim();
      final hm = t.split(':');
      if (hm.length < 2) return DateTime(year, month, day);
      final h = int.tryParse(hm[0]) ?? 0;
      final m = int.tryParse(hm[1]) ?? 0;
      return DateTime(year, month, day, h, m);
    }

    final list = <PrayerTimeModel>[];
    const keys = ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    const prayers = [
      PrayerName.fajr,
      PrayerName.sunrise,
      PrayerName.dhuhr,
      PrayerName.asr,
      PrayerName.maghrib,
      PrayerName.isha,
    ];

    for (var i = 0; i < keys.length; i++) {
      final raw = timings[keys[i]];
      if (raw == null) continue;
      final prayer = prayers[i];
      final dt = parseTime(raw.toString());
      list.add(
        PrayerTimeModel(
          name: PrayerNames.displayName(prayer),
          dateTime: dt,
          prayerType: prayer,
          isNotificationEnabled: prayer != PrayerName.sunrise,
        ),
      );
    }

    list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return list;
  }
}
