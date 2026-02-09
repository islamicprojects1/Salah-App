import 'package:cloud_firestore/cloud_firestore.dart';

enum ActivityType {
  prayerLog,
  streakAchievement,
  encouragement,
  joinedFamily,
}

class FamilyActivityModel {
  final String id;
  final ActivityType type;
  final String userId;
  final String userName;
  final String? userPhoto;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  FamilyActivityModel({
    required this.id,
    required this.type,
    required this.userId,
    required this.userName,
    this.userPhoto,
    required this.timestamp,
    required this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'userId': userId,
      'userName': userName,
      'userPhoto': userPhoto,
      'timestamp': Timestamp.fromDate(timestamp),
      'data': data,
    };
  }

  factory FamilyActivityModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FamilyActivityModel(
      id: doc.id,
      type: ActivityType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ActivityType.prayerLog,
      ),
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown',
      userPhoto: data['userPhoto'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      data: data['data'] as Map<String, dynamic>? ?? {},
    );
  }
}
