import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/models/connection_state.dart';
import '../../data/services/telnyx_service.dart';

/// Provider for managing and exposing WebRTC connection state to UI.
class ConnectionStateProvider extends ChangeNotifier {
  final TelnyxService _telnyxService;

  StreamSubscription<WebRTCConnectionState>? _stateSubscription;
  StreamSubscription<ConnectionQuality>? _qualitySubscription;

  WebRTCConnectionState _connectionState = WebRTCConnectionState.idle;
  ConnectionQuality _connectionQuality = const ConnectionQuality();
  String? _errorMessage;
  bool _isReconnecting = false;

  ConnectionStateProvider({required TelnyxService telnyxService})
      : _telnyxService = telnyxService {
    _subscribeToStreams();
  }

  // Getters.
  WebRTCConnectionState get connectionState => _connectionState;
  ConnectionQuality get connectionQuality => _connectionQuality;
  String? get errorMessage => _errorMessage;
  bool get isReconnecting => _isReconnecting;
  bool get isConnected => _connectionState == WebRTCConnectionState.connected;

  /// Get quality indicator color.
  int get qualityColor {
    switch (_connectionQuality.qualityLevel) {
      case 'excellent':
        return 0xFF4CAF50; // Green.
      case 'good':
        return 0xFF8BC34A; // Light green.
      case 'fair':
        return 0xFFFFC107; // Yellow.
      case 'poor':
        return 0xFFF44336; // Red.
      default:
        return 0xFF9E9E9E; // Grey.
    }
  }

  /// Get quality indicator text.
  String get qualityText {
    switch (_connectionQuality.qualityLevel) {
      case 'excellent':
        return 'Excellent';
      case 'good':
        return 'Good';
      case 'fair':
        return 'Fair';
      case 'poor':
        return 'Poor Connection';
      default:
        return 'Checking...';
    }
  }

  void _subscribeToStreams() {
    _stateSubscription =
        _telnyxService.webrtcConnectionStateStream.listen((state) {
      _connectionState = state;
      _isReconnecting = state == WebRTCConnectionState.reconnecting;

      if (state == WebRTCConnectionState.failed) {
        _errorMessage = 'Connection failed. Please check your network.';
      } else {
        _errorMessage = null;
      }

      notifyListeners();
    });

    _qualitySubscription =
        _telnyxService.connectionQualityStream.listen((quality) {
      _connectionQuality = quality;
      notifyListeners();
    });
  }

  /// Manually trigger reconnection.
  Future<void> reconnect() async {
    _isReconnecting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _telnyxService.forceReconnect();
    } catch (e) {
      _errorMessage = 'Reconnection failed: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _qualitySubscription?.cancel();
    super.dispose();
  }
}
