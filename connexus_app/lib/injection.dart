import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

final getIt = GetIt.instance;

/// Initialize dependency injection
Future<void> configureDependencies() async {
  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton(() => sharedPreferences);

  // Dio configuration
  getIt.registerLazySingleton<Dio>(() {
    final dio = Dio();
    dio.options = BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    // Add interceptors for logging in debug mode
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

  // Register repositories, use cases, blocs/providers in future tasks
}
