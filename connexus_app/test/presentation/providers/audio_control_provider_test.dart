import 'dart:async';

import 'package:connexus_app/data/services/audio_control_service.dart';
import 'package:connexus_app/domain/models/audio_control_state.dart';
import 'package:connexus_app/domain/models/audio_output_type.dart';
import 'package:connexus_app/presentation/providers/audio_control_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxdart/rxdart.dart';

/// Simple fake service used to drive [AudioControlProvider] in tests.
class FakeAudioControlService implements AudioControlService {
  final BehaviorSubject<AudioControlState> _subject =
      BehaviorSubject<AudioControlState>.seeded(
    AudioControlState.initial(),
  );

  bool _initialized = false;

  @override
  Stream<AudioControlState> get stateStream => _subject.stream;

  @override
  AudioControlState get currentState => _subject.value;

  @override
  bool get isInitialized => _initialized;

  @override
  bool get isMuted => currentState.isMuted;

  @override
  bool get isSpeakerOn => currentState.isSpeakerOn;

  @override
  Future<void> initialize() async {
    _initialized = true;
  }

  @override
  Future<bool> toggleMute() async {
    final bool newMuted = !currentState.isMuted;
    _subject.add(currentState.copyWith(isMuted: newMuted));
    return newMuted;
  }

  @override
  Future<void> setMuted(bool muted) async {
    _subject.add(currentState.copyWith(isMuted: muted));
  }

  @override
  Future<bool> toggleSpeaker() async {
    final bool newSpeaker = !currentState.isSpeakerOn;
    _subject.add(currentState.copyWith(isSpeakerOn: newSpeaker));
    return newSpeaker;
  }

  @override
  Future<void> setSpeaker(bool enabled) async {
    _subject.add(currentState.copyWith(isSpeakerOn: enabled));
  }

  @override
  Future<void> setAudioOutput(AudioOutputType outputType) async {
    _subject.add(currentState.copyWith(currentOutput: outputType));
  }

  @override
  Future<void> resetForCallEnd() async {
    _subject.add(AudioControlState.initial());
  }

  @override
  Future<void> dispose() async {
    await _subject.close();
  }
}

void main() {
  late FakeAudioControlService fakeService;
  late AudioControlProvider provider;

  setUp(() {
    fakeService = FakeAudioControlService();
    provider = AudioControlProvider(audioService: fakeService);
  });

  tearDown(() async {
    await fakeService.dispose();
    provider.dispose();
  });

  group('AudioControlProvider', () {
    test('initial state matches service state', () {
      expect(provider.isMuted, false);
      expect(provider.isSpeakerOn, false);
      expect(provider.currentOutput, AudioOutputType.earpiece);
    });

    test('updates when service emits new state', () async {
      await fakeService.setMuted(true);
      await Future<void>.delayed(Duration.zero);

      expect(provider.isMuted, true);
    });

    test('toggleMute delegates to service', () async {
      await provider.toggleMute();
      expect(provider.isMuted, true);

      await provider.toggleMute();
      expect(provider.isMuted, false);
    });

    test('toggleSpeaker delegates to service', () async {
      await provider.toggleSpeaker();
      expect(provider.isSpeakerOn, true);
    });

    test('setAudioOutput delegates to service', () async {
      await provider.setAudioOutput(AudioOutputType.speaker);
      expect(provider.currentOutput, AudioOutputType.speaker);
    });

    test('clearError removes error message', () async {
      // Push a state with error.
      fakeService._subject.add(
        AudioControlState.initial().copyWith(
          errorMessage: 'Test error',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(provider.errorMessage, 'Test error');

      provider.clearError();
      expect(provider.errorMessage, isNull);
    });
  });
}


