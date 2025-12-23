import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import 'package:connexus_app/presentation/bloc/active_call/active_call_bloc.dart';
import 'package:connexus_app/presentation/bloc/active_call/active_call_event.dart';
import 'package:connexus_app/presentation/bloc/active_call/active_call_state.dart';
import 'package:connexus_app/presentation/screens/call/active_call_screen.dart';
import 'package:connexus_app/domain/models/active_call_state_model.dart';

class MockActiveCallBloc
    extends MockBloc<ActiveCallEvent, ActiveCallState>
    implements ActiveCallBloc {}

void main() {
  late MockActiveCallBloc mockBloc;

  setUp(() {
    mockBloc = MockActiveCallBloc();
  });

  Widget createTestWidget() {
    return MaterialApp(
      home: BlocProvider<ActiveCallBloc>.value(
        value: mockBloc,
        child: const ActiveCallScreen(),
      ),
    );
  }

  group('ActiveCallScreen', () {
    testWidgets('displays caller information', (WidgetTester tester) async {
      when(() => mockBloc.state).thenReturn(
        ActiveCallInProgress(
          callState: ActiveCallStateModel(
            callId: 'test-123',
            callerName: 'Test User',
            callerNumber: '+1234567890',
            callStartTime: DateTime.now(),
          ),
        ),
      );

      await tester.pumpWidget(createTestWidget());

      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('+1234567890'), findsOneWidget);
    });

    testWidgets('displays call controls', (WidgetTester tester) async {
      when(() => mockBloc.state).thenReturn(
        ActiveCallInProgress(
          callState: ActiveCallStateModel(
            callId: 'test-123',
            callerName: 'Test User',
            callerNumber: '+1234567890',
            callStartTime: DateTime.now(),
          ),
        ),
      );

      await tester.pumpWidget(createTestWidget());

      expect(find.text('Mute'), findsOneWidget);
      expect(find.text('Speaker'), findsOneWidget);
      expect(find.text('Keypad'), findsOneWidget);
      expect(find.text('Hold'), findsOneWidget);
      expect(find.text('Transfer'), findsOneWidget);
    });

    testWidgets('end call button is visible', (WidgetTester tester) async {
      when(() => mockBloc.state).thenReturn(
        ActiveCallInProgress(
          callState: ActiveCallStateModel(
            callId: 'test-123',
            callerName: 'Test User',
            callerNumber: '+1234567890',
            callStartTime: DateTime.now(),
          ),
        ),
      );

      await tester.pumpWidget(createTestWidget());

      expect(find.byIcon(Icons.call_end), findsOneWidget);
      expect(find.text('End Call'), findsOneWidget);
    });
  });
}


