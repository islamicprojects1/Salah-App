// ignore_for_file: avoid_print
/// One-time script to backfill memberIds for families that only have members[].
///
/// Run with: dart run scripts/backfill_family_member_ids.dart
///
/// Requires:
/// 1. Firebase Admin SDK (firebase-admin) - typically run from Node.js, OR
/// 2. Service account key at GOOGLE_APPLICATION_CREDENTIALS
///
/// For Flutter/Dart projects, you'd typically run this as a Node.js script
/// using firebase-admin. This file documents the logic:
///
/// For each doc in families collection:
///   if (!doc.memberIds || doc.memberIds.length === 0) {
///     const memberIds = (doc.members || []).map(m => m.userId).filter(Boolean);
///     await doc.ref.update({ memberIds });
///   }
///
/// See scripts/backfill_family_member_ids.js for Node.js implementation.
