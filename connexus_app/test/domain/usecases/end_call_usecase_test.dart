import 'package:connexus_app/core/constants/call_constants.dart';
import 'package:connexus_app/data/repositories/call_repository.dart';
import 'package:connexus_app/data/services/telnyx_service.dart';
import 'package:connexus_app/domain/usecases/end_call_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'end_call_usecase_test.mocks.dart';

@GenerateMocks(<Type>[TelnyxService, CallRepository])
void main() {
  late EndCallUseCase useCase;
  late MockTelnyxService mockTelnyxService;
  late MockCallRepository mockCallRepository;

  setUp(() {
    mockTelnyxService = MockTelnyxService();
    mockCallRepository = MockCallRepository();

    useCase = EndCallUseCase(
      telnyxService: mockTelnyxService,
      callRepository: mockCallRepository,
    );
  });

  group('EndCallUseCase', () {
    test('logs completed call when call info is available', () async {
      // Arrange
      when(mockTelnyxService.getCurrentCallInfo()).thenReturn(
        <String, dynamic>{
          'callId': 'call_123',
          'callerNumber': '+14155551234',
          'callerName': 'Test User',
          'direction': 'incoming',
        },
      );

      when(mockCallRepository.saveCallRecord(any))
          .thenAnswer((_) async {});

      // Act
      await useCase.execute(
        duration: const Duration(seconds: 65),
        reason: CallEndReason.userHangUp,
      );

      // Assert
      verify(mockCallRepository.saveCallRecord(any)).called(1);
    });

    test('does nothing when no current call info is available', () async {
      // Arrange
      when(mockTelnyxService.getCurrentCallInfo()).thenReturn(null);

      // Act
      await useCase.execute(
        duration: const Duration(seconds: 10),
        reason: CallEndReason.userHangUp,
      );

      // Assert
      verifyNever(mockCallRepository.saveCallRecord(any));
    });

    test('swallows repository errors so hang up flow is not broken', () async {
      // Arrange
      when(mockTelnyxService.getCurrentCallInfo()).thenReturn(
        <String, dynamic>{
          'callId': 'call_123',
          'callerNumber': '+14155551234',
          'callerName': 'Test User',
          'direction': 'incoming',
        },
      );

      when(mockCallRepository.saveCallRecord(any))
          .thenThrow(Exception('storage failure'));

      // Act & Assert
      await useCase.execute(
        duration: const Duration(seconds: 30),
        reason: CallEndReason.networkError,
      );

      verify(mockCallRepository.saveCallRecord(any)).called(1);
    });
  });
}


