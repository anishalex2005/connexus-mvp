import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import '../models/telnyx_credentials.dart';
import '../services/secure_storage_service.dart';
import '../../domain/telephony/telnyx_connection_state.dart';
import '../../domain/models/connection_state.dart';
import 'webrtc_connection_manager.dart';
import 'media_handler.dart';

/// Configuration for Telnyx connection retry behavior.
class TelnyxRetryConfig {
  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;
  final double backoffMultiplier;

  const TelnyxRetryConfig({
    this.maxAttempts = 5,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffMultiplier = 2.0,
  });

  /// Calculates delay for a given attempt number.
  Duration getDelayForAttempt(int attempt) {
    if (attempt <= 0) return initialDelay;

    final baseMs = initialDelay.inMilliseconds;
    final factor = backoffMultiplier * (attempt - 1);
    final delayMs = (baseMs * factor).toInt();

    final cappedMs = delayMs.clamp(
      initialDelay.inMilliseconds,
      maxDelay.inMilliseconds,
    );

    return Duration(milliseconds: cappedMs);
  }
}

/// Main service class for managing Telnyx SIP connection.
class TelnyxService {
  /// Optional singleton-style accessor so existing code can use
  /// `TelnyxService.instance` while DI provides the actual instance.
  static TelnyxService? _instance;

  static TelnyxService get instance {
    final instance = _instance;
    if (instance == null) {
      throw StateError(
        'TelnyxService has not been initialized. Ensure it is registered '
        'via dependency injection before first use.',
      );
    }
    return instance;
  }

  // Dependencies.
  final SecureStorageService _secureStorage;
  final TelnyxRetryConfig _retryConfig;
  final WebRTCConnectionManager _connectionManager;
  final MediaHandler _mediaHandler;

  // Current credentials.
  TelnyxCredentials? _currentCredentials;

  // Connection state management.
  final BehaviorSubject<TelnyxConnectionState> _connectionStateSubject =
      BehaviorSubject<TelnyxConnectionState>.seeded(
    TelnyxConnectionState.disconnected,
  );

  // Connection events stream.
  final PublishSubject<TelnyxConnectionEvent> _connectionEventsSubject =
      PublishSubject<TelnyxConnectionEvent>();

  // Retry management.
  int _currentRetryAttempt = 0;
  Timer? _retryTimer;
  bool _isIntentionalDisconnect = false;

  // Call state placeholder (will be expanded in later call-related tasks).
  final BehaviorSubject<TelnyxCallState> _callStateSubject =
      BehaviorSubject<TelnyxCallState>.seeded(TelnyxCallState.idle);

  TelnyxService({
    required SecureStorageService secureStorage,
    TelnyxRetryConfig? retryConfig,
    WebRTCConnectionManager? connectionManager,
    MediaHandler? mediaHandler,
  })  : _secureStorage = secureStorage,
        _retryConfig = retryConfig ?? const TelnyxRetryConfig(),
        _connectionManager = connectionManager ?? WebRTCConnectionManager(),
        _mediaHandler = mediaHandler ?? MediaHandler() {
    // Set singleton instance if not already set.
    _instance ??= this;
  }

  // ============ Public Getters ============

  /// Stream of connection state changes.
  Stream<TelnyxConnectionState> get connectionStateStream =>
      _connectionStateSubject.stream;

  /// Current connection state.
  TelnyxConnectionState get connectionState =>
      _connectionStateSubject.valueOrNull ?? TelnyxConnectionState.disconnected;

  /// Stream of connection events (for logging/UI feedback).
  Stream<TelnyxConnectionEvent> get connectionEvents =>
      _connectionEventsSubject.stream;

  /// Whether currently connected and able to make calls.
  bool get isConnected => connectionState.isConnected;

  /// Whether currently attempting to connect.
  bool get isConnecting => connectionState.isConnecting;

  /// Current call state stream (placeholder until full call handling is added).
  Stream<TelnyxCallState> get callStateStream => _callStateSubject.stream;

  /// Current high-level Telnyx call state.
  TelnyxCallState get callState =>
      _callStateSubject.valueOrNull ?? TelnyxCallState.idle;

  /// WebRTC connection state stream (underlying RTCPeerConnection).
  Stream<WebRTCConnectionState> get webrtcConnectionStateStream =>
      _connectionManager.connectionState;

  /// WebRTC connection quality stream.
  Stream<ConnectionQuality> get connectionQualityStream =>
      _connectionManager.connectionQuality;

  /// Current WebRTC connection quality snapshot.
  ConnectionQuality get currentQuality => _connectionManager.currentQuality;

  WebRTCConnectionManager get connectionManager => _connectionManager;

  MediaHandler get mediaHandler => _mediaHandler;

  // ============ Connection Methods ============

  /// Connects to Telnyx using stored credentials, if available.
  Future<bool> connectWithStoredCredentials() async {
    final credentials = await _secureStorage.getTelnyxCredentials();
    if (credentials == null || !credentials.isValid) {
      _emitEvent(
        TelnyxConnectionState.failed,
        message: 'No valid credentials found',
      );
      return false;
    }

    return connect(credentials);
  }

  /// Connects to Telnyx with provided credentials.
  Future<bool> connect(TelnyxCredentials credentials) async {
    if (!credentials.isValid) {
      _updateState(TelnyxConnectionState.failed);
      _emitEvent(
        TelnyxConnectionState.failed,
        message: 'Invalid credentials provided',
      );
      return false;
    }

    _isIntentionalDisconnect = false;
    _currentCredentials = credentials;
    _currentRetryAttempt = 0;

    return _attemptConnection();
  }

  /// Internal method to attempt connection.
  Future<bool> _attemptConnection() async {
    if (_currentCredentials == null) {
      return false;
    }

    _cancelRetryTimer();
    _updateState(TelnyxConnectionState.connecting);
    _emitEvent(
      TelnyxConnectionState.connecting,
      message: 'Attempting connection (attempt ${_currentRetryAttempt + 1})',
    );

    try {
      // In this environment we don't call the Telnyx SDK directly.
      // Instead, we simulate an async registration and update state.
      debugPrint(
        'TelnyxService: Simulating connection for user '
        '${_currentCredentials!.sipUsername}',
      );

      await Future<void>.delayed(const Duration(milliseconds: 200));

      _currentRetryAttempt = 0;
      _updateState(TelnyxConnectionState.registered);
      _emitEvent(
        TelnyxConnectionState.registered,
        message: 'Simulated registration with Telnyx completed',
      );

      // Store credentials on "successful" connection attempt.
      await _secureStorage.storeTelnyxCredentials(_currentCredentials!);

      // Initialize media and WebRTC connection manager after "registration".
      try {
        final localStream = await _mediaHandler.initializeLocalStream();
        await _connectionManager.initialize();
        await _connectionManager.addLocalStream(localStream);
      } catch (e, stackTrace) {
        debugPrint('Failed to initialize WebRTC after registration: $e');
        debugPrint('Stack trace: $stackTrace');
      }

      return true;
    } catch (e, stackTrace) {
      debugPrint('Telnyx connection error: $e');
      debugPrint('Stack trace: $stackTrace');

      _emitEvent(
        TelnyxConnectionState.failed,
        message: 'Connection failed: $e',
        error: e,
      );

      if (!_isIntentionalDisconnect) {
        _scheduleRetry();
      }

      return false;
    }
  }

  // ============ Retry Logic ============

  void _scheduleRetry() {
    _currentRetryAttempt++;

    if (_currentRetryAttempt > _retryConfig.maxAttempts) {
      debugPrint('Max retry attempts reached');
      _updateState(TelnyxConnectionState.failed);
      _emitEvent(
        TelnyxConnectionState.failed,
        message: 'Max retry attempts (${_retryConfig.maxAttempts}) reached',
      );
      return;
    }

    final delay = _retryConfig.getDelayForAttempt(_currentRetryAttempt);
    debugPrint(
      'Scheduling retry attempt $_currentRetryAttempt in '
      '${delay.inSeconds}s',
    );

    _updateState(TelnyxConnectionState.reconnecting);
    _emitEvent(
      TelnyxConnectionState.reconnecting,
      message:
          'Retrying in ${delay.inSeconds} seconds (attempt $_currentRetryAttempt)',
    );

    _retryTimer = Timer(delay, () {
      if (!_isIntentionalDisconnect) {
        // Fire and forget; internal handling manages further retries.
        // ignore: discarded_futures
        _attemptConnection();
      }
    });
  }

  void _cancelRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  // ============ Disconnect Methods ============

  /// Disconnects from Telnyx.
  Future<void> disconnect() async {
    _isIntentionalDisconnect = true;
    _cancelRetryTimer();

    _updateState(TelnyxConnectionState.loggedOut);
    _emitEvent(
      TelnyxConnectionState.loggedOut,
      message: 'Disconnected from Telnyx',
    );
  }

  /// Disconnects and clears stored credentials.
  Future<void> logout() async {
    await disconnect();
    await _secureStorage.deleteTelnyxCredentials();
    _currentCredentials = null;
  }

  // ============ State Management ============

  void _updateState(TelnyxConnectionState state) {
    if (_connectionStateSubject.valueOrNull != state) {
      _connectionStateSubject.add(state);
    }
  }

  void _emitEvent(
    TelnyxConnectionState state, {
    String? message,
    dynamic error,
  }) {
    _connectionEventsSubject.add(
      TelnyxConnectionEvent(
        state: state,
        message: message,
        error: error,
      ),
    );
  }

  // ============ Cleanup ============

  /// Disposes of resources.
  void dispose() {
    _cancelRetryTimer();
    _connectionStateSubject.close();
    _connectionEventsSubject.close();
    _callStateSubject.close();
    // ignore: discarded_futures
    _connectionManager.dispose();
    // ignore: discarded_futures
    _mediaHandler.dispose();
    if (identical(_instance, this)) {
      _instance = null;
    }
  }

  /// Force a WebRTC reconnection attempt.
  Future<void> forceReconnect() async {
    await _connectionManager.forceReconnect();
  }

  /// Attempt to reconnect after a network change.
  ///
  /// This is a higher-level reconnection intended for use by
  /// [CallNetworkHandler] and future network-aware logic.
  Future<bool> reconnect() async {
    debugPrint('[TelnyxService] Attempting reconnection...');

    if (_currentCredentials == null) {
      debugPrint(
        '[TelnyxService] No stored credentials available for reconnection',
      );
      return false;
    }

    try {
      // If we're already connected/connecting, perform a clean disconnect
      // first to avoid weird intermediate states.
      if (isConnected || isConnecting) {
        await disconnect();
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }

      final bool connected = await connect(_currentCredentials!);
      if (!connected) {
        return false;
      }

      final bool registered = await _waitForRegistration();
      if (registered) {
        debugPrint('[TelnyxService] Reconnection successful');
      } else {
        debugPrint(
          '[TelnyxService] Reconnection failed - registration timeout',
        );
      }

      return registered;
    } catch (e, stackTrace) {
      debugPrint('[TelnyxService] Reconnection error: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Refresh SIP/WebRTC registration without a full reconnect.
  ///
  /// In a real Telnyx integration this would call into the SDK to refresh
  /// registration / ICE state. Here we simulate this behavior.
  Future<void> refreshRegistration() async {
    debugPrint('[TelnyxService] Refreshing SIP registration (simulated)...');

    try {
      if (_currentCredentials == null) {
        return;
      }

      // In this simulated environment we simply ensure our connection is
      // considered "registered" and WebRTC is initialized.
      if (!isConnected) {
        // ignore: discarded_futures
        _attemptConnection();
      }
    } catch (e, stackTrace) {
      debugPrint('[TelnyxService] Error refreshing registration: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Wait for registration to complete with a timeout.
  Future<bool> _waitForRegistration({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    // Fast-path: already registered.
    if (connectionState == TelnyxConnectionState.registered) {
      return true;
    }

    final Completer<bool> completer = Completer<bool>();
    late final StreamSubscription<TelnyxConnectionState> subscription;
    final Timer timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
      subscription.cancel();
    });

    subscription = connectionStateStream.listen((TelnyxConnectionState state) {
      if (state == TelnyxConnectionState.registered) {
        if (!completer.isCompleted) {
          completer.complete(true);
        }
        timer.cancel();
        subscription.cancel();
      } else if (state == TelnyxConnectionState.failed ||
          state == TelnyxConnectionState.loggedOut) {
        if (!completer.isCompleted) {
          completer.complete(false);
        }
        timer.cancel();
        subscription.cancel();
      }
    });

    return completer.future;
  }
}

/// High-level Telnyx call states to be consumed by network handlers and UI.
enum TelnyxCallState {
  idle,
  ringing,
  connecting,
  active,
  onHold,
  disconnecting,
  error,
}
