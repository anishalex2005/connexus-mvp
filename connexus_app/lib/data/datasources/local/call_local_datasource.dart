import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/models/call_record.dart';

/// Local data source for call records using [SharedPreferences].
///
/// This is suitable for MVP and will be replaced with SQLite in a later task.
class CallLocalDataSource {
  static const String _callRecordsKey = 'call_records';
  static const String _pendingSyncKey = 'pending_sync_calls';

  /// Saves a call record to local storage.
  Future<void> saveCallRecord(CallRecord record) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<CallRecord> records = await _getAllRecords(prefs);

      // Add new record at the beginning (most recent first).
      records.insert(0, record);

      // Keep only last 500 records locally.
      if (records.length > 500) {
        records.removeRange(500, records.length);
      }

      await _saveAllRecords(prefs, records);
      debugPrint('CallLocalDataSource: Saved record ${record.id}');
    } catch (e) {
      debugPrint('CallLocalDataSource: Error saving record: $e');
      rethrow;
    }
  }

  /// Gets recent call records.
  Future<List<CallRecord>> getRecentCalls({int limit = 50}) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<CallRecord> records = await _getAllRecords(prefs);
      return records.take(limit).toList();
    } catch (e) {
      debugPrint('CallLocalDataSource: Error getting recent calls: $e');
      return <CallRecord>[];
    }
  }

  /// Gets calls filtered by status.
  Future<List<CallRecord>> getCallsByStatus(CallStatus status) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<CallRecord> records = await _getAllRecords(prefs);
      return records.where((CallRecord r) => r.status == status).toList();
    } catch (e) {
      debugPrint('CallLocalDataSource: Error filtering by status: $e');
      return <CallRecord>[];
    }
  }

  /// Marks a record for later sync.
  Future<void> markForSync(String recordId) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> pendingIds =
          prefs.getStringList(_pendingSyncKey) ?? <String>[];
      if (!pendingIds.contains(recordId)) {
        pendingIds.add(recordId);
        await prefs.setStringList(_pendingSyncKey, pendingIds);
      }
    } catch (e) {
      debugPrint('CallLocalDataSource: Error marking for sync: $e');
    }
  }

  Future<List<CallRecord>> _getAllRecords(SharedPreferences prefs) async {
    final String? jsonString = prefs.getString(_callRecordsKey);
    if (jsonString == null || jsonString.isEmpty) {
      return <CallRecord>[];
    }

    try {
      final List<dynamic> jsonList =
          json.decode(jsonString) as List<dynamic>;
      return jsonList
          .map((dynamic j) => CallRecord.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('CallLocalDataSource: Error parsing records: $e');
      return <CallRecord>[];
    }
  }

  Future<void> _saveAllRecords(
    SharedPreferences prefs,
    List<CallRecord> records,
  ) async {
    final List<Map<String, dynamic>> jsonList =
        records.map((CallRecord r) => r.toJson()).toList();
    await prefs.setString(_callRecordsKey, json.encode(jsonList));
  }
}


