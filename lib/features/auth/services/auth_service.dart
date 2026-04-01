import 'package:dio/dio.dart';
import '../models/auth_state.dart';
import '../models/user.dart';

/// Exception thrown when authentication operations fail
class AuthException implements Exception {
  final String message;
  final String? code;

  const AuthException(this.message, [this.code]);

  @override
  String toString() =>
      'AuthException: $message${code != null ? ' ($code)' : ''}';
}

/// Service for handling authentication API calls
class AuthService {
  final Dio _dio;

  AuthService({Dio? dio}) : _dio = dio ?? _createDefaultDio();

  /// Create default Dio instance with configuration
  static Dio _createDefaultDio() {
    final dio = Dio();
    dio.options = BaseOptions(
      baseUrl:
          'https://sitebook-api.example.com/api/v1', // TODO: Replace with actual API URL
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    // Add secure logging interceptor for development
    // Note: In production, consider removing or using a custom interceptor
    // that excludes sensitive data from logs
    dio.interceptors.add(
      LogInterceptor(
        requestBody:
            false, // SECURITY: Don't log request bodies (contain passwords)
        responseBody:
            false, // SECURITY: Don't log response bodies (contain tokens)
        requestHeader:
            false, // SECURITY: Don't log headers (contain auth tokens)
        logPrint: (log) => print('🌐 API: $log'),
      ),
    );

    return dio;
  }

  /// Login with email and password
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      print('🔐 AuthService: Attempting login for ${request.email}');

      final response = await _dio.post('/auth/login', data: request.toJson());

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(response.data);
        print('✅ AuthService: Login successful for ${authResponse.user.email}');
        return authResponse;
      } else {
        throw AuthException('Login failed with status ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ AuthService: Login failed - ${e.message}');
      throw _handleDioException(e);
    } catch (e) {
      print('❌ AuthService: Unexpected login error - $e');
      throw AuthException('An unexpected error occurred during login');
    }
  }

  /// Register new user account
  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      print('📝 AuthService: Attempting registration for ${request.email}');

      final response = await _dio.post(
        '/auth/register',
        data: request.toJson(),
      );

      if (response.statusCode == 201) {
        final authResponse = AuthResponse.fromJson(response.data);
        print(
          '✅ AuthService: Registration successful for ${authResponse.user.email}',
        );
        return authResponse;
      } else {
        throw AuthException(
          'Registration failed with status ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print('❌ AuthService: Registration failed - ${e.message}');
      throw _handleDioException(e);
    } catch (e) {
      print('❌ AuthService: Unexpected registration error - $e');
      throw AuthException('An unexpected error occurred during registration');
    }
  }

  /// Refresh access token using refresh token
  Future<AuthTokens> refreshToken(String refreshToken) async {
    try {
      print('🔄 AuthService: Refreshing access token');

      final response = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final tokens = AuthTokens.fromJson(response.data);
        print('✅ AuthService: Token refresh successful');
        return tokens;
      } else {
        throw AuthException(
          'Token refresh failed with status ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print('❌ AuthService: Token refresh failed - ${e.message}');
      throw _handleDioException(e);
    } catch (e) {
      print('❌ AuthService: Unexpected token refresh error - $e');
      throw AuthException('An unexpected error occurred during token refresh');
    }
  }

  /// Get current user profile
  Future<User> getCurrentUser(String accessToken) async {
    try {
      print('👤 AuthService: Fetching current user profile');

      final response = await _dio.get(
        '/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200) {
        final user = User.fromJson(response.data);
        print('✅ AuthService: User profile fetched for ${user.email}');
        return user;
      } else {
        throw AuthException(
          'Failed to fetch user profile with status ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print('❌ AuthService: Failed to fetch user profile - ${e.message}');
      throw _handleDioException(e);
    } catch (e) {
      print('❌ AuthService: Unexpected error fetching user profile - $e');
      throw AuthException(
        'An unexpected error occurred while fetching user profile',
      );
    }
  }

  /// Update user profile
  Future<User> updateProfile(
    String accessToken,
    Map<String, dynamic> updates,
  ) async {
    try {
      print('📝 AuthService: Updating user profile');

      final response = await _dio.put(
        '/auth/profile',
        data: updates,
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200) {
        final user = User.fromJson(response.data);
        print('✅ AuthService: Profile updated for ${user.email}');
        return user;
      } else {
        throw AuthException(
          'Profile update failed with status ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print('❌ AuthService: Profile update failed - ${e.message}');
      throw _handleDioException(e);
    } catch (e) {
      print('❌ AuthService: Unexpected error updating profile - $e');
      throw AuthException(
        'An unexpected error occurred while updating profile',
      );
    }
  }

  /// Logout (invalidate refresh token on server)
  Future<void> logout(String refreshToken) async {
    try {
      print('👋 AuthService: Logging out user');

      await _dio.post('/auth/logout', data: {'refreshToken': refreshToken});

      print('✅ AuthService: Logout successful');
    } on DioException catch (e) {
      print('⚠️ AuthService: Logout failed - ${e.message} (continuing anyway)');
      // Continue with logout even if server call fails
    } catch (e) {
      print('⚠️ AuthService: Unexpected logout error - $e (continuing anyway)');
      // Continue with logout even if unexpected error occurs
    }
  }

  /// Handle Dio exceptions and convert to AuthException
  AuthException _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const AuthException(
          'Connection timeout. Please check your internet connection.',
        );

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;

        if (statusCode == 401) {
          return const AuthException(
            'Invalid credentials',
            'INVALID_CREDENTIALS',
          );
        } else if (statusCode == 422) {
          // Validation error - extract message if available
          final message = responseData is Map && responseData['message'] != null
              ? responseData['message'] as String
              : 'Please check your input and try again';
          return AuthException(message, 'VALIDATION_ERROR');
        } else if (statusCode == 409) {
          return const AuthException(
            'Email address is already registered',
            'EMAIL_EXISTS',
          );
        } else if (statusCode != null && statusCode >= 500) {
          return const AuthException(
            'Server error. Please try again later.',
            'SERVER_ERROR',
          );
        } else {
          return AuthException(
            'Request failed with status $statusCode',
            'BAD_RESPONSE',
          );
        }

      case DioExceptionType.cancel:
        return const AuthException('Request was cancelled');

      case DioExceptionType.connectionError:
        return const AuthException(
          'Unable to connect to the server. Please check your internet connection.',
        );

      case DioExceptionType.unknown:
      default:
        return const AuthException(
          'An unexpected error occurred. Please try again.',
        );
    }
  }
}
