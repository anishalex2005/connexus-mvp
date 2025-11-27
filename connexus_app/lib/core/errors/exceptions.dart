/// Custom exception classes for the application
class ServerException implements Exception {
  final String message;
  final String? code;

  ServerException({
    required this.message,
    this.code,
  });
}

class NetworkException implements Exception {
  final String message;

  NetworkException({required this.message});
}

class CacheException implements Exception {
  final String message;

  CacheException({required this.message});
}

class AuthenticationException implements Exception {
  final String message;
  final String? code;

  AuthenticationException({
    required this.message,
    this.code,
  });
}

class CallException implements Exception {
  final String message;
  final String? code;

  CallException({
    required this.message,
    this.code,
  });
}
