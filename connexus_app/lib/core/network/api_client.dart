import 'package:dio/dio.dart';

import '../config/app_config.dart';

/// High-level API client used across the app.
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: '${AppConfig.apiBaseUrl}/api/${AppConfig.apiVersion}',
        connectTimeout: Duration(milliseconds: AppConfig.apiTimeout),
        receiveTimeout: Duration(milliseconds: AppConfig.apiTimeout),
        headers: const <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    if (AppConfig.debugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestHeader: true,
          requestBody: true,
          responseHeader: true,
          responseBody: true,
        ),
      );
    }

    _dio.interceptors.add(AuthInterceptor());
  }

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;

  Dio get dio => _dio;

  Future<Response<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? params,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.get<T>(
      endpoint,
      queryParameters: params,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> post<T>(
    String endpoint, {
    dynamic data,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.post<T>(
      endpoint,
      data: data,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> put<T>(
    String endpoint, {
    dynamic data,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.put<T>(
      endpoint,
      data: data,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> delete<T>(
    String endpoint, {
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.delete<T>(
      endpoint,
      options: options,
      cancelToken: cancelToken,
    );
  }
}

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // TODO: Add token from secure storage when auth is implemented.
    super.onRequest(options, handler);
  }
}
