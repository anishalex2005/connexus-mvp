import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/telnyx_credentials.dart';

/// Service for securely storing and retrieving sensitive data.
class SecureStorageService {
  static const String _credentialsKey = 'telnyx_credentials';
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';

  final FlutterSecureStorage _storage;

  SecureStorageService({
    FlutterSecureStorage? storage,
  }) : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  // ============ Telnyx Credentials ============

  /// Stores Telnyx credentials securely.
  Future<void> storeTelnyxCredentials(TelnyxCredentials credentials) async {
    try {
      final jsonString = jsonEncode(credentials.toJson());
      await _storage.write(key: _credentialsKey, value: jsonString);
    } catch (e) {
      throw SecureStorageException('Failed to store credentials: $e');
    }
  }

  /// Retrieves stored Telnyx credentials.
  Future<TelnyxCredentials?> getTelnyxCredentials() async {
    try {
      final jsonString = await _storage.read(key: _credentialsKey);
      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return TelnyxCredentials.fromJson(json);
    } catch (e) {
      throw SecureStorageException('Failed to retrieve credentials: $e');
    }
  }

  /// Deletes stored Telnyx credentials.
  Future<void> deleteTelnyxCredentials() async {
    try {
      await _storage.delete(key: _credentialsKey);
    } catch (e) {
      throw SecureStorageException('Failed to delete credentials: $e');
    }
  }

  /// Checks if credentials exist and appear valid.
  Future<bool> hasCredentials() async {
    final credentials = await getTelnyxCredentials();
    return credentials != null && credentials.isValid;
  }

  // ============ Auth Tokens ============

  /// Stores authentication token.
  Future<void> storeAuthToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Retrieves authentication token.
  Future<String?> getAuthToken() async {
    return _storage.read(key: _tokenKey);
  }

  /// Stores refresh token.
  Future<void> storeRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  /// Retrieves refresh token.
  Future<String?> getRefreshToken() async {
    return _storage.read(key: _refreshTokenKey);
  }

  // ============ Utility Methods ============

  /// Clears all stored data (for logout).
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// Stores a generic key-value pair.
  Future<void> store(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Retrieves a value by key.
  Future<String?> retrieve(String key) async {
    return _storage.read(key: key);
  }
}

/// Exception for secure storage errors.
class SecureStorageException implements Exception {
  final String message;

  SecureStorageException(this.message);

  @override
  String toString() => 'SecureStorageException: $message';
}
