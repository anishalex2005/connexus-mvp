import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:connexus_app/data/models/call_quality_metrics.dart';
import 'package:connexus_app/presentation/widgets/call_quality_indicator.dart';

void main() {
  group('CallQualityIndicator', () {
    testWidgets('displays quality level name', (WidgetTester tester) async {
      final CallQualityMetrics metrics = CallQualityMetrics(
        timestamp: DateTime.now(),
        roundTripTime: 50.0,
        jitter: 10.0,
        packetLossPercent: 0.1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CallQualityIndicator(metrics: metrics),
          ),
        ),
      );

      expect(find.text('Excellent'), findsOneWidget);
    });

    testWidgets(
      'shows details when showDetails is true',
      (WidgetTester tester) async {
        final CallQualityMetrics metrics = CallQualityMetrics(
          timestamp: DateTime.now(),
          roundTripTime: 100.0,
          jitter: 25.0,
          packetLossPercent: 1.5,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CallQualityIndicator(
                metrics: metrics,
                showDetails: true,
              ),
            ),
          ),
        );

        expect(find.textContaining('RTT:'), findsOneWidget);
        expect(find.textContaining('Loss:'), findsOneWidget);
        expect(find.textContaining('Jitter:'), findsOneWidget);
      },
    );

    testWidgets(
      'handles null metrics gracefully',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CallQualityIndicator(metrics: null),
            ),
          ),
        );

        // Should show "Good" as default when no metrics.
        expect(find.text('Good'), findsOneWidget);
      },
    );

    testWidgets('calls onTap when tapped', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CallQualityIndicator(
              metrics: CallQualityMetrics.empty(),
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CallQualityIndicator));
      expect(tapped, isTrue);
    });
  });

  group('CallQualityDetailsCard', () {
    testWidgets('displays all metrics', (WidgetTester tester) async {
      final CallQualityMetrics metrics = CallQualityMetrics(
        timestamp: DateTime.now(),
        roundTripTime: 100.0,
        jitter: 25.0,
        packetLossPercent: 1.5,
        audioBitrate: 48.0,
        audioCodec: 'opus',
        localCandidateType: 'host',
        remoteCandidateType: 'srflx',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CallQualityDetailsCard(metrics: metrics),
            ),
          ),
        ),
      );

      expect(find.text('Round Trip Time'), findsOneWidget);
      expect(find.text('Packet Loss'), findsOneWidget);
      expect(find.text('Jitter'), findsOneWidget);
      expect(find.text('Audio Bitrate'), findsOneWidget);
      expect(find.text('Codec'), findsOneWidget);
      expect(find.textContaining('opus'), findsOneWidget);
    });

    testWidgets(
      'shows message when metrics is null',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CallQualityDetailsCard(metrics: null),
            ),
          ),
        );

        expect(find.text('No quality data available'), findsOneWidget);
      },
    );
  });
}
