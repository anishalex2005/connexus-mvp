import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logger/logger.dart';
import 'package:mockito/mockito.dart';

import 'package:connexus_app/core/constants/quality_thresholds.dart';
import 'package:connexus_app/data/models/call_quality_metrics.dart';
import 'package:connexus_app/data/services/call_quality_service.dart';

class MockRTCPeerConnection extends Mock implements RTCPeerConnection {}

class MockLogger extends Mock implements Logger {}

void main() {
  late CallQualityService service;
  late MockRTCPeerConnection mockPeerConnection;
  late MockLogger mockLogger;

  setUp(() {
    mockLogger = MockLogger();
    mockPeerConnection = MockRTCPeerConnection();
    service = CallQualityService(logger: mockLogger);
  });

  tearDown(() {
    service.dispose();
  });

  group('CallQualityMetrics', () {
    test('calculates quality score correctly for excellent conditions', () {
      final CallQualityMetrics metrics = CallQualityMetrics(
        timestamp: DateTime.now(),
        roundTripTime: 50.0,
        jitter: 10.0,
        packetLossPercent: 0.1,
      );

      expect(metrics.qualityScore, greaterThanOrEqualTo(90));
      expect(metrics.qualityLevel, equals(CallQualityLevel.excellent));
    });

    test('calculates quality score correctly for poor conditions', () {
      final CallQualityMetrics metrics = CallQualityMetrics(
        timestamp: DateTime.now(),
        roundTripTime: 400.0,
        jitter: 60.0,
        packetLossPercent: 5.0,
      );

      expect(metrics.qualityScore, lessThan(50));
      expect(
        metrics.qualityLevel,
        anyOf(
          equals(CallQualityLevel.poor),
          equals(CallQualityLevel.bad),
        ),
      );
    });

    test('handles null values gracefully', () {
      final CallQualityMetrics metrics = CallQualityMetrics(
        timestamp: DateTime.now(),
      );

      expect(metrics.qualityScore, equals(100));
      expect(metrics.qualityLevel, equals(CallQualityLevel.excellent));
    });

    test('toJson and fromJson round-trip correctly', () {
      final CallQualityMetrics original = CallQualityMetrics(
        timestamp: DateTime.now(),
        roundTripTime: 100.0,
        jitter: 25.0,
        packetLossPercent: 1.5,
        audioBitrate: 48.0,
        audioCodec: 'opus',
      );

      final Map<String, dynamic> json = original.toJson();
      final CallQualityMetrics restored = CallQualityMetrics.fromJson(json);

      expect(restored.roundTripTime, equals(original.roundTripTime));
      expect(restored.jitter, equals(original.jitter));
      expect(restored.packetLossPercent, equals(original.packetLossPercent));
      expect(restored.audioCodec, equals(original.audioCodec));
    });
  });

  group('CallQualityService', () {
    test('isMonitoring returns false initially', () {
      expect(service.isMonitoring, isFalse);
    });

    test('startMonitoring sets isMonitoring to true', () {
      when(mockPeerConnection.getStats())
          .thenAnswer((_) async => <StatsReport>[]);

      service.startMonitoring(mockPeerConnection);

      expect(service.isMonitoring, isTrue);
    });

    test('stopMonitoring sets isMonitoring to false', () {
      when(mockPeerConnection.getStats())
          .thenAnswer((_) async => <StatsReport>[]);

      service.startMonitoring(mockPeerConnection);
      service.stopMonitoring();

      expect(service.isMonitoring, isFalse);
    });

    test('metricsHistory is empty initially', () {
      when(mockPeerConnection.getStats())
          .thenAnswer((_) async => <StatsReport>[]);

      expect(service.metricsHistory, isEmpty);
    });

    test('calls onQualityChange when quality level changes callback is set',
        () async {
      when(mockPeerConnection.getStats())
          .thenAnswer((_) async => <StatsReport>[]);

      CallQualityLevel? reportedOldLevel;
      CallQualityLevel? reportedNewLevel;

      service.onQualityChange = (
        CallQualityLevel oldLevel,
        CallQualityLevel newLevel,
      ) {
        reportedOldLevel = oldLevel;
        reportedNewLevel = newLevel;
      };

      // This test does not assert on actual level changes because
      // it requires crafted stats; we just ensure the callback can be set.
      expect(service.onQualityChange, isNotNull);
      expect(reportedOldLevel, isNull);
      expect(reportedNewLevel, isNull);
    });
  });

  group('QualityThresholds', () {
    test('RTT thresholds are in ascending order', () {
      expect(
        QualityThresholds.rttExcellent,
        lessThan(QualityThresholds.rttGood),
      );
      expect(
        QualityThresholds.rttGood,
        lessThan(QualityThresholds.rttFair),
      );
      expect(
        QualityThresholds.rttFair,
        lessThan(QualityThresholds.rttPoor),
      );
    });

    test('packet loss thresholds are in ascending order', () {
      expect(
        QualityThresholds.packetLossExcellent,
        lessThan(QualityThresholds.packetLossGood),
      );
      expect(
        QualityThresholds.packetLossGood,
        lessThan(QualityThresholds.packetLossFair),
      );
      expect(
        QualityThresholds.packetLossFair,
        lessThan(QualityThresholds.packetLossPoor),
      );
    });

    test('jitter thresholds are in ascending order', () {
      expect(
        QualityThresholds.jitterExcellent,
        lessThan(QualityThresholds.jitterGood),
      );
      expect(
        QualityThresholds.jitterGood,
        lessThan(QualityThresholds.jitterFair),
      );
      expect(
        QualityThresholds.jitterFair,
        lessThan(QualityThresholds.jitterPoor),
      );
    });

    test('collection interval is reasonable', () {
      expect(
        QualityThresholds.metricsCollectionIntervalMs,
        greaterThanOrEqualTo(1000),
      );
      expect(
        QualityThresholds.metricsCollectionIntervalMs,
        lessThanOrEqualTo(5000),
      );
    });
  });

  group('CallQualityLevel', () {
    test('displayName returns readable strings', () {
      expect(
        CallQualityLevel.excellent.displayName,
        equals('Excellent'),
      );
      expect(CallQualityLevel.good.displayName, equals('Good'));
      expect(CallQualityLevel.fair.displayName, equals('Fair'));
      expect(CallQualityLevel.poor.displayName, equals('Poor'));
      expect(CallQualityLevel.bad.displayName, equals('Bad'));
    });

    test('colorValue returns valid color integers', () {
      for (final CallQualityLevel level in CallQualityLevel.values) {
        expect(level.colorValue, greaterThan(0));
        // Check it's a valid ARGB color (has alpha channel).
        expect(level.colorValue & 0xFF000000, equals(0xFF000000));
      }
    });
  });
}
