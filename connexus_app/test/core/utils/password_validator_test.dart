import 'package:connexus_app/core/utils/password_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PasswordValidator', () {
    test('empty password returns empty result', () {
      final PasswordValidationResult result = PasswordValidator.validate('');

      expect(result.strength, PasswordStrength.empty);
      expect(result.requirementsMet, 0);
    });

    test('short password is weak and fails min length', () {
      final PasswordValidationResult result = PasswordValidator.validate('abc');

      expect(result.strength, PasswordStrength.weak);
      expect(result.hasMinLength, isFalse);
    });

    test('password with only lowercase is weak', () {
      final PasswordValidationResult result =
          PasswordValidator.validate('abcdefgh');

      expect(result.strength, PasswordStrength.weak);
      expect(result.hasLowercase, isTrue);
      expect(result.hasUppercase, isFalse);
      expect(result.hasNumber, isFalse);
      expect(result.hasSpecialChar, isFalse);
    });

    test('password with mixed case is at least fair', () {
      final PasswordValidationResult result =
          PasswordValidator.validate('Abcdefgh');

      expect(
        result.strength.index >= PasswordStrength.fair.index,
        isTrue,
      );
      expect(result.hasUppercase, isTrue);
      expect(result.hasLowercase, isTrue);
    });

    test('password with all requirements is acceptable', () {
      final PasswordValidationResult result =
          PasswordValidator.validate('Abcdef1@');

      expect(result.strength.isAcceptable, isTrue);
      expect(result.allRequirementsMet, isTrue);
    });

    test('validatePassword returns error for empty', () {
      final String? error = PasswordValidator.validatePassword('');

      expect(error, isNotNull);
      expect(error, contains('required'));
    });

    test('validatePassword returns null for valid password', () {
      final String? error =
          PasswordValidator.validatePassword('StrongP@ss1word');

      expect(error, isNull);
    });

    test('validateConfirmPassword detects mismatch', () {
      final String? error = PasswordValidator.validateConfirmPassword(
        'Password1!',
        'Password2!',
      );

      expect(error, isNotNull);
      expect(error, contains('match'));
    });

    test('validateConfirmPassword passes for matching', () {
      final String? error = PasswordValidator.validateConfirmPassword(
        'Password1!',
        'Password1!',
      );

      expect(error, isNull);
    });
  });
}


