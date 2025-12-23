import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/services/audio_service.dart';
import '../../data/services/telnyx_service.dart';
import '../../domain/models/call_model.dart';
import '../../domain/usecases/decline_call_usecase.dart';
import '../../injection.dart';

/// Provider that manages call state and UI updates.
class CallProvider extends ChangeNotifier {
  CallModel? _currentCall;
  Timer? _callTimer;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isRinging = false;
  bool _isProcessing = false;
  String? _errorMessage;

  // Audio routing and alerts (ringtone, vibration, speaker, mute).
  late final AudioService _audioService = getIt<AudioService>();

  // Telnyx integration and decline use case.
  late final TelnyxService _telnyxService = getIt<TelnyxService>();
  late final DeclineCallUseCase _declineCallUseCase =
      getIt<DeclineCallUseCase>();

  // Getters
  CallModel? get currentCall => _currentCall;
  bool get hasActiveCall => _currentCall != null;
  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;
  bool get isRinging => _isRinging;
  bool get isIncoming => _currentCall?.state == CallState.incoming;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;

  /// Handle an incoming call.
  Future<void> handleIncomingCall({
    required String callId,
    required String callerNumber,
    String? callerName,
    String? callerPhotoUrl,
  }) async {
    // Create the call model.
    _currentCall = CallModel.incoming(
      callId: callId,
      callerNumber: callerNumber,
      callerName: callerName,
      callerPhotoUrl: callerPhotoUrl,
    );

    // Inform TelnyxService about current call context for decline/logging.
    _telnyxService.updateCurrentCallContext(
      callId: callId,
      callerNumber: callerNumber,
      callerName: callerName,
      direction: 'incoming',
    );

    // Start ringtone + vibration via shared audio service.
    _isRinging = true;
    await _audioService.startIncomingCallAudio();

    // Wake the screen.
    await WakelockPlus.enable();

    _errorMessage = null;
    notifyListeners();
  }

  /// Stop the ringtone and vibration.
  Future<void> _stopRinging() async {
    _isRinging = false;
    await _audioService.stopIncomingCallAudio();
  }

  /// Start the call duration timer for an active call.
  void _startCallTimer() {
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      // Trigger UI updates so that `CallModel.duration` reflects in widgets.
      notifyListeners();
    });
  }

  /// Stop the active call timer.
  void _stopCallTimer() {
    _callTimer?.cancel();
    _callTimer = null;
  }

  /// Answer the current incoming call.
  Future<void> answerCall() async {
    if (_currentCall == null || _currentCall!.state != CallState.incoming) {
      return;
    }

    await _stopRinging();

    // Transition to active call and start duration timer.
    _currentCall = _currentCall!.copyWith(
      state: CallState.active,
      answerTime: DateTime.now(),
    );

    _startCallTimer();
    notifyListeners();
  }

  /// Decline the current incoming call.
  ///
  /// Returns `true` if successful, `false` otherwise.
  Future<bool> declineCall({String? reason}) async {
    if (_currentCall == null ||
        _currentCall!.state != CallState.incoming) {
      debugPrint('CallProvider: Cannot decline - no incoming call');
      return false;
    }

    if (_isProcessing) {
      debugPrint('CallProvider: Already processing an action');
      return false;
    }

    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('CallProvider: Declining call...');

      // Stop local ringing first for immediate feedback.
      await _stopRinging();

      // Execute domain use case (Telnyx + logging).
      final DeclineCallResult result =
          await _declineCallUseCase.execute(
        reason: reason ?? 'user_declined',
      );

      if (result.success) {
        debugPrint('CallProvider: Call declined successfully');

        _currentCall = _currentCall!.copyWith(
          state: CallState.ended,
          endTime: DateTime.now(),
        );

        _stopCallTimer();
        await WakelockPlus.disable();

        notifyListeners();

        // Clear call after a short delay for UI transition.
        await Future<void>.delayed(
          const Duration(milliseconds: 500),
        );
        _currentCall = null;
        notifyListeners();

        return true;
      } else {
        _errorMessage = result.error ?? 'Failed to decline call';
        debugPrint('CallProvider: Decline failed: $_errorMessage');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error declining call: $e';
      debugPrint('CallProvider: Exception: $_errorMessage');
      notifyListeners();
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// End the current active call.
  Future<void> endCall() async {
    if (_currentCall == null) return;

    await _stopRinging();

    // Reset audio routing back to normal mode.
    await _audioService.resetAudio();

    await WakelockPlus.disable();

    _currentCall = _currentCall!.copyWith(
      state: CallState.ended,
      endTime: DateTime.now(),
    );

    _isMuted = false;
    _isSpeakerOn = false;

    _stopCallTimer();
    notifyListeners();

    // Clear call after delay.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _currentCall = null;
    notifyListeners();
  }

  /// Toggle mute state.
  void toggleMute() {
    _isMuted = !_isMuted;
    notifyListeners();
    // Note: Actual audio mute logic will be added in Task 25.
  }

  /// Toggle speaker state.
  void toggleSpeaker() {
    _isSpeakerOn = !_isSpeakerOn;
    notifyListeners();
    // Note: Actual audio routing logic will be added in Task 25.
  }

  /// Update call state (called from Telnyx callbacks).
  void updateCallState(CallState newState) {
    if (_currentCall == null) return;

    _currentCall = _currentCall!.copyWith(state: newState);
    notifyListeners();
  }

  /// Clears any error state.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopRinging();
    _stopCallTimer();
    WakelockPlus.disable();
    super.dispose();
  }
}

