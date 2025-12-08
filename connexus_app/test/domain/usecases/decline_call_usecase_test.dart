import 'package:connexus_app/data/repositories/call_repository.dart';
import 'package:connexus_app/data/services/telnyx_service.dart';
import 'package:connexus_app/domain/usecases/decline_call_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'decline_call_usecase_test.mocks.dart';

@GenerateMocks([TelnyxService, CallRepository])
void main() {
  late DeclineCallUseCase useCase;
  late MockTelnyxService mockTelnyxService;
  late MockCallRepository mockCallRepository;

  setUp(() {
    mockTelnyxService = MockTelnyxService();
    mockCallRepository = MockCallRepository();
    useCase = DeclineCallUseCase(
      telnyxService: mockTelnyxService,
      callRepository: mockCallRepository,
    );
  });

  group('DeclineCallUseCase', () {
    test('should return success when decline succeeds', () async {
      // Arrange
      when(mockTelnyxService.getCurrentCallInfo()).thenReturn(
        <String, dynamic>{
          'callId': 'test_call_123',
          'callerNumber': '+14155551234',
          'callerName': 'Test Caller',
          'direction': 'incoming',
        },
      );
      when(
        mockTelnyxService.declineCall(reason: anyNamed('reason')),
      ).thenAnswer((_) async => true);
      when(mockCallRepository.saveCallRecord(any))
          .thenAnswer((_) async {});

      // Act
      final DeclineCallResult result =
          await useCase.execute(reason: 'user_declined');

      // Assert
      expect(result.success, isTrue);
      expect(result.callId, 'test_call_123');
      verify(
        mockTelnyxService.declineCall(reason: 'user_declined'),
      ).called(1);
      verify(mockCallRepository.saveCallRecord(any)).called(1);
    });

    test('should return failure when decline fails', () async {
      // Arrange
      when(mockTelnyxService.getCurrentCallInfo()).thenReturn(null);
      when(
        mockTelnyxService.declineCall(reason: anyNamed('reason')),
      ).thenAnswer((_) async => false);

      // Act
      final DeclineCallResult result = await useCase.execute();

      // Assert
      expect(result.success, isFalse);
      expect(result.error, isNotNull);
      verifyNever(mockCallRepository.saveCallRecord(any));
    });

    test('should still succeed if logging fails', () async {
      // Arrange
      when(mockTelnyxService.getCurrentCallInfo()).thenReturn(
        <String, dynamic>{
          'callId': 'test_call_123',
          'callerNumber': '+14155551234',
          'callerName': 'Test Caller',
          'direction': 'incoming',
        },
      );
      when(
        mockTelnyxService.declineCall(reason: anyNamed('reason')),
      ).thenAnswer((_) async => true);
      when(mockCallRepository.saveCallRecord(any))
          .thenThrow(Exception('Database error'));

      // Act
      final DeclineCallResult result = await useCase.execute();

      // Assert
      expect(result.success, isTrue); // Decline succeeded even if logging failed
    });
  });
}


