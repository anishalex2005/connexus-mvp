import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:rxdart/rxdart.dart';

import '../models/call_quality_metrics.dart';
import '../models/telnyx_credentials.dart';
import '../services/secure_storage_service.dart';
import '../../domain/telephony/telnyx_connection_state.dart';
import '../../domain/models/connection_state.dart';
import 'call_quality_service.dart';
import 'media_handler.dart';
import 'quality_metrics_logger.dart';
import 'webrtc_connection_manager.dart';

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
  final CallQualityService? _qualityService;
  final QualityMetricsLogger? _metricsLogger;

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

  // Call state placeholder (expanded in Task 21 for decline handling).
  final BehaviorSubject<TelnyxCallState> _callStateSubject =
      BehaviorSubject<TelnyxCallState>.seeded(TelnyxCallState.idle);

  /// Current call start time for duration tracking (used with quality metrics).
  DateTime? _callStartTime;

  /// Current call ID for logging quality metrics and call records.
  String? _currentCallId;

  /// Current caller number for logging and decline metadata.
  String? _currentCallerNumber;

  /// Current caller display name for logging and decline metadata.
  String? _currentCallerName;

  /// Current call direction (`incoming` or `outgoing`) for logging.
  String _currentCallDirection = 'incoming';

  /// Optional external callback when quality level changes.
  void Function(CallQualityLevel)? onQualityChange;

  TelnyxService({
    required SecureStorageService secureStorage,
    TelnyxRetryConfig? retryConfig,
    WebRTCConnectionManager? connectionManager,
    MediaHandler? mediaHandler,
    CallQualityService? qualityService,
    QualityMetricsLogger? qualityMetricsLogger,
  })  : _secureStorage = secureStorage,
        _retryConfig = retryConfig ?? const TelnyxRetryConfig(),
        _connectionManager = connectionManager ?? WebRTCConnectionManager(),
        _mediaHandler = mediaHandler ?? MediaHandler(),
        _qualityService = qualityService,
        _metricsLogger = qualityMetricsLogger {
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

  /// Stream of real-time call quality metrics (if monitoring is active).
  Stream<CallQualityMetrics>? get qualityMetricsStream =>
      _qualityService?.metricsStream;

  /// Stream of quality level changes.
  Stream<CallQualityLevel>? get qualityLevelStream =>
      _qualityService?.qualityLevelStream;

  /// Current quality metrics snapshot.
  CallQualityMetrics? get currentQualityMetrics =>
      _qualityService?.currentMetrics;

  /// Current overall quality level.
  CallQualityLevel? get currentQualityLevel =>
      _qualityService?.currentQualityLevel;

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

  /// Start quality monitoring for an active call.
  ///
  /// Should be called after a call is connected/answered, once a
  /// [RTCPeerConnection] is available.
  void startQualityMonitoring({
    required RTCPeerConnection peerConnection,
    String? callId,
  }) {
    final CallQualityService? qualityService = _qualityService;
    if (qualityService == null) {
      debugPrint('[TelnyxService] CallQualityService not available');
      return;
    }

    _currentCallId = callId ?? DateTime.now().millisecondsSinceEpoch.toString();
    _callStartTime = DateTime.now();

    // Forward quality changes to external listeners.
    qualityService.onQualityChange =
        (CallQualityLevel oldLevel, CallQualityLevel newLevel) {
      onQualityChange?.call(newLevel);
    };

    qualityService.startMonitoring(peerConnection, callId: _currentCallId);
  }

  /// Stop quality monitoring and log metrics.
  ///
  /// Should be called when a call ends.
  Future<void> stopQualityMonitoring({
    String? callerNumber,
    String? callDirection,
  }) async {
    final CallQualityService? qualityService = _qualityService;
    if (qualityService == null || !qualityService.isMonitoring) {
      return;
    }

    final List<CallQualityMetrics> metrics = qualityService.metricsHistory;
    final Duration callDuration = _callStartTime != null
        ? DateTime.now().difference(_callStartTime!)
        : Duration.zero;

    qualityService.stopMonitoring();

    if (metrics.isNotEmpty && _metricsLogger != null) {
      await _metricsLogger!.logCallSummary(
        callId: _currentCallId ?? 'unknown',
        metrics: metrics,
        callDuration: callDuration,
        callerNumber: callerNumber,
        callDirection: callDirection,
      );
    }

    _currentCallId = null;
    _callStartTime = null;
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

  // ============ Call Control & Decline (Task 21) ============

  /// Updates the current call context so decline/logging have caller metadata.
  ///
  /// This should be called by higher-level call handlers (e.g. [CallProvider])
  /// when an incoming/outgoing call is created.
  void updateCurrentCallContext({
    required String callId,
    required String callerNumber,
    String? callerName,
    String direction = 'incoming',
  }) {
    _currentCallId = callId;
    _currentCallerNumber = callerNumber;
    _currentCallerName = callerName;
    _currentCallDirection = direction;
  }

  /// Declines an incoming call.
  ///
  /// In a real Telnyx integration this would invoke the Telnyx SDK to reject
  /// the SIP INVITE (e.g. 486 Busy Here). In this simulated environment we
  /// update internal call state and trigger cleanup so higher-level logic can
  /// react consistently.
  ///
  /// Returns `true` if decline was handled successfully, `false` otherwise.
  Future<bool> declineCall({String? reason}) async {
    try {
      if (_currentCallId == null) {
        debugPrint('[TelnyxService] No active call to decline');
        return false;
      }

      debugPrint(
        '[TelnyxService] Declining call $_currentCallId '
        'with reason: ${reason ?? "user_declined"}',
      );

      // Update call state to reflect a declined call.
      _callStateSubject.add(TelnyxCallState.declined);

      // Perform cleanup (stop quality monitoring, clear metadata, etc.).
      await _cleanupAfterDecline();

      debugPrint('[TelnyxService] Call declined successfully');
      return true;
    } catch (e, stackTrace) {
      debugPrint('[TelnyxService] Error declining call: $e');
      debugPrint('Stack trace: $stackTrace');

      // Attempt cleanup even if decline simulation fails.
      await _cleanupAfterDecline();

      return false;
    }
  }

  /// Cleans up resources after a call is declined/ended.
  Future<void> _cleanupAfterDecline() async {
    try {
      // Stop quality monitoring and log summary if available.
      await stopQualityMonitoring(
        callerNumber: _currentCallerNumber,
        callDirection: _currentCallDirection,
      );

      // Clear current call metadata.
      _currentCallId = null;
      _currentCallerNumber = null;
      _currentCallerName = null;
      _currentCallDirection = 'incoming';

      // Notify listeners that the call lifecycle has ended.
      _callStateSubject.add(TelnyxCallState.ended);

      debugPrint('[TelnyxService] Cleanup after decline completed');
    } catch (e) {
      debugPrint('[TelnyxService] Error during cleanup after decline: $e');
    }
  }

  /// Gets the current call's caller information for logging.
  ///
  /// Returns a simple map intended for persistence via repositories.
  Map<String, dynamic>? getCurrentCallInfo() {
    if (_currentCallId == null) return null;

    return <String, dynamic>{
      'callId': _currentCallId,
      'callerNumber': _currentCallerNumber ?? 'Unknown',
      'callerName': _currentCallerName ?? 'Unknown',
      'direction': _currentCallDirection,
      'timestamp': DateTime.now().toIso8601String(),
    };
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
  /// Call was explicitly declined by the user.
  declined,
  /// Call lifecycle finished (ended, either locally or remotely).
  ended,
  error,
}
