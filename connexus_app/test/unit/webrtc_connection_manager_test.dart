import 'package:connexus_app/data/services/webrtc_connection_manager.dart';
import 'package:connexus_app/domain/models/connection_state.dart';
import 'package:connexus_app/domain/models/webrtc_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WebRTCConnectionManager', () {
    late WebRTCConnectionManager manager;

    setUp(() {
      manager = WebRTCConnectionManager();
    });

    tearDown(() async {
      await manager.dispose();
    });

    test('initial state should be idle', () {
      expect(manager.currentState, equals(WebRTCConnectionState.idle));
    });

    test(
      'should emit connecting state on initialize',
      () async {
        // Arrange
        final List<WebRTCConnectionState> states = <WebRTCConnectionState>[];
        final subscription = manager.connectionState.listen(states.add);

        // Act - Note: This will actually try to create a peer connection.
        // In a real test environment, you might mock createPeerConnection.
        try {
          await manager.initialize();
        } catch (_) {
          // Expected to fail in test environment without WebRTC support.
        }

        // Assert
        expect(states, contains(WebRTCConnectionState.connecting));
        await subscription.cancel();
      },
      skip:
          'Requires flutter_webrtc bindings; skip in pure unit test environment.',
    );
  });

  group('WebRTCConfig', () {
    test('should create default Telnyx config with STUN servers', () {
      final config = WebRTCConfig.telnyxDefault();

      expect(config.iceServers, isNotEmpty);
      expect(
        config.iceServers.any((IceServerConfig s) => s.url.contains('stun')),
        isTrue,
      );
    });

    test('should include TURN server when credentials provided', () {
      final config = WebRTCConfig.telnyxDefault(
        turnUsername: 'test_user',
        turnPassword: 'test_pass',
      );

      expect(
        config.iceServers.any((IceServerConfig s) => s.url.contains('turn')),
        isTrue,
      );
    });

    test('should convert to RTCConfiguration format', () {
      final config = WebRTCConfig.telnyxDefault();
      final rtcConfig = config.toRTCConfiguration();

      expect(rtcConfig['iceServers'], isNotEmpty);
      expect(rtcConfig['bundlePolicy'], equals('max-bundle'));
    });
  });

  group('ConnectionQuality', () {
    test('should calculate excellent quality for low RTT', () {
      final quality = ConnectionQuality.fromStats(<String, dynamic>{
        'roundTripTime': 50.0,
        'packetsLost': 0.0,
        'jitter': 5.0,
      });

      expect(quality.qualityLevel, equals('excellent'));
    });

    test('should calculate poor quality for high RTT', () {
      final quality = ConnectionQuality.fromStats(<String, dynamic>{
        'roundTripTime': 500.0,
        'packetsLost': 10.0,
        'jitter': 100.0,
      });

      expect(quality.qualityLevel, equals('poor'));
    });
  });

  group('IceServerConfig', () {
    test('should create basic STUN config', () {
      const config = IceServerConfig(url: 'stun:stun.l.google.com:19302');
      final map = config.toMap();

      expect(map['urls'], equals('stun:stun.l.google.com:19302'));
      expect(map.containsKey('username'), isFalse);
    });

    test('should create TURN config with credentials', () {
      const config = IceServerConfig(
        url: 'turn:turn.example.com:3478',
        username: 'user',
        credential: 'pass',
      );
      final map = config.toMap();

      expect(map['urls'], equals('turn:turn.example.com:3478'));
      expect(map['username'], equals('user'));
      expect(map['credential'], equals('pass'));
    });
  });
}
