import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class ApiClient {
  static const String _baseUrl = 'https://ridb.recreation.gov/api/v1';

  // Get API key from environment variable passed via --dart-define
  static const String _apiKey = String.fromEnvironment(
    'RECREATION_GOV_API_KEY',
    defaultValue: '',
  );

  late final Dio _dio;
  final Logger _logger = Logger();

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'apikey': _apiKey,
        },
      ),
    );

    _setupInterceptors();
  }

  void _setupInterceptors() {
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          // SECURITY: Disabled request/response body logging to prevent API key exposure
          logPrint: (obj) => _logger.d(obj),
        ),
      );
    }

    // Error handling interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          _logger.e('API Error: ${error.message}', error: error.error);
          handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;

  // Generic GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      _logger.e('GET request failed: $path', error: e);
      rethrow;
    }
  }

  // Generic POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      _logger.e('POST request failed: $path', error: e);
      rethrow;
    }
  }
}
