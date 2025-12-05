import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/network/api_client.dart';
import 'core/services/audio_service.dart';
import 'core/services/call_retry_service.dart';
import 'core/services/registration_retry_service.dart';
import 'core/services/retry_manager.dart';
import 'data/repositories/telephony_repository.dart';
import 'data/services/call_network_handler.dart';
import 'data/services/call_quality_service.dart';
import 'data/services/ice_server_provider.dart';
import 'data/services/media_handler.dart';
import 'data/services/network_monitor_service.dart';
import 'data/services/quality_metrics_logger.dart';
import 'data/services/secure_storage_service.dart';
import 'data/services/telnyx_service.dart';
import 'data/services/webrtc_connection_manager.dart';

final GetIt getIt = GetIt.instance;

/// Initializes all dependencies.
Future<void> configureDependencies() async {
  // External dependencies.
  final sharedPreferences = await SharedPreferences.getInstance();
  if (!getIt.isRegistered<SharedPreferences>()) {
    getIt.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  }

  // Shared structured logger for services that need detailed logging.
  if (!getIt.isRegistered<Logger>()) {
    getIt.registerLazySingleton<Logger>(
      () => Logger(
        printer: PrettyPrinter(
          methodCount: 1,
          errorMethodCount: 5,
          lineLength: 100,
          colors: true,
          printEmojis: true,
        ),
      ),
    );
  }

  // Dio configuration (low-level HTTP client, if needed directly).
  if (!getIt.isRegistered<Dio>()) {
    getIt.registerLazySingleton<Dio>(() {
      final dio = Dio();
      dio.options = BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: const <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      // Add interceptors for logging in debug mode.
      dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
        ),
      );

      return dio;
    });
  }

  // Core services.
  if (!getIt.isRegistered<SecureStorageService>()) {
    getIt.registerLazySingleton<SecureStorageService>(
      () => SecureStorageService(),
    );
  }

  if (!getIt.isRegistered<AudioService>()) {
    getIt.registerLazySingleton<AudioService>(
      AudioService.new,
    );
  }

  if (!getIt.isRegistered<ApiClient>()) {
    getIt.registerLazySingleton<ApiClient>(
      ApiClient.new,
    );
  }

  // WebRTC / media services.
  if (!getIt.isRegistered<IceServerProvider>()) {
    getIt.registerLazySingleton<IceServerProvider>(
      IceServerProvider.new,
    );
  }

  if (!getIt.isRegistered<MediaHandler>()) {
    getIt.registerLazySingleton<MediaHandler>(MediaHandler.new);
  }

  if (!getIt.isRegistered<WebRTCConnectionManager>()) {
    getIt.registerLazySingleton<WebRTCConnectionManager>(
      WebRTCConnectionManager.new,
    );
  }

  // Repositories.
  if (!getIt.isRegistered<TelephonyRepository>()) {
    getIt.registerLazySingleton<TelephonyRepository>(
      () => TelephonyRepository(
        apiClient: getIt<ApiClient>(),
      ),
    );
  }

  // Call quality monitoring & logging.
  if (!getIt.isRegistered<CallQualityService>()) {
    getIt.registerLazySingleton<CallQualityService>(
      () => CallQualityService(
        logger: getIt<Logger>(),
      ),
    );
  }

  if (!getIt.isRegistered<QualityMetricsLogger>()) {
    getIt.registerLazySingleton<QualityMetricsLogger>(
      () => QualityMetricsLogger(
        config: const MetricsLoggerConfig(
          enableLocalLogging: true,
          enableRemoteLogging: false, // Enable when backend endpoint is ready.
          localRetentionDays: 7,
          detailedLoggingThreshold: 60,
        ),
        logger: getIt<Logger>(),
      ),
    );
  }

  // Services.
  if (!getIt.isRegistered<TelnyxService>()) {
    getIt.registerLazySingleton<TelnyxService>(
      () => TelnyxService(
        secureStorage: getIt<SecureStorageService>(),
        retryConfig: const TelnyxRetryConfig(
          maxAttempts: 5,
          initialDelay: Duration(seconds: 2),
          maxDelay: Duration(seconds: 30),
          backoffMultiplier: 2.0,
        ),
        connectionManager: getIt<WebRTCConnectionManager>(),
        mediaHandler: getIt<MediaHandler>(),
        qualityService: getIt<CallQualityService>(),
        qualityMetricsLogger: getIt<QualityMetricsLogger>(),
      ),
    );
  }

  if (!getIt.isRegistered<NetworkMonitorService>()) {
    getIt.registerLazySingleton<NetworkMonitorService>(
      () => NetworkMonitorService(),
    );
  }

  if (!getIt.isRegistered<CallNetworkHandler>()) {
    getIt.registerLazySingleton<CallNetworkHandler>(
      () => CallNetworkHandler(
        networkMonitor: getIt<NetworkMonitorService>(),
        telnyxService: getIt<TelnyxService>(),
      ),
    );
  }

  // Retry manager and services (Task 17).
  if (!getIt.isRegistered<RetryManager>()) {
    getIt.registerLazySingleton<RetryManager>(RetryManager.new);
  }

  if (!getIt.isRegistered<RegistrationRetryService>()) {
    getIt.registerLazySingleton<RegistrationRetryService>(
      () => RegistrationRetryService(
        retryManager: getIt<RetryManager>(),
        networkMonitor: getIt<NetworkMonitorService>(),
      ),
    );
  }

  if (!getIt.isRegistered<CallRetryService>()) {
    getIt.registerLazySingleton<CallRetryService>(
      () => CallRetryService(
        retryManager: getIt<RetryManager>(),
        networkMonitor: getIt<NetworkMonitorService>(),
      ),
    );
  }
}

/// Disposes of services that need cleanup.
Future<void> disposeDependencies() async {
  if (getIt.isRegistered<TelnyxService>()) {
    getIt<TelnyxService>().dispose();
  }
  if (getIt.isRegistered<AudioService>()) {
    await getIt<AudioService>().dispose();
  }
  if (getIt.isRegistered<CallQualityService>()) {
    getIt<CallQualityService>().dispose();
  }
  if (getIt.isRegistered<CallNetworkHandler>()) {
    await getIt<CallNetworkHandler>().dispose();
  }
  if (getIt.isRegistered<NetworkMonitorService>()) {
    await getIt<NetworkMonitorService>().dispose();
  }
  if (getIt.isRegistered<CallRetryService>()) {
    await getIt<CallRetryService>().dispose();
  }
  if (getIt.isRegistered<RegistrationRetryService>()) {
    await getIt<RegistrationRetryService>().dispose();
  }
  if (getIt.isRegistered<RetryManager>()) {
    await getIt<RetryManager>().dispose();
  }
}

/// Initialize services that need to start immediately on app launch.
Future<void> initializeServices() async {
  // Start network monitoring.
  await getIt<NetworkMonitorService>().startMonitoring();

  // Initialize call network handler (subscribes to network + call streams).
  await getIt<CallNetworkHandler>().initialize();
}
