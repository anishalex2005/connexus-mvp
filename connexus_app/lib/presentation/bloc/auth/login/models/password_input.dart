import 'package:formz/formz.dart';

/// Validation errors for the login password input.
enum LoginPasswordValidationError {
  /// Password field is empty.
  empty,
}

/// Password input field for login with simple non-empty validation.
class LoginPasswordInput
    extends FormzInput<String, LoginPasswordValidationError> {
  /// Constructor for pure (unmodified) state.
  const LoginPasswordInput.pure() : super.pure('');

  /// Constructor for dirty (modified) state.
  const LoginPasswordInput.dirty([super.value = '']) : super.dirty();

  @override
  LoginPasswordValidationError? validator(String value) {
    if (value.isEmpty) {
      return LoginPasswordValidationError.empty;
    }

    return null;
  }

  /// Human-readable error message for the current validation state.
  String? get errorMessage {
    if (isValid || isPure) return null;

    switch (displayError) {
      case LoginPasswordValidationError.empty:
        return 'Password is required';
      case null:
        return null;
    }
  }
}


