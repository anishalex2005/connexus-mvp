import 'package:flutter/material.dart';
import '../base_screen.dart';
import '../../../core/routes/app_router.dart';

class LoginScreen extends BaseScreen {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends BaseScreenState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  String get appBarTitle => 'Sign in';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final form = _formKey.currentState;
    if (form == null) return;

    if (!form.validate()) {
      return;
    }

    // In a later task, this will call the real backend auth endpoint.
    // For now, just navigate to the home screen with mock "logged-in" state.
    AppRouter.navigateAndClearStack(context, AppRouter.home);
  }

  @override
  Widget buildContent(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.phone_in_talk,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Welcome to ConnexUS',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to view and manage your AI-powered calls.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Work email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _onSubmit,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Continue'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'For this early demo, any valid-looking email and an 8+ character password will sign you in.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
