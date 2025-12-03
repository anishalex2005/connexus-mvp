library;

import 'dart:async';
import 'dart:math';

import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';

import '../config/retry_config.dart';
import '../models/retry_state.dart';

/// Callback type for the operation to retry.
typedef RetryOperation<T> = Future<T> Function();

/// Callback type for determining if an error is retryable.
typedef RetryableErrorChecker = bool Function(Object error);

/// Callback type for notifications before retry.
typedef OnRetryCallback = void Function(
  int attempt,
  Duration delay,
  Object? lastError,
);

/// Manages retry logic with exponential backoff.
class RetryManager {
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
    ),
  );

  /// Random number generator for jitter.
  final Random _random = Random();

  /// Stream controllers for active retry operations.
  final Map<String, BehaviorSubject<RetryState>> _retryStates = {};

  /// Cancellation tokens for active operations.
  final Map<String, Completer<void>> _cancellationTokens = {};

  /// Default checker that treats all errors as retryable.
  static bool defaultRetryableChecker(Object error) => true;

  /// Common non-retryable error checker.
  static bool commonRetryableChecker(Object error) {
    final String errorString = error.toString().toLowerCase();

    // Don't retry authentication errors.
    if (errorString.contains('unauthorized') ||
        errorString.contains('forbidden') ||
        errorString.contains('invalid credentials') ||
        errorString.contains('authentication failed')) {
      return false;
    }

    // Don't retry client errors (4xx) except timeout-related.
    if (errorString.contains('bad request') ||
        errorString.contains('not found')) {
      return false;
    }

    return true;
  }

  /// Execute an operation with retry logic.
  ///
  /// [operation] - The async operation to execute.
  /// [config] - Retry configuration.
  /// [operationId] - Unique identifier for tracking.
  /// [isRetryable] - Function to check if error should trigger retry.
  /// [onRetry] - Callback before each retry attempt.
  Future<RetryResult<T>> execute<T>({
    required RetryOperation<T> operation,
    required RetryConfig config,
    required String operationId,
    RetryableErrorChecker? isRetryable,
    OnRetryCallback? onRetry,
  }) async {
    final DateTime startTime = DateTime.now();
    final List<Object> errors = <Object>[];
    final RetryableErrorChecker retryableChecker =
        isRetryable ?? commonRetryableChecker;

    // Initialize state tracking.
    final BehaviorSubject<RetryState> stateSubject =
        BehaviorSubject<RetryState>.seeded(
      RetryState.initial(operationId, config.maxAttempts),
    );
    _retryStates[operationId] = stateSubject;

    // Create cancellation token.
    final Completer<void> cancellationToken = Completer<void>();
    _cancellationTokens[operationId] = cancellationToken;

    try {
      for (int attempt = 1; attempt <= config.maxAttempts; attempt++) {
        // Check for cancellation.
        if (cancellationToken.isCompleted) {
          _updateState(
            operationId,
            (RetryState state) => state.copyWith(
              status: RetryStatus.cancelled,
            ),
          );

          return RetryResult.failed(
            'Operation cancelled',
            attempt - 1,
            DateTime.now().difference(startTime),
            errors,
          );
        }

        // Update state to attempting.
        _updateState(
          operationId,
          (RetryState state) => state.copyWith(
            status: RetryStatus.attempting,
            currentAttempt: attempt,
          ),
        );

        _logger.i('[$operationId] Attempt $attempt/${config.maxAttempts}');

        try {
          // Execute the operation.
          final T result = await operation();

          // Success!
          _updateState(
            operationId,
            (RetryState state) => state.copyWith(status: RetryStatus.succeeded),
          );

          _logger.i('[$operationId] Succeeded on attempt $attempt');

          return RetryResult.succeeded(
            result,
            attempt,
            DateTime.now().difference(startTime),
          );
        } catch (error, stackTrace) {
          errors.add(error);
          _logger.w('[$operationId] Attempt $attempt failed: $error');
          _logger.d(stackTrace.toString());

          // Update state with error.
          _updateState(
            operationId,
            (RetryState state) => state.copyWith(
              lastError: error,
            ),
          );

          // Check if we should retry.
          if (!retryableChecker(error)) {
            _logger.e('[$operationId] Error is not retryable');
            _updateState(
              operationId,
              (RetryState state) => state.copyWith(status: RetryStatus.failed),
            );

            return RetryResult.failed(
              error,
              attempt,
              DateTime.now().difference(startTime),
              errors,
            );
          }

          // Check if we have more attempts.
          if (attempt >= config.maxAttempts) {
            _logger.e(
              '[$operationId] All ${config.maxAttempts} attempts exhausted',
            );
            _updateState(
              operationId,
              (RetryState state) => state.copyWith(status: RetryStatus.failed),
            );

            return RetryResult.failed(
              error,
              attempt,
              DateTime.now().difference(startTime),
              errors,
            );
          }

          // Calculate delay for next attempt.
          final Duration delay = _calculateDelay(attempt, config);

          _logger.i(
            '[$operationId] Waiting ${delay.inMilliseconds}ms before retry',
          );

          // Update state to waiting.
          _updateState(
            operationId,
            (RetryState state) => state.copyWith(
              status: RetryStatus.waiting,
              nextRetryIn: delay,
            ),
          );

          // Notify before retry.
          onRetry?.call(attempt, delay, error);

          // Wait with cancellation support.
          try {
            await Future.any<void>(<Future<void>>[
              Future<void>.delayed(delay),
              cancellationToken.future,
            ]);
          } catch (_) {
            // Cancellation occurred.
          }
        }
      }

      // Should not reach here, but handle it.
      return RetryResult.failed(
        'Unknown error',
        config.maxAttempts,
        DateTime.now().difference(startTime),
        errors,
      );
    } finally {
      // Cleanup.
      await _cleanup(operationId);
    }
  }

  /// Calculate delay using exponential backoff with optional jitter.
  Duration _calculateDelay(int attempt, RetryConfig config) {
    // Exponential backoff: initialDelay * (multiplier ^ (attempt - 1)).
    final double exponentialDelay = config.initialDelayMs *
        pow(config.backoffMultiplier, attempt - 1).toDouble();

    // Cap at maximum delay.
    double delayMs = min(exponentialDelay, config.maxDelayMs.toDouble());

    // Add jitter if enabled.
    if (config.useJitter) {
      final double jitterRange = delayMs * config.jitterFactor;
      final double jitter = (_random.nextDouble() * 2 - 1) * jitterRange;
      delayMs = max(0, delayMs + jitter);
    }

    return Duration(milliseconds: delayMs.round());
  }

  /// Update state for an operation.
  void _updateState(
    String operationId,
    RetryState Function(RetryState) updater,
  ) {
    final BehaviorSubject<RetryState>? subject = _retryStates[operationId];
    if (subject != null && !subject.isClosed) {
      subject.add(updater(subject.value));
    }
  }

  /// Get the current state of a retry operation.
  RetryState? getState(String operationId) {
    return _retryStates[operationId]?.valueOrNull;
  }

  /// Stream of state updates for an operation.
  Stream<RetryState>? getStateStream(String operationId) {
    return _retryStates[operationId]?.stream;
  }

  /// Cancel an ongoing retry operation.
  void cancel(String operationId) {
    final Completer<void>? token = _cancellationTokens[operationId];
    if (token != null && !token.isCompleted) {
      token.complete();
      _logger.i('[$operationId] Cancelled');
    }
  }

  /// Cancel all ongoing retry operations.
  void cancelAll() {
    for (final MapEntry<String, Completer<void>> entry
        in _cancellationTokens.entries) {
      if (!entry.value.isCompleted) {
        entry.value.complete();
        _logger.i('[${entry.key}] Cancelled');
      }
    }
  }

  /// Check if an operation is currently being retried.
  bool isRetrying(String operationId) {
    final RetryState? state = getState(operationId);
    return state?.isInProgress ?? false;
  }

  /// Cleanup resources for an operation.
  Future<void> _cleanup(String operationId) async {
    final BehaviorSubject<RetryState>? subject = _retryStates.remove(
      operationId,
    );
    await subject?.close();
    _cancellationTokens.remove(operationId);
  }

  /// Dispose all resources.
  Future<void> dispose() async {
    cancelAll();
    for (final BehaviorSubject<RetryState> subject in _retryStates.values) {
      await subject.close();
    }
    _retryStates.clear();
    _cancellationTokens.clear();
  }
}
