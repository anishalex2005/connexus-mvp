import 'package:equatable/equatable.dart';

/// Base failure class for error handling
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];
}

// General failures
class ServerFailure extends Failure {
  const ServerFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

class CacheFailure extends Failure {
  const CacheFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

// Authentication failures
class AuthenticationFailure extends Failure {
  const AuthenticationFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}

// Call-specific failures
class CallFailure extends Failure {
  const CallFailure({
    required String message,
    String? code,
  }) : super(message: message, code: code);
}
