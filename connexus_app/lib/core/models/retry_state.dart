library;

import 'package:flutter/foundation.dart';

/// Represents the current state of a retry operation.
enum RetryStatus {
  /// No retry in progress.
  idle,

  /// Waiting before next retry attempt.
  waiting,

  /// Currently attempting operation.
  attempting,

  /// Operation succeeded.
  succeeded,

  /// All retries exhausted, operation failed.
  failed,

  /// Retry was cancelled.
  cancelled,
}

/// Tracks the state of an ongoing retry operation.
@immutable
class RetryState {
  /// Current status of the retry operation.
  final RetryStatus status;

  /// Current attempt number (1-based).
  final int currentAttempt;

  /// Maximum attempts configured.
  final int maxAttempts;

  /// Time until next retry (null if not waiting).
  final Duration? nextRetryIn;

  /// Last error that occurred (null if no error yet).
  final Object? lastError;

  /// Timestamp when retry operation started.
  final DateTime? startedAt;

  /// Identifier for the operation being retried.
  final String operationId;

  const RetryState({
    required this.status,
    required this.currentAttempt,
    required this.maxAttempts,
    required this.operationId,
    this.nextRetryIn,
    this.lastError,
    this.startedAt,
  });

  /// Initial state for a new retry operation.
  factory RetryState.initial(String operationId, int maxAttempts) {
    return RetryState(
      status: RetryStatus.idle,
      currentAttempt: 0,
      maxAttempts: maxAttempts,
      operationId: operationId,
      startedAt: DateTime.now(),
    );
  }

  /// Whether the operation is still in progress.
  bool get isInProgress =>
      status == RetryStatus.waiting || status == RetryStatus.attempting;

  /// Whether there are remaining retry attempts.
  bool get hasRemainingAttempts => currentAttempt < maxAttempts;

  /// Progress as a percentage (0.0 to 1.0).
  double get progress => maxAttempts > 0 ? currentAttempt / maxAttempts : 0.0;

  /// Create a copy with updated values.
  RetryState copyWith({
    RetryStatus? status,
    int? currentAttempt,
    int? maxAttempts,
    Duration? nextRetryIn,
    Object? lastError,
    DateTime? startedAt,
    String? operationId,
  }) {
    return RetryState(
      status: status ?? this.status,
      currentAttempt: currentAttempt ?? this.currentAttempt,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      nextRetryIn: nextRetryIn ?? this.nextRetryIn,
      lastError: lastError ?? this.lastError,
      startedAt: startedAt ?? this.startedAt,
      operationId: operationId ?? this.operationId,
    );
  }

  @override
  String toString() {
    return 'RetryState(status: $status, attempt: $currentAttempt/$maxAttempts, '
        'operation: $operationId)';
  }
}

/// Result of a retry operation.
@immutable
class RetryResult<T> {
  /// Whether the operation ultimately succeeded.
  final bool success;

  /// The successful result (null if failed).
  final T? data;

  /// The final error if failed (null if succeeded).
  final Object? error;

  /// Total number of attempts made.
  final int totalAttempts;

  /// Total time spent retrying.
  final Duration totalDuration;

  /// List of errors from each failed attempt.
  final List<Object> attemptErrors;

  const RetryResult({
    required this.success,
    this.data,
    this.error,
    required this.totalAttempts,
    required this.totalDuration,
    this.attemptErrors = const [],
  });

  /// Create a successful result.
  factory RetryResult.succeeded(
    T data,
    int attempts,
    Duration duration,
  ) {
    return RetryResult(
      success: true,
      data: data,
      totalAttempts: attempts,
      totalDuration: duration,
    );
  }

  /// Create a failed result.
  factory RetryResult.failed(
    Object error,
    int attempts,
    Duration duration,
    List<Object> attemptErrors,
  ) {
    return RetryResult(
      success: false,
      error: error,
      totalAttempts: attempts,
      totalDuration: duration,
      attemptErrors: attemptErrors,
    );
  }

  @override
  String toString() {
    return 'RetryResult(success: $success, attempts: $totalAttempts, '
        'duration: ${totalDuration.inMilliseconds}ms)';
  }
}
