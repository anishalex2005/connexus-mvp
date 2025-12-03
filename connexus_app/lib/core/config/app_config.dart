import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'telnyx_config.dart';

/// Application environment
enum Environment {
  development,
  staging,
  production,
}

/// Application configuration
class AppConfig {
  static late Environment _environment;
  static bool _initialized = false;

  static Environment get environment => _environment;

  // API Configuration
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3000';
  static String get apiVersion => dotenv.env['API_VERSION'] ?? 'v1';
  static int get apiTimeout =>
      int.tryParse(dotenv.env['API_TIMEOUT'] ?? '') ?? 30000;

  // WebRTC / ICE servers
  static String? get stunServerUrl => dotenv.env['STUN_SERVER_URL'];
  static String? get turnServerUrl => dotenv.env['TURN_SERVER_URL'];
  static String? get turnUsername => dotenv.env['TURN_USERNAME'];
  static String? get turnPassword => dotenv.env['TURN_PASSWORD'];

  // Telnyx Configuration (generic)
  static String get telnyxApiKey => dotenv.env['TELNYX_API_KEY'] ?? '';
  static String get telnyxSipPassword =>
      dotenv.env['TELNYX_SIP_PASSWORD'] ?? '';
  static String get telnyxWebhookUrl => dotenv.env['TELNYX_WEBHOOK_URL'] ?? '';

  /// Telnyx SIP username (supports both legacy TELNYX_SIP_USER and new TELNYX_SIP_USERNAME)
  static String get telnyxSipUsername =>
      dotenv.env['TELNYX_SIP_USERNAME'] ?? dotenv.env['TELNYX_SIP_USER'] ?? '';

  /// Telnyx caller ID number for outbound calls
  static String get telnyxCallerIdNumber =>
      dotenv.env['TELNYX_CALLER_ID'] ?? '';

  /// Optional Telnyx caller ID name
  static String? get telnyxCallerIdName => dotenv.env['TELNYX_CALLER_ID_NAME'];

  /// Enable verbose Telnyx SDK logging
  static bool get telnyxDebugEnabled =>
      (dotenv.env['TELNYX_DEBUG'] ?? 'false').toLowerCase() == 'true';

  /// Whether required Telnyx config values are present
  static bool get hasTelnyxConfig =>
      telnyxSipUsername.isNotEmpty &&
      telnyxSipPassword.isNotEmpty &&
      telnyxCallerIdNumber.isNotEmpty;

  /// Build a strongly-typed TelnyxConfig from environment values
  static TelnyxConfig get telnyxConfig => TelnyxConfig.fromEnvironment(
        sipUsername: telnyxSipUsername,
        sipPassword: telnyxSipPassword,
        callerIdNumber: telnyxCallerIdNumber,
        callerIdName: telnyxCallerIdName,
        enableDebugLogging: telnyxDebugEnabled,
      );

  // Retell AI Configuration
  static String get retellApiKey => dotenv.env['RETELL_API_KEY'] ?? '';
  static String get retellAgentId => dotenv.env['RETELL_AGENT_ID'] ?? '';
  static String get retellWebhookUrl => dotenv.env['RETELL_WEBHOOK_URL'] ?? '';

  // Firebase Configuration
  static String get fcmServerKey => dotenv.env['FCM_SERVER_KEY'] ?? '';

  // Feature Flags
  static bool get enableCallRecording =>
      (dotenv.env['ENABLE_CALL_RECORDING'] ?? 'false').toLowerCase() == 'true';
  static bool get enableAnalytics =>
      (dotenv.env['ENABLE_ANALYTICS'] ?? 'false').toLowerCase() == 'true';
  static bool get enableCrashReporting =>
      (dotenv.env['ENABLE_CRASH_REPORTING'] ?? 'false').toLowerCase() == 'true';
  static bool get debugMode =>
      (dotenv.env['DEBUG_MODE'] ?? 'true').toLowerCase() == 'true';

  // App Configuration
  static String get appName => dotenv.env['APP_NAME'] ?? 'ConnexUS';
  static String get appVersion => dotenv.env['APP_VERSION'] ?? '1.0.0';
  static String get buildNumber => dotenv.env['BUILD_NUMBER'] ?? '1';

  /// Initialize configuration for the specified environment
  static Future<void> initialize(Environment env) async {
    _environment = env;
    if (_initialized) return;

    final String base = 'env/.env';
    String fileName;
    switch (env) {
      case Environment.development:
        fileName = '$base.development';
        break;
      case Environment.staging:
        fileName = '$base.staging';
        break;
      case Environment.production:
        fileName = '$base.production';
        break;
    }

    // Try to load env file; if missing, continue with defaults
    try {
      await dotenv.load(fileName: fileName, mergeWith: {});
    } catch (_) {
      // Fallback: continue without env file (use defaults)
    }

    _initialized = true;
    _validateConfiguration();
  }

  /// Validate that required config exists in production
  static void _validateConfiguration() {
    if (_environment == Environment.production) {
      final List<String> errors = [];
      if (apiBaseUrl.isEmpty) errors.add('API_BASE_URL is not configured');
      if (telnyxApiKey.isEmpty) errors.add('TELNYX_API_KEY is not configured');
      if (retellApiKey.isEmpty) errors.add('RETELL_API_KEY is not configured');
      if (errors.isNotEmpty) {
        throw Exception('Configuration errors:\n${errors.join('\n')}');
      }
    }
  }

  /// Derived helpers
  static bool get isProduction => _environment == Environment.production;
  static bool get isStaging => _environment == Environment.staging;
  static bool get isDevelopment => _environment == Environment.development;
  static bool get isDebug => kDebugMode;

  static String getApiUrl(String endpoint) {
    final String normalized =
        endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return '$apiBaseUrl/api/$apiVersion$normalized';
  }
}
