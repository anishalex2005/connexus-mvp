import 'package:equatable/equatable.dart';

import 'models/models.dart';

/// Possible statuses for the login form submission flow.
enum LoginStatus {
  /// Initial state, form not yet submitted.
  initial,

  /// Form is being submitted.
  submitting,

  /// Login was successful.
  success,

  /// Login failed with an error.
  failure,
}

/// State for the login form.
///
/// Contains the form inputs, validation state, and submission status.
class LoginState extends Equatable {
  const LoginState({
    this.email = const EmailInput.pure(),
    this.password = const LoginPasswordInput.pure(),
    this.status = LoginStatus.initial,
    this.isValid = false,
    this.errorMessage,
    this.obscurePassword = true,
  });

  /// Email input field.
  final EmailInput email;

  /// Password input field.
  final LoginPasswordInput password;

  /// Current status of the login process.
  final LoginStatus status;

  /// Whether the form is valid for submission.
  final bool isValid;

  /// Error message from failed login attempt, if any.
  final String? errorMessage;

  /// Whether to obscure the password input.
  final bool obscurePassword;

  /// Convenience getter for submitting state.
  bool get isSubmitting => status == LoginStatus.submitting;

  /// Convenience getter for success state.
  bool get isSuccess => status == LoginStatus.success;

  /// Convenience getter for failure state.
  bool get isFailure => status == LoginStatus.failure;

  /// Create a copy with updated values.
  LoginState copyWith({
    EmailInput? email,
    LoginPasswordInput? password,
    LoginStatus? status,
    bool? isValid,
    String? errorMessage,
    bool? obscurePassword,
  }) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      status: status ?? this.status,
      isValid: isValid ?? this.isValid,
      errorMessage: errorMessage,
      obscurePassword: obscurePassword ?? this.obscurePassword,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        email,
        password,
        status,
        isValid,
        errorMessage,
        obscurePassword,
      ];
}


