import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/features/family/data/models/family_model.dart';
import 'package:salah/shared/data/repositories/base_repository.dart';

/// Repository for family-related data operations
class FamilyRepository extends BaseRepository {
  FamilyRepository({required super.firestore});

  /// Create a new family
  Future<FamilyModel> createFamily({
    required String familyName,
    required String creatorId,
    required String creatorName,
  }) async {
    try {
      final inviteCode = _generateInviteCode();

      final family = FamilyModel(
        id: '', // Will be set by Firestore
        name: familyName,
        inviteCode: inviteCode,
        adminId: creatorId,
        members: [
          MemberModel(
            userId: creatorId,
            name: creatorName,
            role: MemberRole.parent,
            joinedAt: DateTime.now(),
          ),
        ],
        createdAt: DateTime.now(),
      );

      final familyId = await firestore.createGroup(family.toFirestore());

      // Return with updated ID
      return FamilyModel(
        id: familyId,
        name: family.name,
        inviteCode: family.inviteCode,
        adminId: family.adminId,
        members: family.members,
        createdAt: family.createdAt,
      );
    } catch (e) {
      throw Exception('Failed to create family: ${handleError(e)}');
    }
  }

  /// Get family by ID
  Future<FamilyModel?> getFamily(String familyId) async {
    try {
      final doc = await firestore.getGroup(familyId);
      if (!doc.exists) return null;

      return FamilyModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get family: ${handleError(e)}');
    }
  }

  /// Get family by invite code (searching through groups)
  Future<FamilyModel?> getFamilyByInviteCode(String inviteCode) async {
    try {
      // Since FirestoreService doesn't have getFamilyByInviteCode,
      // we need to use a stream and get first result
      // final stream = firestore.getUserGroups(''); // This won't work properly
      // For now, return null as placeholder
      return null;
    } catch (e) {
      throw Exception('Failed to find family: ${handleError(e)}');
    }
  }

  /// Add member to family
  Future<void> addMember({
    required String familyId,
    required MemberModel member,
  }) async {
    try {
      final family = await getFamily(familyId);
      if (family == null) {
        throw Exception('Family not found');
      }

      final updatedMembers = [...family.members, member];
      await firestore.updateGroup(familyId, {
        'members': updatedMembers.map((m) => m.toMap()).toList(),
      });
    } catch (e) {
      throw Exception('Failed to add member: ${handleError(e)}');
    }
  }

  /// Get member's today prayer logs
  Stream<QuerySnapshot> getMemberTodayLogs(String userId) {
    return firestore.getTodayPrayerLogs(userId);
  }

  /// Get member data (for streak, etc.)
  Stream<DocumentSnapshot> getMemberData(String userId) {
    return firestore.getUserStream(userId);
  }

  /// Send encouragement/poke using reactions
  Future<void> sendEncouragement({
    required String toUserId,
    required String fromUserId,
    required String fromName,
    required String message,
  }) async {
    try {
      await firestore.addReaction(
        senderId: fromUserId,
        receiverId: toUserId,
        type: 'encouragement',
        prayerName: '',
        message: message,
      );
    } catch (e) {
      throw Exception('Failed to send encouragement: ${handleError(e)}');
    }
  }

  /// Get user notifications (unread reactions)
  Stream<QuerySnapshot> getUserNotifications(String userId) {
    return firestore.getUnreadReactions(userId);
  }

  /// Generate a random 6-character invite code
  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(
      6,
      (index) => chars[(random + index) % chars.length],
    ).join();
  }
}
