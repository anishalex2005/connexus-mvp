library;

import 'package:flutter/foundation.dart';

/// Configuration for retry behavior.
@immutable
class RetryConfig {
  /// Maximum number of retry attempts before giving up.
  final int maxAttempts;

  /// Initial delay before first retry (in milliseconds).
  final int initialDelayMs;

  /// Maximum delay between retries (in milliseconds).
  final int maxDelayMs;

  /// Multiplier for exponential backoff (e.g., 2.0 doubles delay each time).
  final double backoffMultiplier;

  /// Whether to add random jitter to prevent thundering herd.
  final bool useJitter;

  /// Jitter factor (0.0 to 1.0) - percentage of delay to randomize.
  final double jitterFactor;

  const RetryConfig({
    this.maxAttempts = 5,
    this.initialDelayMs = 1000,
    this.maxDelayMs = 30000,
    this.backoffMultiplier = 2.0,
    this.useJitter = true,
    this.jitterFactor = 0.2,
  })  : assert(maxAttempts > 0, 'maxAttempts must be positive'),
        assert(initialDelayMs > 0, 'initialDelayMs must be positive'),
        assert(
          maxDelayMs >= initialDelayMs,
          'maxDelayMs must be >= initialDelayMs',
        ),
        assert(
          backoffMultiplier >= 1.0,
          'backoffMultiplier must be >= 1.0',
        ),
        assert(
          jitterFactor >= 0.0 && jitterFactor <= 1.0,
          'jitterFactor must be 0.0-1.0',
        );

  /// Default configuration for SIP registration retries.
  static const RetryConfig sipRegistration = RetryConfig(
    maxAttempts: 5,
    initialDelayMs: 2000,
    maxDelayMs: 60000,
    backoffMultiplier: 2.0,
    useJitter: true,
    jitterFactor: 0.25,
  );

  /// Default configuration for call connection retries.
  static const RetryConfig callConnection = RetryConfig(
    maxAttempts: 3,
    initialDelayMs: 1000,
    maxDelayMs: 10000,
    backoffMultiplier: 1.5,
    useJitter: true,
    jitterFactor: 0.15,
  );

  /// Configuration for quick retries (network blips).
  static const RetryConfig quickRetry = RetryConfig(
    maxAttempts: 3,
    initialDelayMs: 500,
    maxDelayMs: 3000,
    backoffMultiplier: 1.5,
    useJitter: false,
    jitterFactor: 0.0,
  );

  /// Create a copy with modified values.
  RetryConfig copyWith({
    int? maxAttempts,
    int? initialDelayMs,
    int? maxDelayMs,
    double? backoffMultiplier,
    bool? useJitter,
    double? jitterFactor,
  }) {
    return RetryConfig(
      maxAttempts: maxAttempts ?? this.maxAttempts,
      initialDelayMs: initialDelayMs ?? this.initialDelayMs,
      maxDelayMs: maxDelayMs ?? this.maxDelayMs,
      backoffMultiplier: backoffMultiplier ?? this.backoffMultiplier,
      useJitter: useJitter ?? this.useJitter,
      jitterFactor: jitterFactor ?? this.jitterFactor,
    );
  }

  @override
  String toString() {
    return 'RetryConfig(maxAttempts: $maxAttempts, initialDelayMs: $initialDelayMs, '
        'maxDelayMs: $maxDelayMs, backoffMultiplier: $backoffMultiplier, '
        'useJitter: $useJitter, jitterFactor: $jitterFactor)';
  }
}
