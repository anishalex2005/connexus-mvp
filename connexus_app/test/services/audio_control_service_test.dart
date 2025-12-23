import 'package:connexus_app/data/services/audio_control_service.dart';
import 'package:connexus_app/domain/models/audio_control_state.dart';
import 'package:connexus_app/domain/models/audio_output_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AudioControlState', () {
    test('initial state has correct defaults', () {
      final AudioControlState state = AudioControlState.initial();

      expect(state.isMuted, false);
      expect(state.isSpeakerOn, false);
      expect(state.currentOutput, AudioOutputType.earpiece);
      expect(state.isBluetoothConnected, false);
      expect(state.isWiredHeadsetConnected, false);
      expect(state.isChangingAudio, false);
      expect(state.errorMessage, isNull);
    });

    test('copyWith creates new state with updated values', () {
      final AudioControlState initial = AudioControlState.initial();
      final AudioControlState updated = initial.copyWith(
        isMuted: true,
        isSpeakerOn: true,
        currentOutput: AudioOutputType.speaker,
      );

      expect(updated.isMuted, true);
      expect(updated.isSpeakerOn, true);
      expect(updated.currentOutput, AudioOutputType.speaker);

      // Original unchanged.
      expect(initial.isMuted, false);
      expect(initial.isSpeakerOn, false);
    });

    test('equality comparison works correctly', () {
      final AudioControlState state1 = AudioControlState.initial();
      final AudioControlState state2 = AudioControlState.initial();
      final AudioControlState state3 =
          state1.copyWith(isMuted: true);

      expect(state1, equals(state2));
      expect(state1, isNot(equals(state3)));
    });

    test('error factory creates state with error message', () {
      final AudioControlState initial = AudioControlState.initial();
      final AudioControlState errorState =
          AudioControlState.error('Test error', initial);

      expect(errorState.errorMessage, 'Test error');
      expect(errorState.isChangingAudio, false);
    });
  });

  group('AudioOutputType', () {
    test('displayName returns correct strings', () {
      expect(AudioOutputType.earpiece.displayName, 'Earpiece');
      expect(AudioOutputType.speaker.displayName, 'Speaker');
      expect(AudioOutputType.bluetooth.displayName, 'Bluetooth');
      expect(AudioOutputType.wiredHeadset.displayName, 'Headphones');
    });

    test('isHandsFree returns true for speaker and bluetooth', () {
      expect(AudioOutputType.speaker.isHandsFree, true);
      expect(AudioOutputType.bluetooth.isHandsFree, true);
      expect(AudioOutputType.earpiece.isHandsFree, false);
      expect(AudioOutputType.wiredHeadset.isHandsFree, false);
    });
  });

  group('AudioControlException', () {
    test('toString returns formatted message', () {
      final AudioControlException exception =
          AudioControlException('Test message');
      expect(
        exception.toString(),
        'AudioControlException: Test message',
      );
    });
  });
}


