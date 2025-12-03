import 'package:connexus_app/core/config/retry_config.dart';
import 'package:connexus_app/core/models/retry_state.dart';
import 'package:connexus_app/core/services/retry_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late RetryManager retryManager;

  setUp(() {
    retryManager = RetryManager();
  });

  tearDown(() async {
    await retryManager.dispose();
  });

  group('RetryConfig', () {
    test('should have valid default configurations', () {
      expect(RetryConfig.sipRegistration.maxAttempts, equals(5));
      expect(RetryConfig.callConnection.maxAttempts, equals(3));
      expect(RetryConfig.quickRetry.initialDelayMs, equals(500));
    });

    test('should create copy with modified values', () {
      const RetryConfig original = RetryConfig.sipRegistration;
      final RetryConfig modified = original.copyWith(maxAttempts: 10);

      expect(modified.maxAttempts, equals(10));
      expect(modified.initialDelayMs, equals(original.initialDelayMs));
    });
  });

  group('RetryState', () {
    test('should create initial state correctly', () {
      final RetryState state = RetryState.initial('test_op', 5);

      expect(state.status, equals(RetryStatus.idle));
      expect(state.currentAttempt, equals(0));
      expect(state.maxAttempts, equals(5));
      expect(state.hasRemainingAttempts, isTrue);
    });

    test('should calculate progress correctly', () {
      const RetryState state = RetryState(
        status: RetryStatus.attempting,
        currentAttempt: 2,
        maxAttempts: 4,
        operationId: 'test',
      );

      expect(state.progress, equals(0.5));
    });
  });

  group('RetryManager', () {
    test('should succeed on first attempt', () async {
      int callCount = 0;

      final RetryResult<String> result = await retryManager.execute<String>(
        operation: () async {
          callCount++;
          return 'success';
        },
        config: const RetryConfig(maxAttempts: 3, initialDelayMs: 100),
        operationId: 'test_success',
      );

      expect(result.success, isTrue);
      expect(result.data, equals('success'));
      expect(result.totalAttempts, equals(1));
      expect(callCount, equals(1));
    });

    test('should retry on failure and eventually succeed', () async {
      int callCount = 0;

      final RetryResult<String> result = await retryManager.execute<String>(
        operation: () async {
          callCount++;
          if (callCount < 3) {
            throw Exception('Temporary failure');
          }
          return 'success';
        },
        config: const RetryConfig(
          maxAttempts: 5,
          initialDelayMs: 50,
          backoffMultiplier: 1.0,
        ),
        operationId: 'test_retry_success',
      );

      expect(result.success, isTrue);
      expect(result.totalAttempts, equals(3));
      expect(callCount, equals(3));
    });

    test('should fail after max attempts', () async {
      int callCount = 0;

      final RetryResult<String> result = await retryManager.execute<String>(
        operation: () async {
          callCount++;
          throw Exception('Persistent failure');
        },
        config: const RetryConfig(
          maxAttempts: 3,
          initialDelayMs: 50,
          backoffMultiplier: 1.0,
        ),
        operationId: 'test_retry_fail',
      );

      expect(result.success, isFalse);
      expect(result.totalAttempts, equals(3));
      expect(result.attemptErrors.length, equals(3));
      expect(callCount, equals(3));
    });

    test('should not retry non-retryable errors', () async {
      int callCount = 0;

      final RetryResult<String> result = await retryManager.execute<String>(
        operation: () async {
          callCount++;
          throw Exception('Invalid credentials');
        },
        config: const RetryConfig(maxAttempts: 5, initialDelayMs: 50),
        operationId: 'test_non_retryable',
        isRetryable: RetryManager.commonRetryableChecker,
      );

      expect(result.success, isFalse);
      expect(result.totalAttempts, equals(1));
      expect(callCount, equals(1));
    });

    test('should cancel ongoing retry', () async {
      const String operationId = 'test_cancel';
      bool completed = false;

      // Start a slow retry operation.
      final Future<RetryResult<String>> future = retryManager
          .execute<String>(
        operation: () async {
          throw Exception('Keep failing');
        },
        config: const RetryConfig(
          maxAttempts: 10,
          initialDelayMs: 1000,
        ),
        operationId: operationId,
      )
          .then((RetryResult<String> result) {
        completed = true;
        return result;
      });

      // Wait a bit then cancel.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      retryManager.cancel(operationId);

      final RetryResult<String> result = await future;
      expect(result.success, isFalse);
      expect(completed, isTrue);
    });

    test('should call onRetry callback', () async {
      final List<int> retryAttempts = <int>[];

      await retryManager.execute<String>(
        operation: () async {
          if (retryAttempts.length < 2) {
            throw Exception('Fail');
          }
          return 'success';
        },
        config: const RetryConfig(
          maxAttempts: 5,
          initialDelayMs: 50,
          backoffMultiplier: 1.0,
        ),
        operationId: 'test_callback',
        onRetry: (int attempt, Duration delay, Object? error) {
          retryAttempts.add(attempt);
        },
      );

      expect(retryAttempts, equals(<int>[1, 2]));
    });
  });

  group('RetryResult', () {
    test('should create succeeded result', () {
      final RetryResult<String> result = RetryResult.succeeded(
        'data',
        2,
        const Duration(seconds: 5),
      );

      expect(result.success, isTrue);
      expect(result.data, equals('data'));
      expect(result.totalAttempts, equals(2));
    });

    test('should create failed result', () {
      final List<Object> errors = <Object>[Exception('1'), Exception('2')];
      final RetryResult<void> result = RetryResult.failed(
        Exception('final'),
        2,
        const Duration(seconds: 5),
        errors,
      );

      expect(result.success, isFalse);
      expect(result.error, isNotNull);
      expect(result.attemptErrors.length, equals(2));
    });
  });
}
