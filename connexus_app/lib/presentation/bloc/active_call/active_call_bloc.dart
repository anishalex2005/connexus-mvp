import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/call_constants.dart';
import '../../../data/services/telnyx_service.dart';
import '../../../domain/models/active_call_state_model.dart';
import '../../../domain/usecases/end_call_usecase.dart';
import 'active_call_event.dart';
import 'active_call_state.dart';

/// BLoC managing active call state and actions.
class ActiveCallBloc extends Bloc<ActiveCallEvent, ActiveCallState> {
  final TelnyxService _telnyxService;
  final EndCallUseCase _endCallUseCase;
  Timer? _durationTimer;
  StreamSubscription<TelnyxCallEvent>? _callEventSubscription;

  ActiveCallBloc({
    required TelnyxService telnyxService,
    required EndCallUseCase endCallUseCase,
  })  : _telnyxService = telnyxService,
        _endCallUseCase = endCallUseCase,
        super(const ActiveCallInitial()) {
    on<CallBecameActive>(_onCallBecameActive);
    on<ToggleMute>(_onToggleMute);
    on<ToggleSpeaker>(_onToggleSpeaker);
    on<ToggleHold>(_onToggleHold);
    on<ToggleKeypad>(_onToggleKeypad);
    on<SendDtmfTone>(_onSendDtmfTone);
    on<UpdateCallDuration>(_onUpdateCallDuration);
    on<UpdateCallQuality>(_onUpdateCallQuality);
    on<EndCall>(_onEndCall);
    on<CallEnded>(_onCallEnded);
    on<InitiateTransfer>(_onInitiateTransfer);
  }

  void _onCallBecameActive(
    CallBecameActive event,
    Emitter<ActiveCallState> emit,
  ) {
    final ActiveCallStateModel callState = ActiveCallStateModel(
      callId: event.callId,
      callerName: event.callerName,
      callerNumber: event.callerNumber,
      callerAvatarUrl: event.callerAvatarUrl,
      callStartTime: DateTime.now(),
    );

    emit(ActiveCallInProgress(callState: callState));

    // Start duration timer.
    _startDurationTimer();

    // Subscribe to call events from Telnyx.
    _subscribeToCallEvents();
  }

  Future<void> _onToggleMute(
    ToggleMute event,
    Emitter<ActiveCallState> emit,
  ) async {
    if (state is! ActiveCallInProgress) return;

    final ActiveCallInProgress currentState =
        state as ActiveCallInProgress;
    final bool newMuteState = !currentState.callState.isMuted;

    try {
      await _telnyxService.setMute(newMuteState);

      emit(
        currentState.copyWith(
          callState: currentState.callState
              .copyWith(isMuted: newMuteState),
        ),
      );
    } catch (e) {
      emit(
        ActiveCallError(
          message: 'Failed to toggle mute: $e',
        ),
      );
      emit(currentState); // Restore previous state.
    }
  }

  Future<void> _onToggleSpeaker(
    ToggleSpeaker event,
    Emitter<ActiveCallState> emit,
  ) async {
    if (state is! ActiveCallInProgress) return;

    final ActiveCallInProgress currentState =
        state as ActiveCallInProgress;
    final bool newSpeakerState =
        !currentState.callState.isSpeakerOn;

    try {
      await _telnyxService.setSpeaker(newSpeakerState);

      emit(
        currentState.copyWith(
          callState: currentState.callState
              .copyWith(isSpeakerOn: newSpeakerState),
        ),
      );
    } catch (e) {
      emit(
        ActiveCallError(
          message: 'Failed to toggle speaker: $e',
        ),
      );
      emit(currentState);
    }
  }

  Future<void> _onToggleHold(
    ToggleHold event,
    Emitter<ActiveCallState> emit,
  ) async {
    if (state is! ActiveCallInProgress) return;

    final ActiveCallInProgress currentState =
        state as ActiveCallInProgress;
    final bool newHoldState = !currentState.callState.isOnHold;

    try {
      if (newHoldState) {
        await _telnyxService.holdCall(
          currentState.callState.callId,
        );
      } else {
        await _telnyxService.unholdCall(
          currentState.callState.callId,
        );
      }

      emit(
        currentState.copyWith(
          callState: currentState.callState
              .copyWith(isOnHold: newHoldState),
        ),
      );
    } catch (e) {
      emit(
        ActiveCallError(
          message: 'Failed to toggle hold: $e',
        ),
      );
      emit(currentState);
    }
  }

  void _onToggleKeypad(
    ToggleKeypad event,
    Emitter<ActiveCallState> emit,
  ) {
    if (state is! ActiveCallInProgress) return;

    final ActiveCallInProgress currentState =
        state as ActiveCallInProgress;

    emit(
      currentState.copyWith(
        callState: currentState.callState.copyWith(
          isKeypadVisible:
              !currentState.callState.isKeypadVisible,
        ),
        // Clear DTMF input when hiding keypad.
        dtmfInput: currentState.callState.isKeypadVisible
            ? ''
            : currentState.dtmfInput,
      ),
    );
  }

  Future<void> _onSendDtmfTone(
    SendDtmfTone event,
    Emitter<ActiveCallState> emit,
  ) async {
    if (state is! ActiveCallInProgress) return;

    final ActiveCallInProgress currentState =
        state as ActiveCallInProgress;

    try {
      await _telnyxService.sendDtmf(
        currentState.callState.callId,
        event.digit,
      );

      // Update DTMF display.
      final String newDtmfInput =
          (currentState.dtmfInput ?? '') + event.digit;

      emit(
        currentState.copyWith(
          dtmfInput: newDtmfInput.length > 20
              ? newDtmfInput
                  .substring(newDtmfInput.length - 20)
              : newDtmfInput,
        ),
      );
    } catch (e) {
      // DTMF failures are typically non-critical, just log.
      // ignore: avoid_print
      print('DTMF send failed: $e');
    }
  }

  void _onUpdateCallDuration(
    UpdateCallDuration event,
    Emitter<ActiveCallState> emit,
  ) {
    if (state is! ActiveCallInProgress) return;

    final ActiveCallInProgress currentState =
        state as ActiveCallInProgress;

    emit(
      currentState.copyWith(
        callState: currentState.callState.copyWith(
          callDuration: event.duration,
        ),
      ),
    );
  }

  void _onUpdateCallQuality(
    UpdateCallQuality event,
    Emitter<ActiveCallState> emit,
  ) {
    if (state is! ActiveCallInProgress) return;

    final ActiveCallInProgress currentState =
        state as ActiveCallInProgress;
    final CallQuality quality =
        _scoreToQuality(event.qualityScore);

    emit(
      currentState.copyWith(
        callState: currentState.callState.copyWith(
          callQuality: quality,
        ),
      ),
    );
  }

  Future<void> _onEndCall(
    EndCall event,
    Emitter<ActiveCallState> emit,
  ) async {
    if (state is! ActiveCallInProgress) return;

    final ActiveCallInProgress currentState =
        state as ActiveCallInProgress;

    try {
      await _telnyxService.hangup(
        currentState.callState.callId,
      );

      // Log the ended call in history.
      await _endCallUseCase.execute(
        duration: currentState.callState.callDuration,
        reason: CallEndReason.userHangUp,
      );

      _stopDurationTimer();

      emit(
        ActiveCallComplete(
          callId: currentState.callState.callId,
          totalDuration:
              currentState.callState.callDuration,
          endReason: 'User ended call',
        ),
      );
    } catch (e) {
      emit(
        ActiveCallError(
          message: 'Failed to end call: $e',
        ),
      );
      emit(currentState);
    }
  }

  void _onCallEnded(
    CallEnded event,
    Emitter<ActiveCallState> emit,
  ) {
    if (state is! ActiveCallInProgress) return;

    final ActiveCallInProgress currentState =
        state as ActiveCallInProgress;

    _stopDurationTimer();

    final CallEndReason mappedReason =
        _mapEventReasonToEndReason(event.reason);

    // Fire and forget logging for remote/other end reasons. Declined calls
    // are already logged via [DeclineCallUseCase].
    if (mappedReason != CallEndReason.declined) {
      // ignore: discarded_futures
      _endCallUseCase.execute(
        duration: currentState.callState.callDuration,
        reason: mappedReason,
      );
    }

    emit(
      ActiveCallComplete(
        callId: currentState.callState.callId,
        totalDuration:
            currentState.callState.callDuration,
        endReason: event.reason,
      ),
    );
  }

  void _onInitiateTransfer(
    InitiateTransfer event,
    Emitter<ActiveCallState> emit,
  ) {
    // This will be handled by Task 45-49.
    // For now, just mark that transfer was requested.
    // ignore: avoid_print
    print('Transfer initiated - to be implemented in Task 45-49');
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer timer) {
        if (state is ActiveCallInProgress) {
          final ActiveCallInProgress currentState =
              state as ActiveCallInProgress;
          add(
            UpdateCallDuration(
              Duration(
                seconds:
                    currentState.callState.callDuration
                            .inSeconds +
                        1,
              ),
            ),
          );
        }
      },
    );
  }

  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  void _subscribeToCallEvents() {
    _callEventSubscription?.cancel();
    _callEventSubscription =
        _telnyxService.callEvents.listen((TelnyxCallEvent event) {
      // Handle call events from Telnyx.
      // This integrates with WebRTC connection and quality monitoring.
      if (event.type == 'ended') {
        add(CallEnded(reason: event.reason));
      } else if (event.type == 'quality' &&
          event.qualityScore != null) {
        add(UpdateCallQuality(event.qualityScore!));
      }
    });
  }

  CallQuality _scoreToQuality(int score) {
    if (score >= 80) return CallQuality.excellent;
    if (score >= 60) return CallQuality.good;
    if (score >= 40) return CallQuality.fair;
    return CallQuality.poor;
  }

  CallEndReason _mapEventReasonToEndReason(String? reason) {
    if (reason == null) {
      return CallEndReason.unknown;
    }

    switch (reason) {
      case 'declined':
        return CallEndReason.declined;
      case 'remote_hangup':
      case 'remote':
        return CallEndReason.remoteHangUp;
      case 'network_error':
        return CallEndReason.networkError;
      case 'connection_failed':
        return CallEndReason.connectionFailed;
      case 'transferred':
        return CallEndReason.transferred;
      default:
        // For generic messages like "User ended call" we treat as user hang up.
        return CallEndReason.userHangUp;
    }
  }

  @override
  Future<void> close() {
    _stopDurationTimer();
    _callEventSubscription?.cancel();
    return super.close();
  }
}


