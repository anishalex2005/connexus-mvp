import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import '../../domain/models/network_state.dart';
import 'network_monitor_service.dart';
import 'telnyx_service.dart';

/// Handles the interaction between network changes and active calls.
///
/// Responsible for maintaining call stability during network transitions.
class CallNetworkHandler {
  final NetworkMonitorService _networkMonitor;
  final TelnyxService _telnyxService;

  // Stream subscriptions.
  StreamSubscription<NetworkChangeEvent>? _networkChangeSubscription;

  // State tracking.
  bool _hasActiveCall = false;
  bool _isReconnecting = false;
  DateTime? _reconnectionStartTime;

  // Reconnection configuration.
  static const Duration _reconnectionTimeout = Duration(seconds: 30);
  static const Duration _networkStabilizationDelay = Duration(seconds: 2);

  // Event streams (for UI/analytics).
  final PublishSubject<CallNetworkEvent> _callNetworkEventController =
      PublishSubject<CallNetworkEvent>();

  CallNetworkHandler({
    required NetworkMonitorService networkMonitor,
    required TelnyxService telnyxService,
  })  : _networkMonitor = networkMonitor,
        _telnyxService = telnyxService;

  /// Stream of call-network related events.
  Stream<CallNetworkEvent> get callNetworkEvents =>
      _callNetworkEventController.stream;

  /// Whether a reconnection is in progress.
  bool get isReconnecting => _isReconnecting;

  /// Initialize the handler and start listening to network changes.
  Future<void> initialize() async {
    debugPrint('[CallNetworkHandler] Initializing...');

    // Ensure network monitoring is active.
    if (!_networkMonitor.isMonitoring) {
      await _networkMonitor.startMonitoring();
    }

    // Subscribe to network change events.
    _networkChangeSubscription =
        _networkMonitor.networkChangeStream.listen(_handleNetworkChange);

    // Hook for future Telnyx call state integration (Task 15/17).
    _telnyxService.callStateStream.listen(_handleCallStateChange);

    debugPrint('[CallNetworkHandler] Initialized successfully');
  }

  /// Notify the handler that a call has started.
  void onCallStarted() {
    _hasActiveCall = true;
    debugPrint(
      '[CallNetworkHandler] Call started, monitoring network closely',
    );
  }

  /// Notify the handler that a call has ended.
  void onCallEnded() {
    _hasActiveCall = false;
    _isReconnecting = false;
    _reconnectionStartTime = null;
    debugPrint(
      '[CallNetworkHandler] Call ended, relaxing network monitoring',
    );
  }

  /// Manually trigger a reconnection attempt (e.g., from UI).
  Future<bool> attemptReconnection() async {
    if (_isReconnecting) {
      debugPrint('[CallNetworkHandler] Reconnection already in progress');
      return false;
    }

    return _performReconnection(ReconnectionReason.manual);
  }

  /// Get current network suitability for calls.
  NetworkCallSuitability getNetworkSuitability() {
    final NetworkState state = _networkMonitor.currentState;

    if (!state.isConnected) {
      return const NetworkCallSuitability(
        canMakeCalls: false,
        canReceiveCalls: false,
        reason: 'No network connection',
        recommendedAction: 'Please check your internet connection',
      );
    }

    if (state.quality == NetworkQuality.poor) {
      return const NetworkCallSuitability(
        canMakeCalls: true,
        canReceiveCalls: true,
        reason: 'Poor network quality',
        recommendedAction: 'Call quality may be affected. Consider using WiFi.',
        warning: true,
      );
    }

    if (state.quality == NetworkQuality.unstable) {
      return const NetworkCallSuitability(
        canMakeCalls: false,
        canReceiveCalls: true,
        reason: 'Unstable network connection',
        recommendedAction:
            'Network is unstable. Try moving to a better location.',
        warning: true,
      );
    }

    return const NetworkCallSuitability(
      canMakeCalls: true,
      canReceiveCalls: true,
      reason: 'Network is ready for calls',
    );
  }

  // -------- Private handlers --------

  void _handleNetworkChange(NetworkChangeEvent event) {
    debugPrint(
      '[CallNetworkHandler] Network change detected: ${event.changeType}',
    );

    // Emit network event for UI updates.
    _callNetworkEventController.add(
      CallNetworkEvent(
        type: _mapChangeTypeToEventType(event.changeType),
        networkState: event.currentState,
        previousState: event.previousState,
        timestamp: event.timestamp,
      ),
    );

    // Only handle reconnection if there's an active call.
    if (!_hasActiveCall) {
      debugPrint(
        '[CallNetworkHandler] No active call, skipping reconnection logic',
      );
      return;
    }

    switch (event.changeType) {
      case NetworkChangeType.disconnected:
        _handleDisconnection();
        break;
      case NetworkChangeType.reconnected:
        // Ignore if we have timed out.
        if (_reconnectionStartTime != null &&
            DateTime.now().difference(_reconnectionStartTime!) >
                _reconnectionTimeout) {
          debugPrint(
            '[CallNetworkHandler] Reconnection timeout exceeded; ignoring',
          );
          break;
        }
        // ignore: discarded_futures
        _handleReconnection();
        break;
      case NetworkChangeType.typeChanged:
        // ignore: discarded_futures
        _handleNetworkTypeChange(event);
        break;
      case NetworkChangeType.qualityChanged:
        _handleQualityChange(event.currentState.quality);
        break;
      case NetworkChangeType.initial:
        // No action needed for initial state.
        break;
    }
  }

  void _handleCallStateChange(dynamic callState) {
    // Placeholder for future Telnyx call state integration.
    // For now, callers should invoke onCallStarted/onCallEnded explicitly.
    // This keeps Task 16 focused on network handling.
  }

  void _handleDisconnection() {
    debugPrint(
      '[CallNetworkHandler] Network disconnected during active call',
    );

    _reconnectionStartTime = DateTime.now();

    _callNetworkEventController.add(
      CallNetworkEvent(
        type: CallNetworkEventType.connectionLost,
        networkState: _networkMonitor.currentState,
        timestamp: DateTime.now(),
        message: 'Network connection lost. Attempting to reconnect...',
      ),
    );

    // The Telnyx/Telnyx-WebRTC layers will typically handle putting the
    // media on hold. We focus on re-registering/reconnecting once network
    // is restored.
  }

  Future<void> _handleReconnection() async {
    debugPrint(
      '[CallNetworkHandler] Network reconnected, attempting call recovery',
    );

    // Wait for network to stabilize.
    await Future<void>.delayed(_networkStabilizationDelay);

    // Verify we're still connected.
    final NetworkState currentState = await _networkMonitor.checkConnectivity();
    if (!currentState.isConnected) {
      debugPrint('[CallNetworkHandler] Network unstable after reconnection');
      return;
    }

    await _performReconnection(ReconnectionReason.networkRecovered);
  }

  Future<void> _handleNetworkTypeChange(NetworkChangeEvent event) async {
    debugPrint(
      '[CallNetworkHandler] Network type changed during call: '
      '${event.previousState.status} -> ${event.currentState.status}',
    );

    _callNetworkEventController.add(
      CallNetworkEvent(
        type: CallNetworkEventType.networkTypeChanged,
        networkState: event.currentState,
        previousState: event.previousState,
        timestamp: DateTime.now(),
        message: 'Switching network connection...',
      ),
    );

    // Wait briefly for network to stabilize after handover.
    await Future<void>.delayed(_networkStabilizationDelay);

    await _performSeamlessHandover();
  }

  void _handleQualityChange(NetworkQuality quality) {
    debugPrint('[CallNetworkHandler] Network quality changed to: $quality');

    CallNetworkEventType eventType;
    String message;

    switch (quality) {
      case NetworkQuality.excellent:
      case NetworkQuality.good:
        eventType = CallNetworkEventType.qualityImproved;
        message = 'Network quality is good';
        break;
      case NetworkQuality.poor:
        eventType = CallNetworkEventType.qualityDegraded;
        message = 'Network quality is poor. Call quality may be affected.';
        break;
      case NetworkQuality.unstable:
        eventType = CallNetworkEventType.qualityDegraded;
        message = 'Network is unstable. Call may be interrupted.';
        break;
      case NetworkQuality.unknown:
        return; // Do not emit events for unknown quality.
    }

    _callNetworkEventController.add(
      CallNetworkEvent(
        type: eventType,
        networkState: _networkMonitor.currentState,
        timestamp: DateTime.now(),
        message: message,
      ),
    );
  }

  Future<bool> _performReconnection(ReconnectionReason reason) async {
    if (_isReconnecting) return false;

    _isReconnecting = true;
    _reconnectionStartTime ??= DateTime.now();

    debugPrint('[CallNetworkHandler] Starting reconnection (reason: $reason)');

    _callNetworkEventController.add(
      CallNetworkEvent(
        type: CallNetworkEventType.reconnecting,
        networkState: _networkMonitor.currentState,
        timestamp: DateTime.now(),
        message: 'Reconnecting call...',
      ),
    );

    try {
      final bool success = await _telnyxService.reconnect();

      if (success) {
        debugPrint('[CallNetworkHandler] Reconnection successful');

        _callNetworkEventController.add(
          CallNetworkEvent(
            type: CallNetworkEventType.reconnected,
            networkState: _networkMonitor.currentState,
            timestamp: DateTime.now(),
            message: 'Call reconnected successfully',
          ),
        );

        return true;
      } else {
        throw Exception('Reconnection returned false');
      }
    } catch (e) {
      debugPrint('[CallNetworkHandler] Reconnection failed: $e');

      _callNetworkEventController.add(
        CallNetworkEvent(
          type: CallNetworkEventType.reconnectionFailed,
          networkState: _networkMonitor.currentState,
          timestamp: DateTime.now(),
          message: 'Failed to reconnect call',
          error: e.toString(),
        ),
      );

      return false;
    } finally {
      _isReconnecting = false;
      _reconnectionStartTime = null;
    }
  }

  Future<void> _performSeamlessHandover() async {
    debugPrint('[CallNetworkHandler] Performing seamless network handover');

    try {
      // In a real Telnyx integration this would trigger ICE restarts and
      // possibly media renegotiation. Our abstraction keeps this simple.
      await _telnyxService.refreshRegistration();

      debugPrint('[CallNetworkHandler] Seamless handover completed');

      _callNetworkEventController.add(
        CallNetworkEvent(
          type: CallNetworkEventType.handoverCompleted,
          networkState: _networkMonitor.currentState,
          timestamp: DateTime.now(),
          message: 'Network handover completed',
        ),
      );
    } catch (e) {
      debugPrint('[CallNetworkHandler] Seamless handover failed: $e');

      // Fall back to full reconnection.
      // ignore: discarded_futures
      _performReconnection(ReconnectionReason.handoverFailed);
    }
  }

  CallNetworkEventType _mapChangeTypeToEventType(NetworkChangeType type) {
    switch (type) {
      case NetworkChangeType.disconnected:
        return CallNetworkEventType.connectionLost;
      case NetworkChangeType.reconnected:
        return CallNetworkEventType.reconnected;
      case NetworkChangeType.typeChanged:
        return CallNetworkEventType.networkTypeChanged;
      case NetworkChangeType.qualityChanged:
        return CallNetworkEventType.qualityDegraded;
      case NetworkChangeType.initial:
        return CallNetworkEventType.initialized;
    }
  }

  /// Clean up resources.
  Future<void> dispose() async {
    await _networkChangeSubscription?.cancel();
    await _callNetworkEventController.close();
  }
}

/// Events related to call-network interactions.
class CallNetworkEvent {
  final CallNetworkEventType type;
  final NetworkState networkState;
  final NetworkState? previousState;
  final DateTime timestamp;
  final String? message;
  final String? error;

  const CallNetworkEvent({
    required this.type,
    required this.networkState,
    this.previousState,
    required this.timestamp,
    this.message,
    this.error,
  });
}

/// Types of call-network events.
enum CallNetworkEventType {
  initialized,
  connectionLost,
  reconnecting,
  reconnected,
  reconnectionFailed,
  networkTypeChanged,
  handoverCompleted,
  qualityImproved,
  qualityDegraded,
}

/// Reason for reconnection attempt.
enum ReconnectionReason {
  networkRecovered,
  networkTypeChanged,
  handoverFailed,
  manual,
}

/// Represents network suitability for making/receiving calls.
class NetworkCallSuitability {
  final bool canMakeCalls;
  final bool canReceiveCalls;
  final String reason;
  final String? recommendedAction;
  final bool warning;

  const NetworkCallSuitability({
    required this.canMakeCalls,
    required this.canReceiveCalls,
    required this.reason,
    this.recommendedAction,
    this.warning = false,
  });
}
