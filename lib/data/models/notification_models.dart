import 'package:cloud_firestore/cloud_firestore.dart';

/// Notification action type enum
enum NotificationActionType {
  prayNow,          // تسجيل الصلاة
  snooze5,          // تذكير بعد 5 دقائق
  snooze10,         // تذكير بعد 10 دقائق
  snooze15,         // تذكير بعد 15 دقائق
  markMissed,       // تسجيل فاتتني
  confirmPrayed,    // تأكيد صليت
  willPrayNow,      // سأصلي الآن
  dismiss,          // إغلاق
}

/// Notification action model
class NotificationActionModel {
  final String id;
  final String label;
  final String labelEn;
  final NotificationActionType type;
  final String? icon;

  NotificationActionModel({
    required this.id,
    required this.label,
    required this.labelEn,
    required this.type,
    this.icon,
  });

  /// Get localized label
  String getLocalizedLabel(String language) {
    return language == 'ar' ? label : labelEn;
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'labelEn': labelEn,
      'type': type.name,
      'icon': icon,
    };
  }

  /// Create from map
  factory NotificationActionModel.fromMap(Map<String, dynamic> map) {
    return NotificationActionModel(
      id: map['id'] ?? '',
      label: map['label'] ?? '',
      labelEn: map['labelEn'] ?? '',
      type: _parseType(map['type']),
      icon: map['icon'],
    );
  }

  static NotificationActionType _parseType(String? type) {
    switch (type) {
      case 'prayNow':
        return NotificationActionType.prayNow;
      case 'snooze5':
        return NotificationActionType.snooze5;
      case 'snooze10':
        return NotificationActionType.snooze10;
      case 'snooze15':
        return NotificationActionType.snooze15;
      case 'markMissed':
        return NotificationActionType.markMissed;
      case 'confirmPrayed':
        return NotificationActionType.confirmPrayed;
      case 'willPrayNow':
        return NotificationActionType.willPrayNow;
      default:
        return NotificationActionType.dismiss;
    }
  }
}

/// Default notification actions
class DefaultNotificationActions {
  /// Prayer time notification actions
  static List<NotificationActionModel> get prayerTimeActions => [
    NotificationActionModel(
      id: 'pray_now',
      label: '✅ صليت',
      labelEn: '✅ Prayed',
      type: NotificationActionType.prayNow,
      icon: 'check',
    ),
    NotificationActionModel(
      id: 'snooze_5',
      label: '⏰ 5 دقائق',
      labelEn: '⏰ 5 minutes',
      type: NotificationActionType.snooze5,
      icon: 'snooze',
    ),
    NotificationActionModel(
      id: 'mark_missed',
      label: '❌ فاتتني',
      labelEn: '❌ Missed',
      type: NotificationActionType.markMissed,
      icon: 'close',
    ),
  ];

  /// Reminder notification actions (30 min after)
  static List<NotificationActionModel> get reminderActions => [
    NotificationActionModel(
      id: 'confirm_prayed',
      label: '✅ نعم صليت',
      labelEn: '✅ Yes, I prayed',
      type: NotificationActionType.confirmPrayed,
      icon: 'check',
    ),
    NotificationActionModel(
      id: 'will_pray_now',
      label: '🕌 سأصلي الآن',
      labelEn: '🕌 Will pray now',
      type: NotificationActionType.willPrayNow,
      icon: 'mosque',
    ),
  ];
}

/// User prayer pattern model (for smart reminders)
class UserPrayerPattern {
  final String id;
  final String userId;
  final String prayerName;
  final double avgDelayMinutes;     // متوسط التأخير بالدقائق
  final double confidence;          // مستوى الثقة (0-1)
  final int dataPoints;             // عدد نقاط البيانات
  final DateTime lastUpdated;

  UserPrayerPattern({
    required this.id,
    required this.userId,
    required this.prayerName,
    required this.avgDelayMinutes,
    required this.confidence,
    required this.dataPoints,
    required this.lastUpdated,
  });

  /// Create from Firestore document
  factory UserPrayerPattern.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserPrayerPattern(
      id: doc.id,
      userId: data['userId'] ?? '',
      prayerName: data['prayerName'] ?? '',
      avgDelayMinutes: (data['avgDelayMinutes'] ?? 0).toDouble(),
      confidence: (data['confidence'] ?? 0).toDouble(),
      dataPoints: data['dataPoints'] ?? 0,
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'prayerName': prayerName,
      'avgDelayMinutes': avgDelayMinutes,
      'confidence': confidence,
      'dataPoints': dataPoints,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  /// Get optimal reminder time offset
  Duration getOptimalReminderOffset() {
    if (confidence < 0.5 || dataPoints < 5) {
      return Duration.zero; // Not enough data
    }
    
    // Remind 5 minutes before their usual prayer time
    final reminderOffset = (avgDelayMinutes - 5).clamp(0, 60);
    return Duration(minutes: reminderOffset.toInt());
  }
}

/// Report model (for admin panel)
class ReportModel {
  final String id;
  final ReportType type;
  final String reporterId;
  final String? reportedUserId;
  final String? reportedContentId;
  final String title;
  final String description;
  final ReportStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final String? resolution;

  ReportModel({
    required this.id,
    required this.type,
    required this.reporterId,
    this.reportedUserId,
    this.reportedContentId,
    required this.title,
    required this.description,
    this.status = ReportStatus.pending,
    required this.createdAt,
    this.resolvedAt,
    this.resolvedBy,
    this.resolution,
  });

  /// Create from Firestore document
  factory ReportModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ReportModel(
      id: doc.id,
      type: _parseReportType(data['type']),
      reporterId: data['reporterId'] ?? '',
      reportedUserId: data['reportedUserId'],
      reportedContentId: data['reportedContentId'],
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      status: _parseReportStatus(data['status']),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      resolvedAt: data['resolvedAt'] != null
          ? (data['resolvedAt'] as Timestamp).toDate()
          : null,
      resolvedBy: data['resolvedBy'],
      resolution: data['resolution'],
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'type': type.name,
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'reportedContentId': reportedContentId,
      'title': title,
      'description': description,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'resolvedBy': resolvedBy,
      'resolution': resolution,
    };
  }

  static ReportType _parseReportType(String? type) {
    switch (type) {
      case 'userReport':
        return ReportType.userReport;
      case 'bugReport':
        return ReportType.bugReport;
      case 'featureRequest':
        return ReportType.featureRequest;
      case 'contentReport':
        return ReportType.contentReport;
      default:
        return ReportType.other;
    }
  }

  static ReportStatus _parseReportStatus(String? status) {
    switch (status) {
      case 'pending':
        return ReportStatus.pending;
      case 'inProgress':
        return ReportStatus.inProgress;
      case 'resolved':
        return ReportStatus.resolved;
      case 'dismissed':
        return ReportStatus.dismissed;
      default:
        return ReportStatus.pending;
    }
  }
}

/// Report type enum
enum ReportType {
  userReport,       // بلاغ عن مستخدم
  bugReport,        // بلاغ عن خلل
  featureRequest,   // طلب ميزة
  contentReport,    // بلاغ عن محتوى
  other,            // أخرى
}

/// Report status enum
enum ReportStatus {
  pending,      // قيد الانتظار
  inProgress,   // جارٍ المراجعة
  resolved,     // تم الحل
  dismissed,    // مرفوض
}
