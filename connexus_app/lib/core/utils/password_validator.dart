import 'package:equatable/equatable.dart';

/// Enum representing password strength levels.
enum PasswordStrength {
  empty,
  weak,
  fair,
  good,
  strong;

  /// Returns true if the password meets minimum strength requirements.
  bool get isAcceptable => index >= PasswordStrength.fair.index;
}

/// Model containing detailed password validation results.
class PasswordValidationResult extends Equatable {
  const PasswordValidationResult({
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasNumber,
    required this.hasSpecialChar,
    required this.strength,
  });

  /// Empty validation result for initial state.
  factory PasswordValidationResult.empty() {
    return const PasswordValidationResult(
      hasMinLength: false,
      hasUppercase: false,
      hasLowercase: false,
      hasNumber: false,
      hasSpecialChar: false,
      strength: PasswordStrength.empty,
    );
  }

  /// Whether the password meets the minimum length requirement.
  final bool hasMinLength;

  /// Whether the password contains at least one uppercase letter.
  final bool hasUppercase;

  /// Whether the password contains at least one lowercase letter.
  final bool hasLowercase;

  /// Whether the password contains at least one number.
  final bool hasNumber;

  /// Whether the password contains at least one special character.
  final bool hasSpecialChar;

  /// Overall strength classification.
  final PasswordStrength strength;

  /// Returns the number of requirements met (0–5).
  int get requirementsMet {
    var count = 0;
    if (hasMinLength) count++;
    if (hasUppercase) count++;
    if (hasLowercase) count++;
    if (hasNumber) count++;
    if (hasSpecialChar) count++;
    return count;
  }

  /// Returns true if all requirements are met.
  bool get allRequirementsMet => requirementsMet == 5;

  @override
  List<Object?> get props => <Object?>[
        hasMinLength,
        hasUppercase,
        hasLowercase,
        hasNumber,
        hasSpecialChar,
        strength,
      ];
}

/// Utility class for validating passwords and computing strength.
class PasswordValidator {
  PasswordValidator._();

  /// Minimum required password length.
  static const int minLength = 8;

  static final RegExp _uppercaseRegex = RegExp(r'[A-Z]');
  static final RegExp _lowercaseRegex = RegExp(r'[a-z]');
  static final RegExp _numberRegex = RegExp(r'[0-9]');
  static final RegExp _specialCharRegex =
      RegExp(r'[!@#$%^&*(),.?":{}|<>_\-\\/\[\]]');

  /// Validates a password and returns detailed results.
  static PasswordValidationResult validate(String password) {
    if (password.isEmpty) {
      return PasswordValidationResult.empty();
    }

    final bool hasMinLength = password.length >= minLength;
    final bool hasUppercase = _uppercaseRegex.hasMatch(password);
    final bool hasLowercase = _lowercaseRegex.hasMatch(password);
    final bool hasNumber = _numberRegex.hasMatch(password);
    final bool hasSpecialChar = _specialCharRegex.hasMatch(password);

    // Calculate score based on requirements met plus length bonuses.
    var score = 0;
    if (hasMinLength) score++;
    if (hasUppercase) score++;
    if (hasLowercase) score++;
    if (hasNumber) score++;
    if (hasSpecialChar) score++;

    if (password.length >= 12) score++;
    if (password.length >= 16) score++;

    late final PasswordStrength strength;
    if (score <= 2) {
      strength = PasswordStrength.weak;
    } else if (score <= 3) {
      strength = PasswordStrength.fair;
    } else if (score <= 5) {
      strength = PasswordStrength.good;
    } else {
      strength = PasswordStrength.strong;
    }

    return PasswordValidationResult(
      hasMinLength: hasMinLength,
      hasUppercase: hasUppercase,
      hasLowercase: hasLowercase,
      hasNumber: hasNumber,
      hasSpecialChar: hasSpecialChar,
      strength: strength,
    );
  }

  /// Simple validation that returns an error message or null.
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }

    final PasswordValidationResult result = validate(password);

    if (!result.hasMinLength) {
      return 'Password must be at least $minLength characters';
    }

    if (!result.strength.isAcceptable) {
      return 'Password is too weak. Add uppercase, lowercase, numbers, or special characters.';
    }

    return null;
  }

  /// Validates that confirm password matches.
  static String? validateConfirmPassword(
    String? password,
    String? confirmPassword,
  ) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }

    if (password != confirmPassword) {
      return 'Passwords do not match';
    }

    return null;
  }
}


