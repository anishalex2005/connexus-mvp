import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:vibration/vibration.dart';

/// Service responsible for managing audio routing and alerts during calls.
class AudioService {
  static const MethodChannel _channel = MethodChannel('com.connexus/audio');

  bool _isSpeakerOn = false;
  bool _isMuted = false;
  bool _isRingtoneActive = false;

  /// Whether speakerphone is currently enabled.
  bool get isSpeakerOn => _isSpeakerOn;

  /// Whether the microphone is currently muted.
  bool get isMuted => _isMuted;

  /// Start ringtone + vibration for an incoming call.
  Future<void> startIncomingCallAudio() async {
    if (_isRingtoneActive) return;

    _isRingtoneActive = true;

    // Play system ringtone in a loop.
    await FlutterRingtonePlayer().playRingtone(
      looping: true,
      volume: 1.0,
      asAlarm: false,
    );

    // Start vibration pattern where supported.
    final bool hasVibrator = (await Vibration.hasVibrator()) ?? false;
    if (hasVibrator) {
      // Simple repeating pattern.
      Vibration.vibrate(
        pattern: <int>[0, 1000, 1000, 1000, 1000],
        repeat: 0,
      );
    }
  }

  /// Stop ringtone + vibration for an incoming call.
  Future<void> stopIncomingCallAudio() async {
    if (!_isRingtoneActive) return;

    _isRingtoneActive = false;

    await FlutterRingtonePlayer().stop();
    Vibration.cancel();
  }

  /// Configure audio routing for an active call.
  ///
  /// This sets the native audio mode to "voice call" and defaults to earpiece.
  Future<void> configureActiveCallAudio() async {
    await stopIncomingCallAudio();

    try {
      await _channel.invokeMethod<void>(
        'setAudioMode',
        <String, dynamic>{'mode': 'voice_call'},
      );
    } on PlatformException catch (e) {
      // In a failure case we still continue; audio may still work with defaults.
      // ignore: avoid_print
      print('AudioService: failed to set audio mode: ${e.message}');
    }

    await setSpeaker(false);
  }

  /// Enable or disable speakerphone.
  Future<bool> setSpeaker(bool enabled) async {
    try {
      await _channel.invokeMethod<void>(
        'setSpeaker',
        <String, dynamic>{'enabled': enabled},
      );
      _isSpeakerOn = enabled;
      return true;
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('AudioService: failed to set speaker: ${e.message}');
      return false;
    }
  }

  /// Mute or unmute the microphone.
  ///
  /// On iOS, this is expected to be handled at the WebRTC level and the
  /// native implementation is effectively a no-op.
  Future<bool> setMute(bool muted) async {
    try {
      await _channel.invokeMethod<void>(
        'setMute',
        <String, dynamic>{'muted': muted},
      );
      _isMuted = muted;
      return true;
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('AudioService: failed to set mute: ${e.message}');
      return false;
    }
  }

  /// Reset audio routing back to normal (non-call) mode.
  Future<void> resetAudio() async {
    await stopIncomingCallAudio();
    _isSpeakerOn = false;
    _isMuted = false;

    try {
      await _channel.invokeMethod<void>(
        'setAudioMode',
        <String, dynamic>{'mode': 'normal'},
      );
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('AudioService: failed to reset audio mode: ${e.message}');
    }
  }

  /// Clean up any resources and reset state.
  Future<void> dispose() async {
    await resetAudio();
  }
}
