import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';

/// Base repository interface for all repositories
abstract class BaseRepository {
  /// Get current user authentication status
  Future<bool> get isAuthenticated;
  
  /// Clear all cached data for this repository
  Future<void> clearCache();
}

/// Type definition for Either result type
typedef FailureOr<T> = Either<Failure, T>;


