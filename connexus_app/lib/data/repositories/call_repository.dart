import 'package:flutter/foundation.dart';

import '../../domain/models/call_record.dart';
import '../datasources/local/call_local_datasource.dart';
import '../datasources/remote/call_remote_datasource.dart';

/// Repository for managing call records.
class CallRepository {
  final CallLocalDataSource _localDataSource;
  final CallRemoteDataSource _remoteDataSource;

  CallRepository({
    required CallLocalDataSource localDataSource,
    required CallRemoteDataSource remoteDataSource,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource;

  /// Saves a call record locally and attempts to sync it to the backend.
  Future<void> saveCallRecord(CallRecord record) async {
    try {
      // Save locally first (fast, reliable).
      await _localDataSource.saveCallRecord(record);
      debugPrint('CallRepository: Saved call record locally');

      // Sync to remote (can fail without affecting local).
      try {
        await _remoteDataSource.syncCallRecord(record);
        debugPrint('CallRepository: Synced call record to remote');
      } catch (e) {
        debugPrint('CallRepository: Remote sync failed: $e');
        // Queue for later sync.
        await _localDataSource.markForSync(record.id);
      }
    } catch (e) {
      debugPrint('CallRepository: Error saving call record: $e');
      rethrow;
    }
  }

  /// Gets recent call records.
  Future<List<CallRecord>> getRecentCalls({int limit = 50}) async {
    try {
      return _localDataSource.getRecentCalls(limit: limit);
    } catch (e) {
      debugPrint('CallRepository: Error getting recent calls: $e');
      return <CallRecord>[];
    }
  }

  /// Gets calls by status.
  Future<List<CallRecord>> getCallsByStatus(CallStatus status) async {
    try {
      return _localDataSource.getCallsByStatus(status);
    } catch (e) {
      debugPrint('CallRepository: Error getting calls by status: $e');
      return <CallRecord>[];
    }
  }
}


