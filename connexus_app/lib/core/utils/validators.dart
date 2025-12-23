/// Form field validators for the ConnexUS app.
///
/// These are simple, reusable helpers for forms that are not using Formz.
class Validators {
  Validators._();

  /// Email validation regex pattern.
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Minimum acceptable password length.
  static const int minPasswordLength = 8;

  /// Maximum acceptable password length.
  static const int maxPasswordLength = 128;

  /// Validates an email address.
  ///
  /// Returns `null` if valid, or an error message if invalid.
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final String trimmed = value.trim();

    if (trimmed.isEmpty) {
      return 'Email is required';
    }

    if (!_emailRegex.hasMatch(trimmed)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Validates a password for registration or password update.
  ///
  /// Returns `null` if valid, or an error message if invalid.
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < minPasswordLength) {
      return 'Password must be at least $minPasswordLength characters';
    }

    if (value.length > maxPasswordLength) {
      return 'Password is too long';
    }

    return null;
  }

  /// Validates a password for login (less strict than registration).
  ///
  /// For login, we just check that it is not empty.
  static String? validateLoginPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    return null;
  }

  /// Validates that a required field is not empty.
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    return null;
  }
}


