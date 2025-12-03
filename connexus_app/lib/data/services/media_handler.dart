import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../core/utils/logger.dart' as app_logger;

/// Handles local media capture for WebRTC calls.
class MediaHandler {
  MediaStream? _localStream;
  bool _isMuted = false;
  bool _isSpeakerOn = false;

  MediaStream? get localStream => _localStream;
  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;

  /// Audio constraints for voice calls.
  static const Map<String, dynamic> audioConstraints = <String, dynamic>{
    'audio': <String, dynamic>{
      'echoCancellation': true,
      'noiseSuppression': true,
      'autoGainControl': true,
      'sampleRate': 48000,
      'channelCount': 1,
    },
    'video': false,
  };

  /// Initialize and capture local audio stream.
  Future<MediaStream> initializeLocalStream() async {
    app_logger.Logger.info('Initializing local media stream');
    try {
      _localStream = await navigator.mediaDevices.getUserMedia(
        audioConstraints,
      );
      app_logger.Logger.info(
        'Local stream initialized with '
        '${_localStream!.getAudioTracks().length} audio tracks',
      );
      return _localStream!;
    } catch (e, stackTrace) {
      app_logger.Logger.error(
        'Failed to initialize local stream',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Toggle microphone mute.
  Future<void> toggleMute() async {
    final MediaStream? stream = _localStream;
    if (stream == null) {
      app_logger.Logger.warning('Cannot toggle mute: no local stream');
      return;
    }

    _isMuted = !_isMuted;
    for (final MediaStreamTrack track in stream.getAudioTracks()) {
      track.enabled = !_isMuted;
    }

    app_logger.Logger.info('Microphone ${_isMuted ? 'muted' : 'unmuted'}');
  }

  /// Set mute state explicitly.
  Future<void> setMute(bool muted) async {
    final MediaStream? stream = _localStream;
    if (stream == null) return;

    _isMuted = muted;
    for (final MediaStreamTrack track in stream.getAudioTracks()) {
      track.enabled = !_isMuted;
    }

    app_logger.Logger.info('Microphone mute set to: $_isMuted');
  }

  /// Toggle speaker output.
  Future<void> toggleSpeaker() async {
    _isSpeakerOn = !_isSpeakerOn;
    await Helper.setSpeakerphoneOn(_isSpeakerOn);
    app_logger.Logger.info('Speaker ${_isSpeakerOn ? 'enabled' : 'disabled'}');
  }

  /// Set speaker state explicitly.
  Future<void> setSpeaker(bool enabled) async {
    _isSpeakerOn = enabled;
    await Helper.setSpeakerphoneOn(_isSpeakerOn);
    app_logger.Logger.info('Speaker set to: $_isSpeakerOn');
  }

  /// Get available audio input devices.
  Future<List<MediaDeviceInfo>> getAudioInputDevices() async {
    final List<MediaDeviceInfo> devices =
        await navigator.mediaDevices.enumerateDevices();
    return devices
        .where((MediaDeviceInfo d) => d.kind == 'audioinput')
        .toList();
  }

  /// Get available audio output devices.
  Future<List<MediaDeviceInfo>> getAudioOutputDevices() async {
    final List<MediaDeviceInfo> devices =
        await navigator.mediaDevices.enumerateDevices();
    return devices
        .where((MediaDeviceInfo d) => d.kind == 'audiooutput')
        .toList();
  }

  /// Switch to a different audio input device.
  Future<void> switchAudioInput(String deviceId) async {
    app_logger.Logger.info('Switching audio input to device: $deviceId');

    // Stop current tracks.
    await disposeLocalStream();

    final Map<String, dynamic> constraints = <String, dynamic>{
      'audio': <String, dynamic>{
        ...audioConstraints['audio'] as Map<String, dynamic>,
        'deviceId': deviceId,
      },
      'video': false,
    };

    _localStream = await navigator.mediaDevices.getUserMedia(constraints);
    app_logger.Logger.info('Switched to audio input device: $deviceId');
  }

  /// Dispose of local media stream.
  Future<void> disposeLocalStream() async {
    final MediaStream? stream = _localStream;
    if (stream != null) {
      for (final MediaStreamTrack track in stream.getTracks()) {
        await track.stop();
      }
      await stream.dispose();
      _localStream = null;
      app_logger.Logger.info('Local stream disposed');
    }
  }

  /// Clean up all resources.
  Future<void> dispose() async {
    await disposeLocalStream();
  }
}
