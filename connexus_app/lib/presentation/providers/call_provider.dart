import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/services/audio_service.dart';
import '../../domain/models/call_model.dart';
import '../../injection.dart';

/// Provider that manages call state and UI updates.
class CallProvider extends ChangeNotifier {
  CallModel? _currentCall;
  Timer? _callTimer;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isRinging = false;

  // Audio routing and alerts (ringtone, vibration, speaker, mute).
  late final AudioService _audioService = getIt<AudioService>();

  // Getters
  CallModel? get currentCall => _currentCall;
  bool get hasActiveCall => _currentCall != null;
  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;
  bool get isRinging => _isRinging;
  bool get isIncoming => _currentCall?.state == CallState.incoming;

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

    // Start ringtone + vibration via shared audio service.
    _isRinging = true;
    await _audioService.startIncomingCallAudio();

    // Wake the screen.
    await WakelockPlus.enable();

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
  Future<void> declineCall() async {
    if (_currentCall == null) return;

    await _stopRinging();
    await WakelockPlus.disable();

    _currentCall = _currentCall!.copyWith(
      state: CallState.ended,
      endTime: DateTime.now(),
    );

    _stopCallTimer();
    notifyListeners();

    // Clear call after a short delay for UI transition.
    await Future.delayed(const Duration(milliseconds: 500));
    _currentCall = null;
    notifyListeners();

    // Note: Actual Telnyx decline logic will be added in Task 21.
  }

  /// End the current active call.
  Future<void> endCall() async {
    if (_currentCall == null) return;

    await _stopRinging();
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
    await Future.delayed(const Duration(milliseconds: 500));
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

  @override
  void dispose() {
    _stopRinging();
    _stopCallTimer();
    WakelockPlus.disable();
    super.dispose();
  }
}
