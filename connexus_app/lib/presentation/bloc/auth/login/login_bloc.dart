import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';

import 'login_event.dart';
import 'login_state.dart';
import 'models/models.dart';

/// BLoC for managing login form state.
///
/// Handles form validation, submission, and high-level auth flow.
/// Actual backend integration will be added in a later task.
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(const LoginState()) {
    on<LoginEmailChanged>(_onEmailChanged);
    on<LoginPasswordChanged>(_onPasswordChanged);
    on<LoginPasswordVisibilityToggled>(_onPasswordVisibilityToggled);
    on<LoginSubmitted>(_onSubmitted);
    on<LoginReset>(_onReset);
  }

  void _onEmailChanged(
    LoginEmailChanged event,
    Emitter<LoginState> emit,
  ) {
    final EmailInput email = EmailInput.dirty(event.email);
    emit(
      state.copyWith(
        email: email,
        isValid: Formz.validate(
          <FormzInput<dynamic, dynamic>>[email, state.password],
        ),
        status: LoginStatus.initial,
        errorMessage: null,
      ),
    );
  }

  void _onPasswordChanged(
    LoginPasswordChanged event,
    Emitter<LoginState> emit,
  ) {
    final LoginPasswordInput password =
        LoginPasswordInput.dirty(event.password);
    emit(
      state.copyWith(
        password: password,
        isValid: Formz.validate(
          <FormzInput<dynamic, dynamic>>[state.email, password],
        ),
        status: LoginStatus.initial,
        errorMessage: null,
      ),
    );
  }

  void _onPasswordVisibilityToggled(
    LoginPasswordVisibilityToggled event,
    Emitter<LoginState> emit,
  ) {
    emit(
      state.copyWith(
        obscurePassword: !state.obscurePassword,
      ),
    );
  }

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    // Re-run validation for both fields.
    final EmailInput email = EmailInput.dirty(state.email.value);
    final LoginPasswordInput password =
        LoginPasswordInput.dirty(state.password.value);

    final bool isValid = Formz.validate(
      <FormzInput<dynamic, dynamic>>[email, password],
    );

    emit(
      state.copyWith(
        email: email,
        password: password,
        isValid: isValid,
      ),
    );

    if (!isValid) {
      return;
    }

    emit(
      state.copyWith(
        status: LoginStatus.submitting,
        errorMessage: null,
      ),
    );

    try {
      // TODO(Task 28): Replace with real API call to backend auth endpoint.
      await Future<void>.delayed(const Duration(seconds: 2));

      emit(
        state.copyWith(
          status: LoginStatus.success,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          errorMessage: _mapErrorToMessage(error),
        ),
      );
    }
  }

  void _onReset(
    LoginReset event,
    Emitter<LoginState> emit,
  ) {
    emit(const LoginState());
  }

  String _mapErrorToMessage(Object error) {
    // TODO(Task 28): Map concrete error types to friendly messages.
    return 'Login failed. Please check your credentials and try again.';
  }
}


