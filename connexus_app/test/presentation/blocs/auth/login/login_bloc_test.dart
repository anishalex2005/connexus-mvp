import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:connexus_app/presentation/bloc/auth/login/login.dart';

void main() {
  group('LoginBloc', () {
    late LoginBloc loginBloc;

    setUp(() {
      loginBloc = LoginBloc();
    });

    tearDown(() {
      loginBloc.close();
    });

    test('initial state is correct', () {
      expect(loginBloc.state, const LoginState());
    });

    group('LoginEmailChanged', () {
      blocTest<LoginBloc, LoginState>(
        'emits state with updated email',
        build: LoginBloc.new,
        act: (LoginBloc bloc) =>
            bloc.add(const LoginEmailChanged('test@example.com')),
        expect: () => <Matcher>[
          isA<LoginState>()
              .having(
                (LoginState s) => s.email.value,
                'email value',
                'test@example.com',
              )
              .having(
                (LoginState s) => s.email.isValid,
                'email isValid',
                true,
              ),
        ],
      );

      blocTest<LoginBloc, LoginState>(
        'emits invalid email state for malformed email',
        build: LoginBloc.new,
        act: (LoginBloc bloc) => bloc.add(const LoginEmailChanged('invalid')),
        expect: () => <Matcher>[
          isA<LoginState>()
              .having(
                (LoginState s) => s.email.value,
                'email value',
                'invalid',
              )
              .having(
                (LoginState s) => s.email.isValid,
                'email isValid',
                false,
              ),
        ],
      );
    });

    group('LoginPasswordChanged', () {
      blocTest<LoginBloc, LoginState>(
        'emits state with updated password',
        build: LoginBloc.new,
        act: (LoginBloc bloc) =>
            bloc.add(const LoginPasswordChanged('password123')),
        expect: () => <Matcher>[
          isA<LoginState>()
              .having(
                (LoginState s) => s.password.value,
                'password value',
                'password123',
              )
              .having(
                (LoginState s) => s.password.isValid,
                'password isValid',
                true,
              ),
        ],
      );
    });

    group('LoginPasswordVisibilityToggled', () {
      blocTest<LoginBloc, LoginState>(
        'toggles password visibility flag',
        build: LoginBloc.new,
        act: (LoginBloc bloc) =>
            bloc.add(const LoginPasswordVisibilityToggled()),
        expect: () => <Matcher>[
          isA<LoginState>().having(
            (LoginState s) => s.obscurePassword,
            'obscurePassword',
            false,
          ),
        ],
      );
    });

    group('LoginSubmitted', () {
      blocTest<LoginBloc, LoginState>(
        'does not move to submitting when form is invalid',
        build: LoginBloc.new,
        act: (LoginBloc bloc) => bloc.add(const LoginSubmitted()),
        expect: () => <Matcher>[
          isA<LoginState>()
              .having(
                (LoginState s) => s.status,
                'status',
                LoginStatus.initial,
              )
              .having(
                (LoginState s) => s.isValid,
                'isValid',
                false,
              ),
        ],
      );

      blocTest<LoginBloc, LoginState>(
        'emits submitting then success when form is valid',
        build: LoginBloc.new,
        seed: () => const LoginState(
          email: EmailInput.dirty('test@example.com'),
          password: LoginPasswordInput.dirty('password123'),
          isValid: true,
        ),
        act: (LoginBloc bloc) => bloc.add(const LoginSubmitted()),
        wait: const Duration(seconds: 3),
        expect: () => <Matcher>[
          isA<LoginState>().having(
            (LoginState s) => s.status,
            'status',
            LoginStatus.submitting,
          ),
          isA<LoginState>().having(
            (LoginState s) => s.status,
            'status',
            LoginStatus.success,
          ),
        ],
      );
    });
  });
}


