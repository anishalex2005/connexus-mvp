import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/telnyx_credentials.dart';

/// Repository for telephony-related API operations.
class TelephonyRepository {
  final ApiClient _apiClient;

  TelephonyRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetches SIP credentials from the backend.
  Future<TelnyxCredentials> getCredentials() async {
    try {
      final Response<dynamic> response =
          await _apiClient.get(ApiEndpoints.telephonyCredentials);

      if (response.statusCode == 200 &&
          response.data is Map<String, dynamic> &&
          response.data['success'] == true) {
        return TelnyxCredentials.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
      }

      throw TelephonyException(
        'Failed to fetch credentials',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is TelephonyException) rethrow;
      throw TelephonyException('Network error fetching credentials: $e');
    }
  }

  /// Saves SIP credentials to the backend.
  Future<void> saveCredentials(TelnyxCredentials credentials) async {
    try {
      final Response<dynamic> response = await _apiClient.post(
        ApiEndpoints.telephonyCredentials,
        data: credentials.toJson(),
      );

      if (response.statusCode != 201 ||
          response.data == null ||
          response.data['success'] != true) {
        throw TelephonyException(
          'Failed to save credentials',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is TelephonyException) rethrow;
      throw TelephonyException('Network error saving credentials: $e');
    }
  }

  /// Updates FCM token for push notifications.
  Future<void> updateFcmToken(String fcmToken) async {
    try {
      final Response<dynamic> response = await _apiClient.put(
        ApiEndpoints.telephonyFcmToken,
        data: <String, dynamic>{'fcm_token': fcmToken},
      );

      if (response.statusCode != 200 ||
          response.data == null ||
          response.data['success'] != true) {
        throw TelephonyException(
          'Failed to update FCM token',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is TelephonyException) rethrow;
      throw TelephonyException('Network error updating FCM token: $e');
    }
  }

  /// Deactivates credentials.
  Future<void> deleteCredentials() async {
    try {
      final Response<dynamic> response =
          await _apiClient.delete(ApiEndpoints.telephonyCredentials);

      if (response.statusCode != 200 ||
          response.data == null ||
          response.data['success'] != true) {
        throw TelephonyException(
          'Failed to delete credentials',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is TelephonyException) rethrow;
      throw TelephonyException('Network error deleting credentials: $e');
    }
  }

  /// Gets connection status.
  Future<ConnectionStatus> getConnectionStatus() async {
    try {
      final Response<dynamic> response =
          await _apiClient.get(ApiEndpoints.telephonyConnectionStatus);

      if (response.statusCode == 200 &&
          response.data is Map<String, dynamic> &&
          response.data['success'] == true) {
        return ConnectionStatus.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
      }

      throw TelephonyException(
        'Failed to get connection status',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is TelephonyException) rethrow;
      throw TelephonyException('Network error getting status: $e');
    }
  }
}

/// Connection status model.
class ConnectionStatus {
  final bool hasCredentials;
  final bool isActive;
  final DateTime? lastConnectedAt;
  final int connectionCount;

  ConnectionStatus({
    required this.hasCredentials,
    required this.isActive,
    this.lastConnectedAt,
    this.connectionCount = 0,
  });

  factory ConnectionStatus.fromJson(Map<String, dynamic> json) {
    return ConnectionStatus(
      hasCredentials: (json['has_credentials'] as bool?) ?? false,
      isActive: (json['is_active'] as bool?) ?? false,
      lastConnectedAt: json['last_connected_at'] != null
          ? DateTime.tryParse(json['last_connected_at'].toString())
          : null,
      connectionCount: (json['connection_count'] as int?) ?? 0,
    );
  }
}

/// Exception for telephony operations.
class TelephonyException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  TelephonyException(
    this.message, {
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => 'TelephonyException: $message (status: $statusCode)';
}
