import 'package:connexus_app/data/models/telnyx_credentials.dart';
import 'package:connexus_app/data/services/secure_storage_service.dart';
import 'package:connexus_app/data/services/telnyx_service.dart';
import 'package:connexus_app/domain/telephony/telnyx_connection_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([SecureStorageService])
import 'telnyx_service_test.mocks.dart';

void main() {
  late TelnyxService telnyxService;
  late MockSecureStorageService mockSecureStorage;

  setUp(() {
    mockSecureStorage = MockSecureStorageService();
    telnyxService = TelnyxService(
      secureStorage: mockSecureStorage,
      retryConfig: const TelnyxRetryConfig(
        maxAttempts: 3,
        initialDelay: Duration(milliseconds: 100),
        maxDelay: Duration(milliseconds: 500),
        backoffMultiplier: 2.0,
      ),
    );
  });

  tearDown(() {
    telnyxService.dispose();
  });

  group('TelnyxService', () {
    group('initial state', () {
      test('should start with disconnected state', () {
        expect(
          telnyxService.connectionState,
          equals(TelnyxConnectionState.disconnected),
        );
      });

      test('isConnected should be false initially', () {
        expect(telnyxService.isConnected, isFalse);
      });
    });

    group('credentials validation', () {
      test('should reject empty credentials', () async {
        final credentials = TelnyxCredentials.empty();

        final result = await telnyxService.connect(credentials);

        expect(result, isFalse);
        expect(
          telnyxService.connectionState,
          equals(TelnyxConnectionState.failed),
        );
      });

      test('should reject credentials with empty username', () async {
        const credentials = TelnyxCredentials(
          sipUsername: '',
          sipPassword: 'test_password',
        );

        final result = await telnyxService.connect(credentials);

        expect(result, isFalse);
      });
    });

    group('connectWithStoredCredentials', () {
      test('should fail when no credentials stored', () async {
        when(mockSecureStorage.getTelnyxCredentials())
            .thenAnswer((_) async => null);

        final result = await telnyxService.connectWithStoredCredentials();

        expect(result, isFalse);
        verify(mockSecureStorage.getTelnyxCredentials()).called(1);
      });

      test('should fail when stored credentials are invalid', () async {
        when(mockSecureStorage.getTelnyxCredentials())
            .thenAnswer((_) async => TelnyxCredentials.empty());

        final result = await telnyxService.connectWithStoredCredentials();

        expect(result, isFalse);
      });
    });

    group('retry configuration', () {
      test('should calculate correct delays for attempts', () {
        const config = TelnyxRetryConfig(
          initialDelay: Duration(seconds: 1),
          maxDelay: Duration(seconds: 30),
          backoffMultiplier: 2.0,
        );

        expect(
          config.getDelayForAttempt(1),
          equals(const Duration(seconds: 1)),
        );
        expect(
          config.getDelayForAttempt(2),
          equals(const Duration(seconds: 2)),
        );
        expect(
          config.getDelayForAttempt(3),
          equals(const Duration(seconds: 4)),
        );
      });

      test('should cap delay at maxDelay', () {
        const config = TelnyxRetryConfig(
          initialDelay: Duration(seconds: 10),
          maxDelay: Duration(seconds: 30),
          backoffMultiplier: 2.0,
        );

        expect(
          config.getDelayForAttempt(10),
          equals(const Duration(seconds: 30)),
        );
      });
    });

    group('disconnect', () {
      test('should update state to loggedOut', () async {
        await telnyxService.disconnect();

        expect(
          telnyxService.connectionState,
          equals(TelnyxConnectionState.loggedOut),
        );
      });
    });

    group('connection state stream', () {
      test('should emit state changes', () async {
        final states = <TelnyxConnectionState>[];

        final subscription =
            telnyxService.connectionStateStream.listen(states.add);

        await telnyxService.disconnect();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(states, contains(TelnyxConnectionState.loggedOut));
        await subscription.cancel();
      });
    });
  });

  group('TelnyxCredentials', () {
    test('should create valid credentials from JSON', () {
      final json = <String, dynamic>{
        'sip_username': 'test_user',
        'sip_password': 'test_pass',
        'caller_id_name': 'Test User',
        'caller_id_number': '+15551234567',
      };

      final credentials = TelnyxCredentials.fromJson(json);

      expect(credentials.sipUsername, equals('test_user'));
      expect(credentials.sipPassword, equals('test_pass'));
      expect(credentials.callerIdName, equals('Test User'));
      expect(credentials.callerIdNumber, equals('+15551234567'));
      expect(credentials.isValid, isTrue);
    });

    test('should convert to JSON correctly', () {
      const credentials = TelnyxCredentials(
        sipUsername: 'test_user',
        sipPassword: 'test_pass',
        callerIdName: 'Test User',
      );

      final json = credentials.toJson();

      expect(json['sip_username'], equals('test_user'));
      expect(json['sip_password'], equals('test_pass'));
      expect(json['caller_id_name'], equals('Test User'));
    });

    test('empty credentials should be invalid', () {
      final credentials = TelnyxCredentials.empty();

      expect(credentials.isValid, isFalse);
      expect(credentials.sipUsername, isEmpty);
    });
  });

  group('TelnyxConnectionState extensions', () {
    test('isConnected should only be true for registered', () {
      expect(TelnyxConnectionState.registered.isConnected, isTrue);
      expect(TelnyxConnectionState.connecting.isConnected, isFalse);
      expect(TelnyxConnectionState.disconnected.isConnected, isFalse);
    });

    test('isConnecting should be true for connecting states', () {
      expect(TelnyxConnectionState.connecting.isConnecting, isTrue);
      expect(TelnyxConnectionState.reconnecting.isConnecting, isTrue);
      expect(TelnyxConnectionState.registered.isConnecting, isFalse);
    });

    test('canMakeCalls should only be true when registered', () {
      expect(TelnyxConnectionState.registered.canMakeCalls, isTrue);
      expect(TelnyxConnectionState.connecting.canMakeCalls, isFalse);
      expect(TelnyxConnectionState.failed.canMakeCalls, isFalse);
    });
  });
}
