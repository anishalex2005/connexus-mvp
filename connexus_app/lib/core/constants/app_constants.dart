/// Application-wide constants
class AppConstants {
  // API Configuration
  static const String appName = 'ConnexUS';
  static const String appVersion = '1.0.0';

  // Timeouts
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds

  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String themeKey = 'theme_preference';

  // Pagination
  static const int defaultPageSize = 20;

  // Call Configuration
  static const int callConnectTimeout = 5000; // 5 seconds
  static const int maxRetryAttempts = 3;
}
