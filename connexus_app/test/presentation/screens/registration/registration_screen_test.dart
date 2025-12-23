import 'package:connexus_app/core/constants/registration_strings.dart';
import 'package:connexus_app/presentation/screens/login/registration_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestApp() {
    return const MaterialApp(
      home: RegistrationScreen(),
    );
  }

  group('RegistrationScreen', () {
    testWidgets('renders core fields and texts', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      expect(find.text(RegistrationStrings.screenTitle), findsOneWidget);
      expect(find.text(RegistrationStrings.firstNameLabel), findsOneWidget);
      expect(find.text(RegistrationStrings.lastNameLabel), findsOneWidget);
      expect(find.text(RegistrationStrings.emailLabel), findsOneWidget);
      expect(find.text(RegistrationStrings.passwordLabel), findsOneWidget);
      expect(
        find.text(RegistrationStrings.confirmPasswordLabel),
        findsOneWidget,
      );
      expect(
        find.text(RegistrationStrings.createAccountButton),
        findsOneWidget,
      );
    });

    testWidgets('shows validation errors when submitting empty form',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      await tester.tap(
        find.text(RegistrationStrings.createAccountButton),
      );
      await tester.pumpAndSettle();

      expect(find.text(RegistrationStrings.firstNameRequired), findsOneWidget);
      expect(find.text(RegistrationStrings.lastNameRequired), findsOneWidget);
      expect(find.text(RegistrationStrings.emailRequired), findsOneWidget);
      expect(
        find.text(RegistrationStrings.passwordRequired),
        findsWidgets,
      );
    });

    testWidgets('shows terms error when not accepted',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'John',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Doe',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'john.doe@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(3),
        'StrongP@ss1',
      );
      await tester.enterText(
        find.byType(TextFormField).at(4),
        'StrongP@ss1',
      );

      await tester.tap(
        find.text(RegistrationStrings.createAccountButton),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(RegistrationStrings.termsRequired),
        findsOneWidget,
      );
    });

    testWidgets('password strength indicator updates with input',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      await tester.enterText(
        find.byType(TextFormField).at(3),
        '123',
      );
      await tester.pump();

      expect(find.text(RegistrationStrings.strengthWeak), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField).at(3),
        'StrongP@ss1',
      );
      await tester.pump();

      expect(find.text(RegistrationStrings.strengthStrong), findsOneWidget);
    });
  });
}


