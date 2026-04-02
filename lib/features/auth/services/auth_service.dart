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

/// Service for handling authentication (local only)
class AuthService {
  AuthService();

  /// Local-only Demo User login
  Future<AuthResponse> login(LoginRequest request) async {
    print('🔐 AuthService: Local login for ${request.email}');
    if (request.email == 'demo@sitebook.app' && request.password == 'demo123') {
      // Return a mock AuthResponse for Demo User
      final user = User(
        id: 'demo',
        email: 'demo@sitebook.app',
        name: 'Demo User',
        createdAt: DateTime(2024, 1, 1),
      );
      final tokens = AuthTokens(
        accessToken: 'demo-token',
        refreshToken: 'demo-refresh',
        expiresAt: DateTime.now().add(const Duration(days: 365)),
      );
      return AuthResponse(user: user, tokens: tokens);
    } else {
      throw const AuthException('Only Demo User login is supported.');
    }
  }

  /// Registration is not supported
  Future<AuthResponse> register(RegisterRequest request) async {
    throw const AuthException('Registration is not supported.');
  }

  /// Token refresh is not supported
  Future<AuthTokens> refreshToken(String refreshToken) async {
    throw const AuthException('Token refresh is not supported.');
  }

  /// Getting current user profile is not supported (local only)
  Future<User> getCurrentUser(String accessToken) async {
    throw const AuthException('Getting user profile is not supported.');
  }

  /// Updating user profile is not supported (local only)
  Future<User> updateProfile(
    String accessToken,
    Map<String, dynamic> updates,
  ) async {
    throw const AuthException('Updating user profile is not supported.');
  }

  /// Logout is a local operation only
  Future<void> logout(String refreshToken) async {
    // No-op for local only
    print('👋 AuthService: Local logout (no server)');
  }

  // No Dio/network exceptions in local-only mode
}
