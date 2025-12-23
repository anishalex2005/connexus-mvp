import 'app_config.dart';

/// Thin wrapper for environment configuration used by some task docs.
///
/// The project primarily uses [AppConfig], but a dedicated [EnvConfig]
/// helps keep compatibility with documentation that expects this API.
abstract class EnvConfig {
  /// Base URL for the backend API (including protocol and host).
  static String get apiBaseUrl => AppConfig.apiBaseUrl;
}


