/// API endpoint constants.
class ApiEndpoints {
  // Base URL is configured by ApiClient / AppConfig.
  static const String _apiVersionPrefix = '/api/v1';

  // Auth endpoints.
  static const String login = '$_apiVersionPrefix/auth/login';
  static const String register = '$_apiVersionPrefix/auth/register';
  static const String refreshToken = '$_apiVersionPrefix/auth/refresh';
  static const String logout = '$_apiVersionPrefix/auth/logout';

  // User endpoints.
  static const String userProfile = '$_apiVersionPrefix/users/profile';
  static const String userSettings = '$_apiVersionPrefix/users/settings';

  // Telephony endpoints (Task 14).
  static const String telephonyCredentials =
      '$_apiVersionPrefix/telephony/credentials';
  static const String telephonyFcmToken =
      '$_apiVersionPrefix/telephony/fcm-token';
  static const String telephonyConnectionStatus =
      '$_apiVersionPrefix/telephony/connection-status';

  // Call endpoints (for future tasks).
  static const String calls = '$_apiVersionPrefix/calls';
  static const String callHistory = '$_apiVersionPrefix/calls/history';
}
