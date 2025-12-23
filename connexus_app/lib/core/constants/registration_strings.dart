/// String constants for the registration screen.
///
/// Centralizing strings makes localization easier and prevents typos.
class RegistrationStrings {
  const RegistrationStrings._();

  // Screen titles
  static const String screenTitle = 'Create Account';
  static const String screenSubtitle = 'Sign up to get started with ConnexUS';

  // Field labels
  static const String firstNameLabel = 'First Name';
  static const String lastNameLabel = 'Last Name';
  static const String emailLabel = 'Email Address';
  static const String passwordLabel = 'Password';
  static const String confirmPasswordLabel = 'Confirm Password';

  // Field hints
  static const String firstNameHint = 'Enter your first name';
  static const String lastNameHint = 'Enter your last name';
  static const String emailHint = 'you@example.com';
  static const String passwordHint = 'Create a strong password';
  static const String confirmPasswordHint = 'Re-enter your password';

  // Validation messages
  static const String firstNameRequired = 'First name is required';
  static const String lastNameRequired = 'Last name is required';
  static const String emailRequired = 'Email address is required';
  static const String emailInvalid = 'Please enter a valid email address';
  static const String passwordRequired = 'Password is required';
  static const String passwordTooShort =
      'Password must be at least 8 characters';
  static const String passwordTooWeak = 'Password is too weak';
  static const String passwordsDoNotMatch = 'Passwords do not match';

  // Password strength labels
  static const String strengthWeak = 'Weak';
  static const String strengthFair = 'Fair';
  static const String strengthGood = 'Good';
  static const String strengthStrong = 'Strong';

  // Password requirements
  static const String passwordRequirements = 'Password must contain:';
  static const String requirementLength = 'At least 8 characters';
  static const String requirementUppercase = 'One uppercase letter';
  static const String requirementLowercase = 'One lowercase letter';
  static const String requirementNumber = 'One number';
  static const String requirementSpecial =
      'One special character (!@#\$%^&* or similar)';

  // Terms and conditions
  static const String termsPrefix = 'I agree to the ';
  static const String termsOfService = 'Terms of Service';
  static const String andText = ' and ';
  static const String privacyPolicy = 'Privacy Policy';
  static const String termsRequired = 'You must accept the terms to continue';

  // Buttons
  static const String createAccountButton = 'Create Account';
  static const String alreadyHaveAccount = 'Already have an account? ';
  static const String signInLink = 'Sign In';

  // Success/Error messages
  static const String registrationSuccess = 'Account created successfully!';
  static const String registrationError =
      'Failed to create account. Please try again.';
  static const String emailAlreadyExists =
      'An account with this email already exists';
}


