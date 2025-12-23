import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/services/audio_control_service.dart';
import '../../domain/models/audio_control_state.dart';
import '../../domain/models/audio_output_type.dart';

/// Provider that manages audio control state for the UI layer.
///
/// This provider wraps [AudioControlService] and exposes its state
/// in a way that's compatible with Flutter's `ChangeNotifier` pattern.
class AudioControlProvider extends ChangeNotifier {
  final AudioControlService _audioService;

  StreamSubscription<AudioControlState>? _stateSubscription;

  AudioControlState _state = AudioControlState.initial();

  /// Whether an operation is currently in progress.
  bool _isLoading = false;

  AudioControlProvider({required AudioControlService audioService})
      : _audioService = audioService {
    _subscribeToStateChanges();
  }

  /// Current audio control state.
  AudioControlState get state => _state;

  /// Whether the microphone is muted.
  bool get isMuted => _state.isMuted;

  /// Whether the speaker is enabled.
  bool get isSpeakerOn => _state.isSpeakerOn;

  /// Current audio output type.
  AudioOutputType get currentOutput => _state.currentOutput;

  /// Available audio output options.
  List<AudioOutputType> get availableOutputs => _state.availableOutputs;

  /// Whether Bluetooth is connected.
  bool get isBluetoothConnected => _state.isBluetoothConnected;

  /// Name of connected Bluetooth device.
  String? get bluetoothDeviceName => _state.bluetoothDeviceName;

  /// Whether an operation is in progress.
  bool get isLoading => _isLoading || _state.isChangingAudio;

  /// Error message from last operation.
  String? get errorMessage => _state.errorMessage;

  /// Whether multiple audio outputs are available.
  bool get hasMultipleOutputs => _state.availableOutputs.length > 2;

  void _subscribeToStateChanges() {
    _stateSubscription = _audioService.stateStream.listen(
      (AudioControlState newState) {
        _state = newState;
        notifyListeners();
      },
      onError: (Object error) {
        debugPrint('AudioControlProvider: Stream error - $error');
      },
    );
  }

  /// Initializes the audio service.
  ///
  /// Call this when a call is established.
  Future<void> initialize() async {
    if (_audioService.isInitialized) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _audioService.initialize();
    } catch (e) {
      debugPrint('AudioControlProvider: Initialization failed - $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggles the microphone mute state.
  Future<void> toggleMute() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _audioService.toggleMute();
    } catch (e) {
      debugPrint('AudioControlProvider: Toggle mute failed - $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggles the speaker state.
  Future<void> toggleSpeaker() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _audioService.toggleSpeaker();
    } catch (e) {
      debugPrint('AudioControlProvider: Toggle speaker failed - $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sets a specific audio output.
  Future<void> setAudioOutput(AudioOutputType outputType) async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _audioService.setAudioOutput(outputType);
    } catch (e) {
      debugPrint('AudioControlProvider: Set audio output failed - $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Resets audio state when call ends.
  Future<void> resetForCallEnd() async {
    try {
      await _audioService.resetForCallEnd();
    } catch (e) {
      debugPrint('AudioControlProvider: Reset failed - $e');
    }
  }

  /// Clears any error message.
  void clearError() {
    if (_state.errorMessage != null) {
      _state = _state.copyWith(errorMessage: null);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    super.dispose();
  }
}


