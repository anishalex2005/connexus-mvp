import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../domain/models/call_record.dart';

/// Remote data source for syncing call records to backend.
class CallRemoteDataSource {
  final http.Client _httpClient;
  final String _endpointUrl;

  CallRemoteDataSource({
    http.Client? httpClient,
    String? endpointUrl,
  })  : _httpClient = httpClient ?? http.Client(),
        _endpointUrl =
            endpointUrl ?? AppConfig.getApiUrl('/calls'); // POST /api/v1/calls

  /// Syncs a call record to the remote server.
  Future<void> syncCallRecord(CallRecord record) async {
    try {
      final http.Response response = await _httpClient.post(
        Uri.parse(_endpointUrl),
        headers: <String, String>{
          'Content-Type': 'application/json',
          // Auth token can be injected here once auth storage is wired.
        },
        body: json.encode(record.toJson()),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'Failed to sync call record: ${response.statusCode}',
        );
      }

      debugPrint('CallRemoteDataSource: Synced record ${record.id}');
    } catch (e) {
      debugPrint('CallRemoteDataSource: Sync failed: $e');
      rethrow;
    }
  }
}


