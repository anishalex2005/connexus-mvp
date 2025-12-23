import 'package:formz/formz.dart';

/// Validation errors for the email input.
enum EmailValidationError {
  /// Email field is empty.
  empty,

  /// Email format is invalid.
  invalid,
}

/// Email input field with validation using Formz.
class EmailInput extends FormzInput<String, EmailValidationError> {
  /// Constructor for pure (unmodified) state.
  const EmailInput.pure() : super.pure('');

  /// Constructor for dirty (modified) state.
  const EmailInput.dirty([super.value = '']) : super.dirty();

  /// Email validation regex.
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  @override
  EmailValidationError? validator(String value) {
    if (value.isEmpty) {
      return EmailValidationError.empty;
    }

    if (!_emailRegex.hasMatch(value.trim())) {
      return EmailValidationError.invalid;
    }

    return null;
  }

  /// Human-readable error message for the current validation state.
  String? get errorMessage {
    if (isValid || isPure) return null;

    switch (displayError) {
      case EmailValidationError.empty:
        return 'Email is required';
      case EmailValidationError.invalid:
        return 'Please enter a valid email address';
      case null:
        return null;
    }
  }
}


