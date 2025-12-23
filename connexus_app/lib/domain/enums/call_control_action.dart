/// Enum representing all available call control actions.
/// Used by the Active Call UI to manage button states and actions.
enum CallControlAction {
  mute,
  speaker,
  hold,
  keypad,
  transfer,
  addCall,
  bluetooth,
  record,
}

/// Extension to provide UI-related properties for each action.
extension CallControlActionExtension on CallControlAction {
  String get label {
    switch (this) {
      case CallControlAction.mute:
        return 'Mute';
      case CallControlAction.speaker:
        return 'Speaker';
      case CallControlAction.hold:
        return 'Hold';
      case CallControlAction.keypad:
        return 'Keypad';
      case CallControlAction.transfer:
        return 'Transfer';
      case CallControlAction.addCall:
        return 'Add Call';
      case CallControlAction.bluetooth:
        return 'Bluetooth';
      case CallControlAction.record:
        return 'Record';
    }
  }

  String get iconName {
    switch (this) {
      case CallControlAction.mute:
        return 'mic_off';
      case CallControlAction.speaker:
        return 'volume_up';
      case CallControlAction.hold:
        return 'pause';
      case CallControlAction.keypad:
        return 'dialpad';
      case CallControlAction.transfer:
        return 'call_split';
      case CallControlAction.addCall:
        return 'add_call';
      case CallControlAction.bluetooth:
        return 'bluetooth_audio';
      case CallControlAction.record:
        return 'fiber_manual_record';
    }
  }
}


