/// Represents the available audio output destinations for calls.
///
/// This enum is used by audio control services to manage audio routing
/// during active calls.
enum AudioOutputType {
  /// Device earpiece (default for phone calls)
  earpiece,

  /// Device speaker (loudspeaker mode)
  speaker,

  /// Connected Bluetooth device (headset, speaker, car audio)
  bluetooth,

  /// Wired headphones or headset
  wiredHeadset,
}

/// Extension methods for [AudioOutputType].
extension AudioOutputTypeExtension on AudioOutputType {
  /// Returns a user-friendly display name for the audio output type.
  String get displayName {
    switch (this) {
      case AudioOutputType.earpiece:
        return 'Earpiece';
      case AudioOutputType.speaker:
        return 'Speaker';
      case AudioOutputType.bluetooth:
        return 'Bluetooth';
      case AudioOutputType.wiredHeadset:
        return 'Headphones';
    }
  }

  /// Returns the icon name for the audio output type.
  ///
  /// These are Material icon names that can be mapped to [Icons].
  String get iconName {
    switch (this) {
      case AudioOutputType.earpiece:
        return 'phone_in_talk';
      case AudioOutputType.speaker:
        return 'volume_up';
      case AudioOutputType.bluetooth:
        return 'bluetooth_audio';
      case AudioOutputType.wiredHeadset:
        return 'headset';
    }
  }

  /// Whether this output type is considered "hands-free".
  bool get isHandsFree {
    return this == AudioOutputType.speaker || this == AudioOutputType.bluetooth;
  }
}


