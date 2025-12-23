import 'package:equatable/equatable.dart';

/// Events for the Active Call BLoC.
abstract class ActiveCallEvent extends Equatable {
  const ActiveCallEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Event when a call becomes active.
class CallBecameActive extends ActiveCallEvent {
  final String callId;
  final String callerName;
  final String callerNumber;
  final String? callerAvatarUrl;

  const CallBecameActive({
    required this.callId,
    required this.callerName,
    required this.callerNumber,
    this.callerAvatarUrl,
  });

  @override
  List<Object?> get props =>
      <Object?>[callId, callerName, callerNumber, callerAvatarUrl];
}

/// Event to toggle mute state.
class ToggleMute extends ActiveCallEvent {
  const ToggleMute();
}

/// Event to toggle speaker state.
class ToggleSpeaker extends ActiveCallEvent {
  const ToggleSpeaker();
}

/// Event to toggle hold state.
class ToggleHold extends ActiveCallEvent {
  const ToggleHold();
}

/// Event to toggle keypad visibility.
class ToggleKeypad extends ActiveCallEvent {
  const ToggleKeypad();
}

/// Event to send DTMF tone.
class SendDtmfTone extends ActiveCallEvent {
  final String digit;

  const SendDtmfTone(this.digit);

  @override
  List<Object?> get props => <Object?>[digit];
}

/// Event to update call duration.
class UpdateCallDuration extends ActiveCallEvent {
  final Duration duration;

  const UpdateCallDuration(this.duration);

  @override
  List<Object?> get props => <Object?>[duration];
}

/// Event to update call quality.
class UpdateCallQuality extends ActiveCallEvent {
  /// Score from 0-100.
  final int qualityScore;

  const UpdateCallQuality(this.qualityScore);

  @override
  List<Object?> get props => <Object?>[qualityScore];
}

/// Event to end the call.
class EndCall extends ActiveCallEvent {
  const EndCall();
}

/// Event to initiate call transfer.
class InitiateTransfer extends ActiveCallEvent {
  const InitiateTransfer();
}

/// Event when call has ended.
class CallEnded extends ActiveCallEvent {
  final String? reason;

  const CallEnded({this.reason});

  @override
  List<Object?> get props => <Object?>[reason];
}


