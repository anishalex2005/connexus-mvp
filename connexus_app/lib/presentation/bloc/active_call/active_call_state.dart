import 'package:equatable/equatable.dart';

import '../../../domain/models/active_call_state_model.dart';

/// States for the Active Call BLoC.
abstract class ActiveCallState extends Equatable {
  const ActiveCallState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state before call is active.
class ActiveCallInitial extends ActiveCallState {
  const ActiveCallInitial();
}

/// State when call is in progress.
class ActiveCallInProgress extends ActiveCallState {
  final ActiveCallStateModel callState;
  final String? dtmfInput;

  const ActiveCallInProgress({
    required this.callState,
    this.dtmfInput,
  });

  ActiveCallInProgress copyWith({
    ActiveCallStateModel? callState,
    String? dtmfInput,
  }) {
    return ActiveCallInProgress(
      callState: callState ?? this.callState,
      dtmfInput: dtmfInput ?? this.dtmfInput,
    );
  }

  @override
  List<Object?> get props => <Object?>[callState, dtmfInput];
}

/// State when call has ended.
class ActiveCallComplete extends ActiveCallState {
  final String callId;
  final Duration totalDuration;
  final String? endReason;

  const ActiveCallComplete({
    required this.callId,
    required this.totalDuration,
    this.endReason,
  });

  @override
  List<Object?> get props => <Object?>[callId, totalDuration, endReason];
}

/// State when there's an error.
class ActiveCallError extends ActiveCallState {
  final String message;
  final String? errorCode;

  const ActiveCallError({
    required this.message,
    this.errorCode,
  });

  @override
  List<Object?> get props => <Object?>[message, errorCode];
}


