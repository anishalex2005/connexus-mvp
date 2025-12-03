library;

import 'dart:async';

import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';

import '../config/retry_config.dart';
import '../models/retry_state.dart';
import 'retry_manager.dart';
import '../../data/services/network_monitor_service.dart';
import '../../domain/models/network_state.dart';

/// Status of the registration.
enum RegistrationStatus {
  unregistered,
  registering,
  registered,
  failed,
  retrying,
}

/// Events that can trigger registration changes.
enum RegistrationEvent {
  register,
  unregister,
  networkLost,
  networkRestored,
  forceReconnect,
}

/// Service for managing SIP registration with automatic retry.
class RegistrationRetryService {
  final Logger _logger = Logger(
    printer: PrettyPrinter(methodCount: 0),
  );

  final RetryManager _retryManager;
  final NetworkMonitorService _networkMonitor;

  /// Configuration for registration retries.
  RetryConfig _config = RetryConfig.sipRegistration;

  /// Stream controller for registration status.
  final BehaviorSubject<RegistrationStatus> _statusController =
      BehaviorSubject<RegistrationStatus>.seeded(
    RegistrationStatus.unregistered,
  );

  /// Stream controller for retry state.
  final BehaviorSubject<RetryState?> _retryStateController =
      BehaviorSubject<RetryState?>.seeded(null);

  /// Current registration credentials.
  String? _sipUsername;
  String? _sipPassword;
  String? _sipDomain;

  /// Subscription to network changes.
  StreamSubscription<NetworkChangeEvent>? _networkSubscription;

  /// Flag to track if we should auto-reconnect.
  bool _shouldAutoReconnect = true;

  /// Operation ID for tracking.
  static const String _operationId = 'sip_registration';

  RegistrationRetryService({
    required RetryManager retryManager,
    required NetworkMonitorService networkMonitor,
  })  : _retryManager = retryManager,
        _networkMonitor = networkMonitor {
    _setupNetworkListener();
  }

  /// Stream of registration status changes.
  Stream<RegistrationStatus> get statusStream => _statusController.stream;

  /// Current registration status.
  RegistrationStatus get currentStatus => _statusController.value;

  /// Stream of retry state changes.
  Stream<RetryState?> get retryStateStream => _retryStateController.stream;

  /// Current retry state.
  RetryState? get currentRetryState => _retryStateController.value;

  /// Whether currently registered.
  bool get isRegistered => currentStatus == RegistrationStatus.registered;

  /// Update retry configuration.
  void setConfig(RetryConfig config) {
    _config = config;
    _logger.i('Registration retry config updated: $config');
  }

  /// Set up listener for network changes.
  void _setupNetworkListener() {
    _networkSubscription =
        _networkMonitor.networkChangeStream.listen(_handleNetworkChange);
  }

  /// Handle network status changes.
  void _handleNetworkChange(NetworkChangeEvent event) {
    switch (event.changeType) {
      case NetworkChangeType.reconnected:
        _logger.i('Network restored, checking registration status');
        if (_shouldAutoReconnect &&
            currentStatus != RegistrationStatus.registered &&
            currentStatus != RegistrationStatus.registering) {
          _logger.i('Auto-reconnecting after network restore');
          // ignore: discarded_futures
          handleEvent(RegistrationEvent.networkRestored);
        }
        break;

      case NetworkChangeType.disconnected:
        _logger.w('Network lost, pausing registration attempts');
        // ignore: discarded_futures
        handleEvent(RegistrationEvent.networkLost);
        break;

      case NetworkChangeType.typeChanged:
      case NetworkChangeType.qualityChanged:
      case NetworkChangeType.initial:
        // No-op for now; registration is primarily tied to up/down.
        break;
    }
  }

  /// Handle registration events.
  Future<void> handleEvent(RegistrationEvent event) async {
    _logger.i('Handling registration event: $event');

    switch (event) {
      case RegistrationEvent.register:
        await _startRegistration();
        break;
      case RegistrationEvent.unregister:
        await _unregister();
        break;
      case RegistrationEvent.networkLost:
        _handleNetworkLost();
        break;
      case RegistrationEvent.networkRestored:
        await _handleNetworkRestored();
        break;
      case RegistrationEvent.forceReconnect:
        await _forceReconnect();
        break;
    }
  }

  /// Start registration with credentials.
  Future<bool> register({
    required String username,
    required String password,
    required String domain,
    bool autoReconnect = true,
  }) async {
    _sipUsername = username;
    _sipPassword = password;
    _sipDomain = domain;
    _shouldAutoReconnect = autoReconnect;

    return _startRegistration();
  }

  /// Internal method to start registration with retry.
  Future<bool> _startRegistration() async {
    if (_sipUsername == null || _sipPassword == null) {
      _logger.e('Cannot register: credentials not set');
      return false;
    }

    // Check network first.
    if (!_networkMonitor.isConnected) {
      _logger.w('Cannot register: network offline');
      _statusController.add(RegistrationStatus.failed);
      return false;
    }

    _statusController.add(RegistrationStatus.registering);

    // Kick off retry operation first so state stream is available.
    final Future<RetryResult<bool>> resultFuture = _retryManager.execute<bool>(
      operation: () => _performRegistration(),
      config: _config,
      operationId: _operationId,
      isRetryable: _isRegistrationErrorRetryable,
      onRetry: (int attempt, Duration delay, Object? error) {
        _statusController.add(RegistrationStatus.retrying);
        _logger.i('Registration retry $attempt in ${delay.inSeconds}s');
      },
    );

    // Mirror retry state into local controller if available.
    final Stream<RetryState>? stateStream =
        _retryManager.getStateStream(_operationId);
    StreamSubscription<RetryState>? stateSubscription;
    if (stateStream != null) {
      stateSubscription = stateStream.listen(_retryStateController.add);
    }

    final RetryResult<bool> result = await resultFuture;
    await stateSubscription?.cancel();

    if (result.success) {
      _statusController.add(RegistrationStatus.registered);
      _logger.i(
        'Registration successful after ${result.totalAttempts} attempt(s)',
      );
      return true;
    } else {
      _statusController.add(RegistrationStatus.failed);
      _logger.e(
        'Registration failed after ${result.totalAttempts} attempts: '
        '${result.error}',
      );
      return false;
    }
  }

  /// Perform the actual registration.
  ///
  /// This should be replaced with actual Telnyx registration call.
  Future<bool> _performRegistration() async {
    _logger.d(
      'Attempting SIP registration for $_sipUsername@$_sipDomain',
    );

    // TODO(Task 17 follow-up): Replace with actual Telnyx service call.
    // Example (after wiring TelnyxService into DI):
    //
    // final telnyxService = getIt<TelnyxService>();
    // await telnyxService.connect(
    //   TelnyxCredentials(
    //     sipUsername: _sipUsername!,
    //     sipPassword: _sipPassword!,
    //     callerIdNumber: AppConfig.telnyxCallerIdNumber,
    //     callerIdName: AppConfig.telnyxCallerIdName,
    //   ),
    // );

    // Simulated registration for testing.
    await Future<void>.delayed(const Duration(milliseconds: 500));

    // Simulate occasional failures for testing retry logic.
    // Remove this in production and use actual Telnyx registration.
    if (DateTime.now().millisecond % 3 == 0) {
      throw Exception('Simulated registration failure');
    }

    return true;
  }

  /// Check if a registration error should be retried.
  bool _isRegistrationErrorRetryable(Object error) {
    final String errorString = error.toString().toLowerCase();

    // Don't retry credential errors.
    if (errorString.contains('invalid credentials') ||
        errorString.contains('unauthorized') ||
        errorString.contains('forbidden') ||
        errorString.contains('wrong password')) {
      _logger.w('Registration error is not retryable (auth error)');
      return false;
    }

    // Don't retry if account issues.
    if (errorString.contains('account suspended') ||
        errorString.contains('account disabled')) {
      _logger.w('Registration error is not retryable (account issue)');
      return false;
    }

    // Retry network and server errors.
    return true;
  }

  /// Unregister from the SIP service.
  Future<void> _unregister() async {
    _retryManager.cancel(_operationId);

    // TODO(Task 17 follow-up): Call actual Telnyx disconnect.
    //
    // final telnyxService = getIt<TelnyxService>();
    // await telnyxService.disconnect();

    _statusController.add(RegistrationStatus.unregistered);
    _logger.i('Unregistered from SIP service');
  }

  /// Handle network loss.
  void _handleNetworkLost() {
    // Cancel ongoing retries - they'll fail anyway.
    _retryManager.cancel(_operationId);

    // Don't change status to failed - we'll reconnect when network returns.
    _logger.i('Registration paused due to network loss');
  }

  /// Handle network restoration.
  Future<void> _handleNetworkRestored() async {
    if (_sipUsername != null && _shouldAutoReconnect) {
      // Small delay to let network stabilize.
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await _startRegistration();
    }
  }

  /// Force a reconnection attempt.
  Future<void> _forceReconnect() async {
    _retryManager.cancel(_operationId);
    await _startRegistration();
  }

  /// Dispose resources.
  Future<void> dispose() async {
    await _networkSubscription?.cancel();
    await _statusController.close();
    await _retryStateController.close();
  }
}
