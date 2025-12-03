library;

import 'dart:async';

import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';

import '../config/retry_config.dart';
import '../models/retry_state.dart';
import 'retry_manager.dart';
import '../../data/services/network_monitor_service.dart';

/// Types of call operations that can be retried.
enum CallOperationType {
  /// Initiating a new outbound call.
  outboundCall,

  /// Reconnecting a dropped call.
  reconnect,

  /// Re-establishing WebRTC connection.
  webrtcReconnect,
}

/// Result of a call retry operation.
class CallRetryResult {
  final bool success;
  final String? callId;
  final Object? error;
  final int attempts;
  final Duration totalDuration;

  const CallRetryResult({
    required this.success,
    this.callId,
    this.error,
    required this.attempts,
    required this.totalDuration,
  });
}

/// Callback for performing a call operation.
///
/// Should return a call ID on success.
typedef CallOperation = Future<String> Function();

/// Service for managing call-related retries.
class CallRetryService {
  final Logger _logger = Logger(
    printer: PrettyPrinter(methodCount: 0),
  );

  final RetryManager _retryManager;
  final NetworkMonitorService _networkMonitor;

  /// Configuration for different call operation types.
  final Map<CallOperationType, RetryConfig> _configs =
      <CallOperationType, RetryConfig>{
    CallOperationType.outboundCall: RetryConfig.callConnection,
    CallOperationType.reconnect: RetryConfig.quickRetry,
    CallOperationType.webrtcReconnect: const RetryConfig(
      maxAttempts: 4,
      initialDelayMs: 500,
      maxDelayMs: 5000,
      backoffMultiplier: 1.5,
      useJitter: true,
      jitterFactor: 0.2,
    ),
  };

  /// Active call retry operations.
  final Map<String, BehaviorSubject<RetryState?>> _activeOperations =
      <String, BehaviorSubject<RetryState?>>{};

  /// Callbacks for UI notifications.
  void Function(String callId, int attempt, Duration nextRetryIn)?
      onRetryStarted;
  void Function(String callId, bool success)? onRetryCompleted;

  CallRetryService({
    required RetryManager retryManager,
    required NetworkMonitorService networkMonitor,
  })  : _retryManager = retryManager,
        _networkMonitor = networkMonitor;

  /// Update configuration for a specific operation type.
  void setConfig(CallOperationType type, RetryConfig config) {
    _configs[type] = config;
    _logger.i('Updated $type config: $config');
  }

  /// Get configuration for an operation type.
  RetryConfig getConfig(CallOperationType type) {
    return _configs[type] ?? RetryConfig.callConnection;
  }

  /// Execute a call with retry logic.
  ///
  /// [operation] - The call operation to perform (should return call ID).
  /// [operationType] - Type of call operation for config lookup.
  /// [phoneNumber] - Target phone number (for logging).
  /// [existingCallId] - Existing call ID (for reconnection scenarios).
  Future<CallRetryResult> executeWithRetry({
    required CallOperation operation,
    required CallOperationType operationType,
    String? phoneNumber,
    String? existingCallId,
  }) async {
    final String operationId =
        existingCallId ?? 'call_${DateTime.now().millisecondsSinceEpoch}';
    final RetryConfig config = getConfig(operationType);

    // Check network.
    if (!_networkMonitor.isConnected) {
      _logger.w('Cannot initiate call: network offline');
      return const CallRetryResult(
        success: false,
        error: 'Network offline',
        attempts: 0,
        totalDuration: Duration.zero,
      );
    }

    // Set up state tracking.
    final BehaviorSubject<RetryState?> stateSubject =
        BehaviorSubject<RetryState?>.seeded(null);
    _activeOperations[operationId] = stateSubject;

    _logger.i('Starting $operationType for ${phoneNumber ?? operationId}');

    // Kick off retry operation first so state stream is available.
    final Future<RetryResult<String>> resultFuture =
        _retryManager.execute<String>(
      operation: operation,
      config: config,
      operationId: operationId,
      isRetryable: (Object error) =>
          _isCallErrorRetryable(error, operationType),
      onRetry: (int attempt, Duration delay, Object? error) {
        _logger.i('Call retry $attempt in ${delay.inMilliseconds}ms');
        onRetryStarted?.call(operationId, attempt, delay);
      },
    );

    // Forward retry state from manager into our per-call subject.
    final Stream<RetryState>? stateStream =
        _retryManager.getStateStream(operationId);
    StreamSubscription<RetryState>? stateSubscription;
    if (stateStream != null) {
      stateSubscription = stateStream.listen(stateSubject.add);
    }

    try {
      final RetryResult<String> result = await resultFuture;

      final CallRetryResult callRetryResult = CallRetryResult(
        success: result.success,
        callId: result.success ? result.data : null,
        error: result.error,
        attempts: result.totalAttempts,
        totalDuration: result.totalDuration,
      );

      onRetryCompleted?.call(operationId, result.success);

      if (result.success) {
        _logger.i(
          'Call succeeded after ${result.totalAttempts} attempt(s)',
        );
      } else {
        _logger.e('Call failed after ${result.totalAttempts} attempts');
      }

      return callRetryResult;
    } finally {
      await stateSubscription?.cancel();
      await stateSubject.close();
      _activeOperations.remove(operationId);
    }
  }

  /// Check if a call error should be retried.
  bool _isCallErrorRetryable(Object error, CallOperationType operationType) {
    final String errorString = error.toString().toLowerCase();

    // Never retry these errors.
    if (errorString.contains('invalid number') ||
        errorString.contains('number not in service') ||
        errorString.contains('call rejected') ||
        errorString.contains('busy')) {
      return false;
    }

    // Don't retry permission errors.
    if (errorString.contains('permission denied') ||
        errorString.contains('not authorized')) {
      return false;
    }

    // For outbound calls, be more conservative.
    if (operationType == CallOperationType.outboundCall) {
      // Don't retry if the call was answered then failed.
      if (errorString.contains('call ended') ||
          errorString.contains('hangup')) {
        return false;
      }
    }

    // For reconnection, retry most errors.
    return true;
  }

  /// Make an outbound call with automatic retry.
  Future<CallRetryResult> makeCall({
    required String phoneNumber,
    required Future<String> Function() callInitiator,
  }) async {
    return executeWithRetry(
      operation: callInitiator,
      operationType: CallOperationType.outboundCall,
      phoneNumber: phoneNumber,
    );
  }

  /// Attempt to reconnect a dropped call.
  Future<CallRetryResult> reconnectCall({
    required String callId,
    required Future<String> Function() reconnector,
  }) async {
    return executeWithRetry(
      operation: reconnector,
      operationType: CallOperationType.reconnect,
      existingCallId: callId,
    );
  }

  /// Reconnect WebRTC for an existing call.
  Future<CallRetryResult> reconnectWebRTC({
    required String callId,
    required Future<String> Function() webrtcReconnector,
  }) async {
    return executeWithRetry(
      operation: webrtcReconnector,
      operationType: CallOperationType.webrtcReconnect,
      existingCallId: callId,
    );
  }

  /// Cancel an ongoing call retry.
  void cancelRetry(String operationId) {
    _retryManager.cancel(operationId);
    _logger.i('Cancelled call retry for $operationId');
  }

  /// Get the current state of a call retry operation.
  Stream<RetryState?>? getRetryStateStream(String operationId) {
    return _activeOperations[operationId]?.stream;
  }

  /// Check if a call operation is being retried.
  bool isRetrying(String operationId) {
    return _retryManager.isRetrying(operationId);
  }

  /// Dispose resources.
  Future<void> dispose() async {
    for (final BehaviorSubject<RetryState?> subject
        in _activeOperations.values) {
      await subject.close();
    }
    _activeOperations.clear();
  }
}
