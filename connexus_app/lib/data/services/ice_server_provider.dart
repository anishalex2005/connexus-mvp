import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/utils/logger.dart' as app_logger;
import '../../domain/models/webrtc_config.dart';
import '../../core/config/app_config.dart';

/// Provides ICE server configurations, fetching TURN credentials from backend.
class IceServerProvider {
  final http.Client _httpClient;

  // Cache TURN credentials (they typically last 24 hours).
  IceServerConfig? _cachedTurnServer;
  DateTime? _cacheExpiry;

  IceServerProvider({
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  /// Get complete WebRTC configuration with fresh ICE servers.
  Future<WebRTCConfig> getWebRTCConfig() async {
    app_logger.Logger.info('Fetching WebRTC configuration');

    final IceServerConfig? turnCredentials = await _getTurnCredentials();

    return WebRTCConfig(
      iceServers: <IceServerConfig>[
        // Public STUN servers (always available).
        const IceServerConfig(url: 'stun:stun.l.google.com:19302'),
        const IceServerConfig(url: 'stun:stun1.l.google.com:19302'),
        const IceServerConfig(url: 'stun:stun.telnyx.com:3478'),
        // TURN server (if credentials available).
        if (turnCredentials != null) turnCredentials,
      ],
    );
  }

  /// Fetch TURN credentials from backend.
  Future<IceServerConfig?> _getTurnCredentials() async {
    // Return cached credentials if still valid.
    if (_cachedTurnServer != null &&
        _cacheExpiry != null &&
        DateTime.now().isBefore(_cacheExpiry!)) {
      app_logger.Logger.debug('Using cached TURN credentials');
      return _cachedTurnServer;
    }

    try {
      final Uri uri = Uri.parse(
        AppConfig.getApiUrl('/webrtc/turn-credentials'),
      );
      final http.Response response = await _httpClient.get(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;

        _cachedTurnServer = IceServerConfig(
          url: data['url'] as String,
          username: data['username'] as String?,
          credential: data['credential'] as String?,
        );

        // Cache for 23 hours (credentials typically last 24 hours).
        _cacheExpiry = DateTime.now().add(const Duration(hours: 23));

        app_logger.Logger.info('TURN credentials fetched and cached');
        return _cachedTurnServer;
      } else {
        app_logger.Logger.warning(
          'Failed to fetch TURN credentials: ${response.statusCode}',
        );
        return null;
      }
    } catch (e, stackTrace) {
      app_logger.Logger.error(
        'Error fetching TURN credentials',
        e,
        stackTrace,
      );
      // Fall back to environment variables if API fails.
      return _getFallbackTurnConfig();
    }
  }

  /// Fallback to environment-configured TURN server.
  IceServerConfig? _getFallbackTurnConfig() {
    final String? turnUrl = AppConfig.turnServerUrl;
    final String? turnUsername = AppConfig.turnUsername;
    final String? turnPassword = AppConfig.turnPassword;

    if (turnUrl != null &&
        turnUrl.isNotEmpty &&
        turnUsername != null &&
        turnUsername.isNotEmpty &&
        turnPassword != null &&
        turnPassword.isNotEmpty) {
      app_logger.Logger.info(
        'Using fallback TURN configuration from environment',
      );
      return IceServerConfig(
        url: turnUrl,
        username: turnUsername,
        credential: turnPassword,
      );
    }

    app_logger.Logger.warning(
      'No TURN server available - NAT traversal may fail',
    );
    return null;
  }

  /// Clear cached credentials.
  void clearCache() {
    _cachedTurnServer = null;
    _cacheExpiry = null;
    app_logger.Logger.info('ICE server cache cleared');
  }
}
