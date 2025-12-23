import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../bloc/auth/login/login.dart';
import '../../widgets/widgets.dart';

/// Login screen for ConnexUS.
///
/// Allows existing users to sign in with email and password and
/// links to registration and password reset flows (to be wired later).
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LoginBloc>(
      create: (_) => LoginBloc(),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatelessWidget {
  const _LoginView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      listenWhen: (LoginState previous, LoginState current) =>
          previous.status != current.status,
      listener: (BuildContext context, LoginState state) {
        if (state.isSuccess) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text('Login successful!'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          // Navigate to home screen, keeping behaviour from the previous login.
          AppRouter.navigateAndClearStack(context, AppRouter.home);
        } else if (state.isFailure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  state.errorMessage ?? 'Login failed. Please try again.',
                ),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AutofillGroup(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: const <Widget>[
                    _LoginHeader(),
                    SizedBox(height: 48),
                    _EmailField(),
                    SizedBox(height: 16),
                    _PasswordField(),
                    SizedBox(height: 8),
                    _ForgotPasswordButton(),
                    SizedBox(height: 24),
                    _LoginButton(),
                    SizedBox(height: 24),
                    _OrDivider(),
                    SizedBox(height: 24),
                    _SocialLoginOptions(),
                    SizedBox(height: 32),
                    _RegisterLink(),
                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Login screen header with logo and welcome text.
class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.phone_in_talk_rounded,
            size: 40,
            color: AppColors.textOnPrimary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Welcome Back',
          style: AppTextStyles.h2.copyWith(
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to continue to ConnexUS',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Email input field.
class _EmailField extends StatelessWidget {
  const _EmailField();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      buildWhen: (LoginState previous, LoginState current) =>
          previous.email != current.email ||
          previous.status != current.status,
      builder: (BuildContext context, LoginState state) {
        return CustomTextField(
          key: const Key('loginForm_emailInput_textField'),
          labelText: 'Email',
          hintText: 'Enter your email address',
          errorText: state.email.displayError != null && !state.email.isPure
              ? state.email.errorMessage
              : null,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          enableSuggestions: false,
          autofillHints: const <String>[AutofillHints.email],
          prefixIcon: const Icon(
            Icons.email_outlined,
            color: AppColors.textTertiary,
          ),
          enabled: !state.isSubmitting,
          onChanged: (String email) {
            context.read<LoginBloc>().add(LoginEmailChanged(email));
          },
        );
      },
    );
  }
}

/// Password input field.
class _PasswordField extends StatelessWidget {
  const _PasswordField();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      buildWhen: (LoginState previous, LoginState current) =>
          previous.password != current.password ||
          previous.obscurePassword != current.obscurePassword ||
          previous.status != current.status,
      builder: (BuildContext context, LoginState state) {
        return CustomTextField(
          key: const Key('loginForm_passwordInput_textField'),
          labelText: 'Password',
          hintText: 'Enter your password',
          errorText:
              state.password.displayError != null && !state.password.isPure
                  ? state.password.errorMessage
                  : null,
          obscureText: state.obscurePassword,
          textInputAction: TextInputAction.done,
          autocorrect: false,
          enableSuggestions: false,
          autofillHints: const <String>[AutofillHints.password],
          prefixIcon: const Icon(
            Icons.lock_outline_rounded,
            color: AppColors.textTertiary,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              state.obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AppColors.textTertiary,
            ),
            onPressed: () {
              context
                  .read<LoginBloc>()
                  .add(const LoginPasswordVisibilityToggled());
            },
          ),
          enabled: !state.isSubmitting,
          onChanged: (String password) {
            context.read<LoginBloc>().add(LoginPasswordChanged(password));
          },
          onSubmitted: (_) {
            FocusScope.of(context).unfocus();
            context.read<LoginBloc>().add(const LoginSubmitted());
          },
        );
      },
    );
  }
}

/// Forgot password link button.
class _ForgotPasswordButton extends StatelessWidget {
  const _ForgotPasswordButton();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          // To be wired to the password reset screen in a later task.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Forgot password flow coming soon.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          'Forgot Password?',
          style: AppTextStyles.link,
        ),
      ),
    );
  }
}

/// Login submit button.
class _LoginButton extends StatelessWidget {
  const _LoginButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      builder: (BuildContext context, LoginState state) {
        return PrimaryButton(
          key: const Key('loginForm_submit_button'),
          text: 'Sign In',
          isLoading: state.isSubmitting,
          isEnabled: state.isValid,
          onPressed: () {
            FocusScope.of(context).unfocus();
            context.read<LoginBloc>().add(const LoginSubmitted());
          },
        );
      },
    );
  }
}

/// Visual divider between standard login and alternative options.
class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Expanded(child: Divider(color: AppColors.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.divider)),
      ],
    );
  }
}

/// Social login options (placeholders for future integration).
class _SocialLoginOptions extends StatelessWidget {
  const _SocialLoginOptions();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _SocialButton(
          icon: Icons.g_mobiledata_rounded,
          label: 'Google',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Google Sign In coming soon'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        const SizedBox(width: 16),
        _SocialButton(
          icon: Icons.apple_rounded,
          label: 'Apple',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Apple Sign In coming soon'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Individual social login button.
class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: Icon(icon, size: 24),
      label: Text(label),
    );
  }
}

/// Register link at the bottom of the screen.
class _RegisterLink extends StatelessWidget {
  const _RegisterLink();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          "Don't have an account? ",
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        TextButton(
          onPressed: () {
            AppRouter.navigateTo(context, AppRouter.register);
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Sign Up',
            style: AppTextStyles.link.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

