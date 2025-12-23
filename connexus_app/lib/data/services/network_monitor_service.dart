import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import '../../domain/models/network_state.dart';

/// Service responsible for monitoring network connectivity changes and
/// providing reactive streams of network state updates.
class NetworkMonitorService {
  final Connectivity _connectivity;

  // Stream controllers.
  final BehaviorSubject<NetworkState> _networkStateController;
  final PublishSubject<NetworkChangeEvent> _networkChangeController;

  // Subscription management.
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // State tracking.
  NetworkState _currentState = NetworkState.unknown();
  NetworkState _previousState = NetworkState.unknown();
  bool _isMonitoring = false;

  // Debounce timer to avoid rapid-fire events during transitions.
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  // Reconnection tracking (hook for Task 17).
  // Some of these fields are currently only used by experimental retry logic;
  // we keep them for future tasks but silence unused_field warnings explicitly.
  // ignore: unused_field
  DateTime? _lastDisconnectionTime;
  // ignore: unused_field
  int _reconnectionAttempts = 0;
  // ignore: unused_field
  static const int _maxReconnectionAttempts = 5;
  // ignore: unused_field
  static const Duration _reconnectionCooldown = Duration(seconds: 30);

  NetworkMonitorService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity(),
        _networkStateController = BehaviorSubject<NetworkState>.seeded(
          NetworkState.unknown(),
        ),
        _networkChangeController = PublishSubject<NetworkChangeEvent>();

  /// Stream of current network state (always emits current value on subscribe).
  Stream<NetworkState> get networkStateStream =>
      _networkStateController.stream.distinct();

  /// Stream of network change events (only emits on changes).
  Stream<NetworkChangeEvent> get networkChangeStream =>
      _networkChangeController.stream;

  /// Current network state snapshot.
  NetworkState get currentState => _currentState;

  /// Whether the service is actively monitoring.
  bool get isMonitoring => _isMonitoring;

  /// Whether device is currently connected to any network.
  bool get isConnected => _currentState.isConnected;

  /// Whether current network is suitable for VoIP calls.
  bool get isSuitableForCalls => _currentState.isSuitableForCalls;

  /// Initialize and start monitoring network changes.
  Future<void> startMonitoring() async {
    if (_isMonitoring) {
      debugPrint('[NetworkMonitor] Already monitoring, skipping start');
      return;
    }

    debugPrint('[NetworkMonitor] Starting network monitoring...');
    _isMonitoring = true;

    // Get initial connectivity state.
    await _checkInitialConnectivity();

    // Subscribe to connectivity changes.
    _connectivitySubscription = _connectivity.onConnectivityChanged
        .listen(_handleConnectivityChange, onError: (Object error) {
      debugPrint('[NetworkMonitor] Connectivity stream error: $error');
      _handleConnectivityError(error);
    });

    debugPrint('[NetworkMonitor] Network monitoring started successfully');
  }

  /// Stop monitoring network changes.
  Future<void> stopMonitoring() async {
    if (!_isMonitoring) return;

    debugPrint('[NetworkMonitor] Stopping network monitoring...');
    _isMonitoring = false;

    _debounceTimer?.cancel();
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;

    debugPrint('[NetworkMonitor] Network monitoring stopped');
  }

  /// Check current connectivity status (on-demand, without side effects).
  Future<NetworkState> checkConnectivity() async {
    try {
      final List<ConnectivityResult> results =
          await _connectivity.checkConnectivity();
      final NetworkState newState = _mapConnectivityResults(results);
      return newState;
    } catch (e) {
      debugPrint('[NetworkMonitor] Error checking connectivity: $e');
      return NetworkState.unknown();
    }
  }

  /// Force a connectivity recheck and emit update even if unchanged.
  Future<void> forceRecheck() async {
    debugPrint('[NetworkMonitor] Forcing connectivity recheck...');
    final NetworkState newState = await checkConnectivity();
    _updateState(newState, forceEmit: true);
  }

  /// Check if we can reach a specific host (for more reliable detection).
  Future<bool> canReachHost(String host, {int port = 443}) async {
    try {
      final List<InternetAddress> result = await InternetAddress.lookup(host);
      if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) {
        final Socket socket = await Socket.connect(
          host,
          port,
          timeout: const Duration(seconds: 5),
        );
        socket.destroy();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[NetworkMonitor] Cannot reach host $host: $e');
      return false;
    }
  }

  /// Verify internet connectivity by attempting to reach common hosts.
  Future<bool> verifyInternetConnectivity() async {
    const List<String> hosts = <String>[
      'google.com',
      'cloudflare.com',
      'apple.com',
    ];

    for (final String host in hosts) {
      if (await canReachHost(host)) {
        return true;
      }
    }
    return false;
  }

  // -------- Private helpers --------

  Future<void> _checkInitialConnectivity() async {
    try {
      final List<ConnectivityResult> results =
          await _connectivity.checkConnectivity();
      final NetworkState initialState = _mapConnectivityResults(results);

      _currentState = initialState;
      _previousState = initialState;
      _networkStateController.add(initialState);

      // Emit initial event.
      _networkChangeController.add(
        NetworkChangeEvent(
          previousState: NetworkState.unknown(),
          currentState: initialState,
          timestamp: DateTime.now(),
          changeType: NetworkChangeType.initial,
        ),
      );

      debugPrint('[NetworkMonitor] Initial state: $initialState');
    } catch (e) {
      debugPrint('[NetworkMonitor] Error getting initial connectivity: $e');
      _currentState = NetworkState.unknown();
      _networkStateController.add(_currentState);
    }
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    // Debounce rapid changes (common during network transitions).
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      final NetworkState newState = _mapConnectivityResults(results);
      _updateState(newState);
    });
  }

  void _updateState(NetworkState newState, {bool forceEmit = false}) {
    // Skip if state hasn't changed (unless forced).
    if (!forceEmit && newState == _currentState) {
      return;
    }

    _previousState = _currentState;
    _currentState = newState;

    // Determine change type.
    final NetworkChangeType changeType =
        _determineChangeType(_previousState, newState);

    // Track disconnection/reconnection metadata for future retry logic.
    if (changeType == NetworkChangeType.disconnected) {
      _lastDisconnectionTime = DateTime.now();
      _reconnectionAttempts = 0;
    } else if (changeType == NetworkChangeType.reconnected) {
      _reconnectionAttempts++;
    }

    // Emit new state.
    _networkStateController.add(newState);

    // Emit change event.
    final NetworkChangeEvent event = NetworkChangeEvent(
      previousState: _previousState,
      currentState: newState,
      timestamp: DateTime.now(),
      changeType: changeType,
    );
    _networkChangeController.add(event);

    debugPrint('[NetworkMonitor] State changed: $changeType');
    debugPrint('[NetworkMonitor] Previous: $_previousState');
    debugPrint('[NetworkMonitor] Current: $newState');
  }

  NetworkState _mapConnectivityResults(List<ConnectivityResult> results) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      return NetworkState.disconnected();
    }

    NetworkStatus status;
    String? connectionType;

    final ConnectivityResult primary = results.first;

    switch (primary) {
      case ConnectivityResult.wifi:
        status = NetworkStatus.wifi;
        connectionType = 'WiFi';
        break;
      case ConnectivityResult.mobile:
        status = NetworkStatus.cellular;
        connectionType = 'Cellular';
        break;
      case ConnectivityResult.ethernet:
        status = NetworkStatus.ethernet;
        connectionType = 'Ethernet';
        break;
      case ConnectivityResult.bluetooth:
      case ConnectivityResult.other:
      case ConnectivityResult.vpn:
        // VPN/other typically ride over WiFi or cellular; treat as unknown
        // but still connected so CallNetworkHandler can decide.
        status = NetworkStatus.unknown;
        connectionType = describeEnum(primary);
        break;
      case ConnectivityResult.none:
        // Handled above.
        status = NetworkStatus.disconnected;
        connectionType = 'None';
        break;
    }

    return NetworkState.connected(
      status: status,
      quality: NetworkQuality.good, // Placeholder until Task 18.
      connectionType: connectionType,
    );
  }

  NetworkChangeType _determineChangeType(
    NetworkState previous,
    NetworkState current,
  ) {
    if (!previous.isConnected && current.isConnected) {
      return NetworkChangeType.reconnected;
    }

    if (previous.isConnected && !current.isConnected) {
      return NetworkChangeType.disconnected;
    }

    if (previous.status != current.status) {
      return NetworkChangeType.typeChanged;
    }

    if (previous.quality != current.quality) {
      return NetworkChangeType.qualityChanged;
    }

    return NetworkChangeType.initial;
  }

  void _handleConnectivityError(Object error) {
    debugPrint('[NetworkMonitor] Handling connectivity error: $error');
    // On error, assume disconnected and emit.
    _updateState(NetworkState.disconnected());
  }

  /// Clean up resources.
  Future<void> dispose() async {
    await stopMonitoring();
    await _networkStateController.close();
    await _networkChangeController.close();
  }
}
