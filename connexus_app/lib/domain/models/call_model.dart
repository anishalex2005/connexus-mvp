import 'package:flutter/foundation.dart';

/// Represents the current state of a call.
enum CallState {
  incoming,
  connecting,
  active,
  held,
  ended,
}

/// Represents the direction of the call.
enum CallDirection {
  incoming,
  outgoing,
}

/// Model representing a phone call.
@immutable
class CallModel {
  final String callId;
  final String callerNumber;
  final String? callerName;
  final String? callerPhotoUrl;
  final CallState state;
  final CallDirection direction;
  final DateTime startTime;
  final DateTime? answerTime;
  final DateTime? endTime;

  const CallModel({
    required this.callId,
    required this.callerNumber,
    this.callerName,
    this.callerPhotoUrl,
    required this.state,
    required this.direction,
    required this.startTime,
    this.answerTime,
    this.endTime,
  });

  /// Creates a copy with updated fields.
  CallModel copyWith({
    String? callId,
    String? callerNumber,
    String? callerName,
    String? callerPhotoUrl,
    CallState? state,
    CallDirection? direction,
    DateTime? startTime,
    DateTime? answerTime,
    DateTime? endTime,
  }) {
    return CallModel(
      callId: callId ?? this.callId,
      callerNumber: callerNumber ?? this.callerNumber,
      callerName: callerName ?? this.callerName,
      callerPhotoUrl: callerPhotoUrl ?? this.callerPhotoUrl,
      state: state ?? this.state,
      direction: direction ?? this.direction,
      startTime: startTime ?? this.startTime,
      answerTime: answerTime ?? this.answerTime,
      endTime: endTime ?? this.endTime,
    );
  }

  /// Creates a new incoming call model.
  factory CallModel.incoming({
    required String callId,
    required String callerNumber,
    String? callerName,
    String? callerPhotoUrl,
  }) {
    return CallModel(
      callId: callId,
      callerNumber: callerNumber,
      callerName: callerName,
      callerPhotoUrl: callerPhotoUrl,
      state: CallState.incoming,
      direction: CallDirection.incoming,
      startTime: DateTime.now(),
    );
  }

  /// Formatted caller display name.
  String get displayName => callerName ?? callerNumber;

  /// Formatted phone number for display.
  String get formattedNumber {
    if (callerNumber.length == 10) {
      return '(${callerNumber.substring(0, 3)}) '
          '${callerNumber.substring(3, 6)}-'
          '${callerNumber.substring(6)}';
    } else if (callerNumber.length == 11 && callerNumber.startsWith('1')) {
      return '+1 (${callerNumber.substring(1, 4)}) '
          '${callerNumber.substring(4, 7)}-'
          '${callerNumber.substring(7)}';
    }
    return callerNumber;
  }

  /// Duration of the call if answered.
  Duration? get duration {
    if (answerTime == null) return null;
    final end = endTime ?? DateTime.now();
    return end.difference(answerTime!);
  }

  @override
  String toString() {
    return 'CallModel(callId: $callId, caller: $displayName, state: $state)';
  }
}
