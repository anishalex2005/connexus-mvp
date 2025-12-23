import 'package:flutter/foundation.dart';

import 'audio_output_type.dart';

/// Immutable state class representing the current audio control settings
/// during an active call.
///
/// This class is consumed by UI components to display and control audio
/// settings (mute, speaker, output device, etc.).
@immutable
class AudioControlState {
  /// Whether the local microphone is muted.
  final bool isMuted;

  /// Whether the speaker (loudspeaker) is enabled.
  final bool isSpeakerOn;

  /// The currently active audio output destination.
  final AudioOutputType currentOutput;

  /// List of available audio output options.
  final List<AudioOutputType> availableOutputs;

  /// Whether a Bluetooth device is currently connected.
  final bool isBluetoothConnected;

  /// Name of the connected Bluetooth device (if any).
  final String? bluetoothDeviceName;

  /// Whether wired headphones are connected.
  final bool isWiredHeadsetConnected;

  /// Whether audio controls are currently being changed.
  final bool isChangingAudio;

  /// Error message if last audio operation failed.
  final String? errorMessage;

  const AudioControlState({
    this.isMuted = false,
    this.isSpeakerOn = false,
    this.currentOutput = AudioOutputType.earpiece,
    this.availableOutputs = const <AudioOutputType>[
      AudioOutputType.earpiece,
      AudioOutputType.speaker,
    ],
    this.isBluetoothConnected = false,
    this.bluetoothDeviceName,
    this.isWiredHeadsetConnected = false,
    this.isChangingAudio = false,
    this.errorMessage,
  });

  /// Creates a copy of this state with the given fields replaced.
  AudioControlState copyWith({
    bool? isMuted,
    bool? isSpeakerOn,
    AudioOutputType? currentOutput,
    List<AudioOutputType>? availableOutputs,
    bool? isBluetoothConnected,
    String? bluetoothDeviceName,
    bool? isWiredHeadsetConnected,
    bool? isChangingAudio,
    String? errorMessage,
  }) {
    return AudioControlState(
      isMuted: isMuted ?? this.isMuted,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      currentOutput: currentOutput ?? this.currentOutput,
      availableOutputs: availableOutputs ?? this.availableOutputs,
      isBluetoothConnected: isBluetoothConnected ?? this.isBluetoothConnected,
      bluetoothDeviceName: bluetoothDeviceName ?? this.bluetoothDeviceName,
      isWiredHeadsetConnected:
          isWiredHeadsetConnected ?? this.isWiredHeadsetConnected,
      isChangingAudio: isChangingAudio ?? this.isChangingAudio,
      // When copying we intentionally allow overriding the error message
      // explicitly, including clearing it by passing `null`.
      errorMessage: errorMessage,
    );
  }

  /// Returns the initial state for a new call.
  factory AudioControlState.initial() {
    return const AudioControlState();
  }

  /// Returns state indicating an error occurred.
  factory AudioControlState.error(String message, AudioControlState previous) {
    return previous.copyWith(
      isChangingAudio: false,
      errorMessage: message,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AudioControlState &&
        other.isMuted == isMuted &&
        other.isSpeakerOn == isSpeakerOn &&
        other.currentOutput == currentOutput &&
        listEquals(other.availableOutputs, availableOutputs) &&
        other.isBluetoothConnected == isBluetoothConnected &&
        other.bluetoothDeviceName == bluetoothDeviceName &&
        other.isWiredHeadsetConnected == isWiredHeadsetConnected &&
        other.isChangingAudio == isChangingAudio &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode {
    return Object.hash(
      isMuted,
      isSpeakerOn,
      currentOutput,
      Object.hashAll(availableOutputs),
      isBluetoothConnected,
      bluetoothDeviceName,
      isWiredHeadsetConnected,
      isChangingAudio,
      errorMessage,
    );
  }

  @override
  String toString() {
    return 'AudioControlState('
        'isMuted: $isMuted, '
        'isSpeakerOn: $isSpeakerOn, '
        'currentOutput: $currentOutput, '
        'isBluetoothConnected: $isBluetoothConnected, '
        'bluetoothDeviceName: $bluetoothDeviceName)';
  }
}


