import 'package:flutter/material.dart';

import '../../../core/constants/registration_strings.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/password_validator.dart';
import '../../widgets/auth/auth_text_field.dart';
import '../../widgets/auth/password_strength_indicator.dart';
import '../../widgets/auth/terms_checkbox.dart';
import '../../widgets/common/primary_button.dart';

/// Registration screen for new user account creation.
///
/// Implements form validation, password strength checking, and terms acceptance.
/// Actual API integration will be added in Task 28.
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _termsAccepted = false;
  bool _showTermsError = false;
  bool _isLoading = false;

  PasswordValidationResult _passwordValidation =
      PasswordValidationResult.empty();

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController
      ..removeListener(_onPasswordChanged)
      ..dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onPasswordChanged() {
    setState(() {
      _passwordValidation =
          PasswordValidator.validate(_passwordController.text);
    });
  }

  Future<void> _handleRegistration() async {
    if (!_termsAccepted) {
      setState(() {
        _showTermsError = true;
      });
      return;
    }

    final FormState? formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    if (!_passwordValidation.strength.isAcceptable) {
      _showSnackBar('Please create a stronger password');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO(Task 28): Replace with real registration API call.
      await Future<void>.delayed(const Duration(seconds: 2));

      if (!mounted) {
        return;
      }

      _showSnackBar(
        RegistrationStrings.registrationSuccess,
        isError: false,
      );

      // Navigate back to login after successful registration.
      AppRouter.navigateAndReplace(context, AppRouter.login);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showSnackBar(RegistrationStrings.registrationError);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.error : AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _buildBackButton(),
                  const SizedBox(height: 24),
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildNameFields(),
                  const SizedBox(height: 20),
                  EmailTextField(
                    controller: _emailController,
                    validator: (String? value) {
                      if (value == null || value.trim().isEmpty) {
                        return RegistrationStrings.emailRequired;
                      }
                      final String trimmed = value.trim();
                      final RegExp emailRegex = RegExp(
                        r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$',
                      );
                      if (!emailRegex.hasMatch(trimmed)) {
                        return RegistrationStrings.emailInvalid;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  PasswordTextField(
                    controller: _passwordController,
                    label: RegistrationStrings.passwordLabel,
                    hint: RegistrationStrings.passwordHint,
                    validator: (String? value) =>
                        PasswordValidator.validatePassword(value),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  PasswordStrengthIndicator(
                    validationResult: _passwordValidation,
                    showRequirements: true,
                  ),
                  const SizedBox(height: 20),
                  PasswordTextField(
                    controller: _confirmPasswordController,
                    label: RegistrationStrings.confirmPasswordLabel,
                    hint: RegistrationStrings.confirmPasswordHint,
                    validator: (String? value) =>
                        PasswordValidator.validateConfirmPassword(
                      _passwordController.text,
                      value,
                    ),
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 24),
                  TermsCheckbox(
                    value: _termsAccepted,
                    onChanged: (bool? value) {
                      setState(() {
                        _termsAccepted = value ?? false;
                        if (_termsAccepted) {
                          _showTermsError = false;
                        }
                      });
                    },
                    onTermsTap: () => _showLegalDocument(
                      RegistrationStrings.termsOfService,
                    ),
                    onPrivacyTap: () => _showLegalDocument(
                      RegistrationStrings.privacyPolicy,
                    ),
                    errorText:
                        _showTermsError ? RegistrationStrings.termsRequired : null,
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    text: RegistrationStrings.createAccountButton,
                    isLoading: _isLoading,
                    isEnabled: !_isLoading,
                    onPressed: _handleRegistration,
                  ),
                  const SizedBox(height: 24),
                  _buildSignInLink(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        style: IconButton.styleFrom(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          RegistrationStrings.screenTitle,
          style: AppTextStyles.h2.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          RegistrationStrings.screenSubtitle,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildNameFields() {
    return Row(
      children: <Widget>[
        Expanded(
          child: AuthTextField(
            controller: _firstNameController,
            label: RegistrationStrings.firstNameLabel,
            hint: RegistrationStrings.firstNameHint,
            textInputAction: TextInputAction.next,
            validator: (String? value) {
              if (value == null || value.trim().isEmpty) {
                return RegistrationStrings.firstNameRequired;
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AuthTextField(
            controller: _lastNameController,
            label: RegistrationStrings.lastNameLabel,
            hint: RegistrationStrings.lastNameHint,
            textInputAction: TextInputAction.next,
            validator: (String? value) {
              if (value == null || value.trim().isEmpty) {
                return RegistrationStrings.lastNameRequired;
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSignInLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          RegistrationStrings.alreadyHaveAccount,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        TextButton(
          onPressed: () {
            AppRouter.navigateAndReplace(context, AppRouter.login);
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            RegistrationStrings.signInLink,
            style: AppTextStyles.link.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _showLegalDocument(String title) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (BuildContext context, ScrollController controller) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textTertiary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: controller,
                      child: Text(
                        _getLegalContent(title),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    text: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getLegalContent(String title) {
    if (title == RegistrationStrings.termsOfService) {
      return '''
Terms of Service for ConnexUS

Last updated: ${DateTime.now().year}

1. Acceptance of Terms
By accessing and using ConnexUS, you agree to be bound by these Terms of Service.

2. Description of Service
ConnexUS provides AI-powered call management services for businesses.

3. User Accounts
You are responsible for maintaining the security of your account credentials.

4. Privacy
Your use of the service is also governed by our Privacy Policy.

5. Prohibited Uses
You agree not to use the service for any unlawful purpose.

6. Termination
We reserve the right to terminate your access to the service at any time.

7. Changes to Terms
We may modify these terms at any time. Continued use constitutes acceptance.

8. Contact
For questions about these terms, contact us at support@connexus.com.
''';
    }

    return '''
Privacy Policy for ConnexUS

Last updated: ${DateTime.now().year}

1. Information We Collect
We collect information you provide directly, including name, email, and phone number.

2. How We Use Your Information
We use your information to provide and improve our services.

3. Information Sharing
We do not sell your personal information to third parties.

4. Data Security
We implement appropriate security measures to protect your information.

5. Your Rights
You have the right to access, correct, or delete your personal information.

6. Cookies
We use cookies to improve your experience on our platform.

7. Changes to This Policy
We may update this policy from time to time.

8. Contact Us
For privacy questions, contact us at privacy@connexus.com.
''';
  }
}


