import 'package:equatable/equatable.dart';

/// Base class for login events.
abstract class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Event fired when the email input changes.
class LoginEmailChanged extends LoginEvent {
  const LoginEmailChanged(this.email);

  /// The new email value.
  final String email;

  @override
  List<Object?> get props => <Object?>[email];
}

/// Event fired when the password input changes.
class LoginPasswordChanged extends LoginEvent {
  const LoginPasswordChanged(this.password);

  /// The new password value.
  final String password;

  @override
  List<Object?> get props => <Object?>[password];
}

/// Event fired to toggle password visibility.
class LoginPasswordVisibilityToggled extends LoginEvent {
  const LoginPasswordVisibilityToggled();
}

/// Event fired when the form is submitted.
class LoginSubmitted extends LoginEvent {
  const LoginSubmitted();
}

/// Event fired to reset the form state.
class LoginReset extends LoginEvent {
  const LoginReset();
}


