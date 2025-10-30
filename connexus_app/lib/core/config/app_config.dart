import 'package:flutter/foundation.dart';

/// Application configuration
class AppConfig {
  static late AppConfig _instance;
  
  final String apiBaseUrl;
  final String telnyxApiKey;
  final String retellApiKey;
  final bool enableLogging;
  final Environment environment;
  
  AppConfig._({
    required this.apiBaseUrl,
    required this.telnyxApiKey,
    required this.retellApiKey,
    required this.enableLogging,
    required this.environment,
  });
  
  /// Initialize app configuration
  static void initialize({
    required String apiBaseUrl,
    required String telnyxApiKey,
    required String retellApiKey,
    required Environment environment,
  }) {
    _instance = AppConfig._(
      apiBaseUrl: apiBaseUrl,
      telnyxApiKey: telnyxApiKey,
      retellApiKey: retellApiKey,
      enableLogging: environment != Environment.production,
      environment: environment,
    );
  }
  
  /// Get current app configuration instance
  static AppConfig get instance => _instance;
  
  /// Check if app is in debug mode
  static bool get isDebug => kDebugMode;
  
  /// Check if app is in production
  bool get isProduction => environment == Environment.production;
  
  /// Check if app is in staging
  bool get isStaging => environment == Environment.staging;
  
  /// Check if app is in development
  bool get isDevelopment => environment == Environment.development;
}

/// Application environment
enum Environment {
  development,
  staging,
  production,
}


