import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

import '../../core/services/audio_service.dart';
import '../../domain/models/audio_control_state.dart';
import '../../domain/models/audio_output_type.dart';
import 'media_handler.dart';

/// Service responsible for managing audio controls during calls.
///
/// This service handles:
/// - Microphone mute/unmute (via [MediaHandler] and native channel)
/// - Speaker/earpiece toggle
/// - Bluetooth / wired headset detection
/// - Audio session configuration for VoIP calls
///
/// It is designed to complement the existing [AudioService] and
/// [MediaHandler] so that higher-level call logic (BLoC/Provider)
/// can react to a single stream of [AudioControlState].
class AudioControlService {
  /// Platform channel for native audio control.
  ///
  /// Reuses the same channel as [AudioService] to avoid duplicating
  /// native wiring.
  @visibleForTesting
  static const MethodChannel channel = MethodChannel('com.connexus/audio');

  /// Audio session instance for configuration.
  AudioSession? _audioSession;

  /// Underlying media handler controlling WebRTC tracks.
  final MediaHandler _mediaHandler;

  /// System-level audio service for ringtones and audio modes.
  final AudioService _audioService;

  /// Stream controller for audio state changes.
  final BehaviorSubject<AudioControlState> _stateController =
      BehaviorSubject<AudioControlState>.seeded(
    AudioControlState.initial(),
  );

  /// Subscription for audio device changes.
  StreamSubscription<AudioDevicesChangedEvent>? _devicesSubscription;

  /// Subscription for audio interruptions.
  StreamSubscription<AudioInterruptionEvent>? _interruptionSubscription;

  /// Whether the service has been initialized.
  bool _isInitialized = false;

  AudioControlService({
    required MediaHandler mediaHandler,
    required AudioService audioService,
  })  : _mediaHandler = mediaHandler,
        _audioService = audioService;

  /// Stream of audio control state changes.
  Stream<AudioControlState> get stateStream => _stateController.stream;

  /// Current audio control state.
  AudioControlState get currentState => _stateController.value;

  /// Whether the microphone is currently muted.
  bool get isMuted => currentState.isMuted;

  /// Whether the speaker is currently enabled.
  bool get isSpeakerOn => currentState.isSpeakerOn;

  /// Whether the service has been initialized.
  bool get isInitialized => _isInitialized;

  /// Initializes the audio control service.
  ///
  /// This should be called when a call is established. It configures
  /// the platform audio session for voice communication and begins
  /// tracking device changes (Bluetooth, wired headsets, etc).
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    try {
      _audioSession = await AudioSession.instance;
      await _configureAudioSession();
      _setupDeviceChangeListener();
      _setupInterruptionListener();
      await _detectAvailableDevices();

      _isInitialized = true;
      debugPrint('AudioControlService: Initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('AudioControlService: Initialization failed - $e');
      debugPrint('$stackTrace');
      throw AudioControlException('Failed to initialize audio service: $e');
    }
  }

  /// Configures the audio session for VoIP calling.
  Future<void> _configureAudioSession() async {
    await _audioSession?.configure(
      const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        // Use a single option here to keep the configuration `const`
        // and avoid constant-evaluation issues with the bitwise OR.
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.allowBluetooth,
        avAudioSessionMode: AVAudioSessionMode.voiceChat,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions:
            AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ),
    );

    await _audioSession?.setActive(true);
  }

  /// Sets up listener for audio device changes (Bluetooth connect/disconnect, etc.).
  void _setupDeviceChangeListener() {
    _devicesSubscription =
        _audioSession?.devicesChangedEventStream.listen(
      (AudioDevicesChangedEvent event) async {
        debugPrint('AudioControlService: Devices changed');
        debugPrint(
          '  Added: ${event.devicesAdded.map((AudioDevice d) => d.name)}',
        );
        debugPrint(
          '  Removed: ${event.devicesRemoved.map((AudioDevice d) => d.name)}',
        );

        await _detectAvailableDevices();
      },
      onError: (Object error) {
        debugPrint(
          'AudioControlService: Device change listener error - $error',
        );
      },
    );
  }

  /// Sets up listener for audio interruptions (phone calls, alarms, etc.).
  void _setupInterruptionListener() {
    _interruptionSubscription =
        _audioSession?.interruptionEventStream.listen(
      (AudioInterruptionEvent event) {
        debugPrint(
          'AudioControlService: Interruption event - ${event.type}',
        );

        if (event.begin) {
          _updateState(
            currentState.copyWith(
              errorMessage: 'Audio interrupted by ${event.type}',
            ),
          );
        } else {
          _updateState(
            currentState.copyWith(errorMessage: null),
          );
        }
      },
    );
  }

  /// Detects available audio output devices.
  Future<void> _detectAvailableDevices() async {
    try {
      final List<AudioDevice> devices =
          (await _audioSession?.getDevices() ?? <AudioDevice>[])
              .toList();

      final List<AudioOutputType> availableOutputs =
          <AudioOutputType>[AudioOutputType.earpiece];
      bool bluetoothConnected = false;
      bool wiredConnected = false;
      String? bluetoothName;

      for (final AudioDevice device in devices) {
        if (device.isOutput) {
          switch (device.type) {
            case AudioDeviceType.builtInSpeaker:
              if (!availableOutputs.contains(AudioOutputType.speaker)) {
                availableOutputs.add(AudioOutputType.speaker);
              }
              break;
            case AudioDeviceType.bluetoothA2dp:
            case AudioDeviceType.bluetoothSco:
            case AudioDeviceType.bluetoothLe:
              bluetoothConnected = true;
              bluetoothName = device.name;
              if (!availableOutputs.contains(AudioOutputType.bluetooth)) {
                availableOutputs.add(AudioOutputType.bluetooth);
              }
              break;
            case AudioDeviceType.wiredHeadphones:
            case AudioDeviceType.wiredHeadset:
              wiredConnected = true;
              if (!availableOutputs
                  .contains(AudioOutputType.wiredHeadset)) {
                availableOutputs.add(AudioOutputType.wiredHeadset);
              }
              break;
            default:
              break;
          }
        }
      }

      _updateState(
        currentState.copyWith(
          availableOutputs: availableOutputs,
          isBluetoothConnected: bluetoothConnected,
          bluetoothDeviceName: bluetoothName,
          isWiredHeadsetConnected: wiredConnected,
        ),
      );

      debugPrint(
        'AudioControlService: Available outputs - $availableOutputs',
      );
    } catch (e) {
      debugPrint('AudioControlService: Failed to detect devices - $e');
    }
  }

  /// Toggles the microphone mute state.
  ///
  /// Returns the new mute state.
  Future<bool> toggleMute() async {
    _ensureInitialized();

    final bool newMutedState = !currentState.isMuted;
    _updateState(currentState.copyWith(isChangingAudio: true));

    try {
      // Mute at the WebRTC/media level.
      await _mediaHandler.setMute(newMutedState);

      // Also attempt to mute via native channel for platforms that support it.
      await channel.invokeMethod<void>(
        'setMute',
        <String, dynamic>{'muted': newMutedState},
      );

      _updateState(
        currentState.copyWith(
          isMuted: newMutedState,
          isChangingAudio: false,
          errorMessage: null,
        ),
      );

      debugPrint('AudioControlService: Mute toggled to $newMutedState');
      return newMutedState;
    } catch (e) {
      debugPrint('AudioControlService: Failed to toggle mute - $e');
      _updateState(
        AudioControlState.error(
          'Failed to toggle mute: $e',
          currentState.copyWith(isChangingAudio: false),
        ),
      );
      throw AudioControlException('Failed to toggle mute: $e');
    }
  }

  /// Sets the mute state explicitly.
  Future<void> setMuted(bool muted) async {
    if (currentState.isMuted == muted) {
      return;
    }
    await toggleMute();
  }

  /// Toggles the speaker output.
  ///
  /// When speaker is enabled, audio is routed to the device's loudspeaker.
  /// When disabled, audio returns to earpiece (or connected device).
  ///
  /// Returns the new speaker state.
  Future<bool> toggleSpeaker() async {
    _ensureInitialized();

    final AudioControlState state = currentState;
    final bool newSpeakerState = !state.isSpeakerOn;

    _updateState(state.copyWith(isChangingAudio: true));

    try {
      final AudioOutputType newOutput = newSpeakerState
          ? AudioOutputType.speaker
          : _getDefaultNonSpeakerOutput();

      await _setAudioRoute(newOutput);

      _updateState(
        currentState.copyWith(
          isSpeakerOn: newSpeakerState,
          currentOutput: newOutput,
          isChangingAudio: false,
          errorMessage: null,
        ),
      );

      debugPrint(
        'AudioControlService: Speaker toggled to $newSpeakerState',
      );
      return newSpeakerState;
    } catch (e) {
      debugPrint('AudioControlService: Failed to toggle speaker - $e');
      _updateState(
        AudioControlState.error(
          'Failed to toggle speaker: $e',
          currentState.copyWith(isChangingAudio: false),
        ),
      );
      throw AudioControlException('Failed to toggle speaker: $e');
    }
  }

  /// Sets the speaker state explicitly.
  Future<void> setSpeaker(bool enabled) async {
    if (currentState.isSpeakerOn == enabled) {
      return;
    }
    await toggleSpeaker();
  }

  /// Sets the audio output to a specific type.
  Future<void> setAudioOutput(AudioOutputType outputType) async {
    _ensureInitialized();

    if (!currentState.availableOutputs.contains(outputType)) {
      throw AudioControlException(
        'Audio output $outputType is not available',
      );
    }

    _updateState(currentState.copyWith(isChangingAudio: true));

    try {
      await _setAudioRoute(outputType);

      _updateState(
        currentState.copyWith(
          currentOutput: outputType,
          isSpeakerOn: outputType == AudioOutputType.speaker,
          isChangingAudio: false,
          errorMessage: null,
        ),
      );

      debugPrint(
        'AudioControlService: Audio output set to $outputType',
      );
    } catch (e) {
      debugPrint('AudioControlService: Failed to set audio output - $e');
      _updateState(
        AudioControlState.error(
          'Failed to set audio output: $e',
          currentState.copyWith(isChangingAudio: false),
        ),
      );
      throw AudioControlException('Failed to set audio output: $e');
    }
  }

  /// Internal method to set the audio route based on [AudioOutputType].
  Future<void> _setAudioRoute(AudioOutputType outputType) async {
    // Route via flutter_webrtc helper and AudioService.
    switch (outputType) {
      case AudioOutputType.speaker:
        await _mediaHandler.setSpeaker(true);
        await _audioService.setSpeaker(true);
        break;
      case AudioOutputType.bluetooth:
      case AudioOutputType.wiredHeadset:
      case AudioOutputType.earpiece:
        // For non-speaker outputs we disable speakerphone; the platform
        // will route to the appropriate connected device (wired/Bluetooth)
        // where supported.
        await _mediaHandler.setSpeaker(false);
        await _audioService.setSpeaker(false);
        break;
    }
  }

  /// Gets the default non-speaker output based on connected devices.
  AudioOutputType _getDefaultNonSpeakerOutput() {
    final AudioControlState state = currentState;

    if (state.isBluetoothConnected) {
      return AudioOutputType.bluetooth;
    }
    if (state.isWiredHeadsetConnected) {
      return AudioOutputType.wiredHeadset;
    }
    return AudioOutputType.earpiece;
  }

  /// Updates the state and notifies listeners.
  void _updateState(AudioControlState newState) {
    if (_stateController.value != newState) {
      _stateController.add(newState);
    }
  }

  /// Ensures the service is initialized before operations.
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw AudioControlException(
        'AudioControlService not initialized. Call initialize() first.',
      );
    }
  }

  /// Resets audio state when a call ends.
  ///
  /// This should be called when hanging up or when the call is disconnected.
  Future<void> resetForCallEnd() async {
    try {
      if (_isInitialized) {
        await _setAudioRoute(AudioOutputType.earpiece);
      }

      await _audioSession?.setActive(false);
      await _audioService.resetAudio();

      _updateState(AudioControlState.initial());
      debugPrint('AudioControlService: Reset for call end');
    } catch (e) {
      debugPrint('AudioControlService: Error during reset - $e');
    }
  }

  /// Disposes of resources.
  Future<void> dispose() async {
    await _devicesSubscription?.cancel();
    await _interruptionSubscription?.cancel();

    await _audioSession?.setActive(false);
    await _stateController.close();

    _isInitialized = false;
    debugPrint('AudioControlService: Disposed');
  }
}

/// Exception thrown when audio control operations fail.
class AudioControlException implements Exception {
  final String message;

  AudioControlException(this.message);

  @override
  String toString() => 'AudioControlException: $message';
}


