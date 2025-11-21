// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:connexus_app/app.dart';
import 'package:connexus_app/core/config/app_config.dart';

void main() {
  testWidgets('ConnexUSApp builds', (WidgetTester tester) async {
    // Initialize configuration for tests (development environment)
    await AppConfig.initialize(Environment.development);

    await tester.pumpWidget(const ConnexUSApp());
    expect(find.byType(ConnexUSApp), findsOneWidget);
  });
}
