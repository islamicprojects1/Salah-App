import 'package:cloud_firestore/cloud_firestore.dart';

/// Gender enum
enum Gender { male, female }

/// User model for Firestore
class UserModel {
  final String id;
  final String name;
  final DateTime birthDate;
  final Gender gender;
  final String? email;
  final String? photoUrl;
  final String? fcmToken;
  final String language; // 'ar' or 'en'
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Group references
  final String? familyId;
  final List<String> groupIds;

  UserModel({
    required this.id,
    required this.name,
    required this.birthDate,
    required this.gender,
    this.email,
    this.photoUrl,
    this.fcmToken,
    this.language = 'ar',
    required this.createdAt,
    this.updatedAt,
    this.familyId,
    this.groupIds = const [],
  });

  /// Calculate age from birth date
  int get age {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// Check if user is accountable for prayer (typically 7+ years for practice, 10+ for accountability)
  bool get isAccountable => age >= 10;

  /// Create from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      birthDate: (data['birthDate'] as Timestamp).toDate(),
      gender: data['gender'] == 'male' ? Gender.male : Gender.female,
      email: data['email'],
      photoUrl: data['photoUrl'],
      fcmToken: data['fcmToken'],
      language: data['language'] ?? 'ar',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      familyId: data['familyId'],
      groupIds: List<String>.from(data['groupIds'] ?? []),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'birthDate': Timestamp.fromDate(birthDate),
      'gender': gender == Gender.male ? 'male' : 'female',
      'email': email,
      'photoUrl': photoUrl,
      'fcmToken': fcmToken,
      'language': language,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'familyId': familyId,
      'groupIds': groupIds,
    };
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    String? name,
    DateTime? birthDate,
    Gender? gender,
    String? email,
    String? photoUrl,
    String? fcmToken,
    String? language,
    DateTime? updatedAt,
    String? familyId,
    List<String>? groupIds,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      language: language ?? this.language,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      familyId: familyId ?? this.familyId,
      groupIds: groupIds ?? this.groupIds,
    );
  }
}
