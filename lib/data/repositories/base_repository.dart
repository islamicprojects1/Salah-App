import 'package:salah/core/services/firestore_service.dart';

/// Base repository class with common operations
/// All repositories should extend this class
abstract class BaseRepository {
  final FirestoreService firestore;

  BaseRepository({required this.firestore});

  /// Override this to provide repository-specific error handling
  String handleError(dynamic error) {
    return error.toString();
  }
}
