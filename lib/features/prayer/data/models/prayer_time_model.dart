import 'package:salah/core/constants/enums.dart';

/// Model representing a prayer time
class PrayerTimeModel {
  final String name;
  final PrayerName prayerType;
  final DateTime dateTime;
  final bool isNotificationEnabled;

  const PrayerTimeModel({
    required this.name,
    required this.prayerType,
    required this.dateTime,
    this.isNotificationEnabled = true,
  });

  PrayerTimeModel copyWith({
    String? name,
    DateTime? dateTime,
    PrayerName? prayerType,
    bool? isNotificationEnabled,
  }) {
    return PrayerTimeModel(
      name: name ?? this.name,
      prayerType: prayerType ?? this.prayerType,
      dateTime: dateTime ?? this.dateTime,
      isNotificationEnabled:
          isNotificationEnabled ?? this.isNotificationEnabled,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PrayerTimeModel &&
        other.name == name &&
        other.dateTime == dateTime &&
        other.isNotificationEnabled == isNotificationEnabled;
  }

  @override
  int get hashCode =>
      name.hashCode ^ dateTime.hashCode ^ isNotificationEnabled.hashCode;

  @override
  String toString() => 'PrayerTimeModel(name: $name, dateTime: $dateTime)';
}
