import '../models/auth_state.dart';
import '../models/user.dart';
import 'auth_service.dart';
import 'auth_storage_service.dart';
import '../../../core/utils/app_logger.dart';

/// Repository that manages authentication state and operations
class AuthRepository {
  final AuthService _authService;
  final AuthStorageService _storageService;

  AuthRepository({AuthService? authService, AuthStorageService? storageService})
    : _authService = authService ?? AuthService(),
      _storageService = storageService ?? AuthStorageService();

  /// Initialize repository and check for existing authentication (Demo User only)
  Future<AuthState> initialize() async {
    AppLogger.info(
      'AuthRepository: Initializing authentication state (Demo User only)',
    );
    final hasUser = await _storageService.hasStoredUser();
    final user = await _storageService.getUser();
    if (hasUser && user != null && user.email == 'demo@sitebook.app') {
      return AuthState.authenticated(user);
    }
    await _storageService.clearAll();
    return const AuthState.unauthenticated();
  }

  /// Sign in with email and password (Demo User only)
  Future<AuthState> signIn(String email, String password) async {
    AppLogger.auth('Attempting local sign in', userId: email);
    if (email == 'demo@sitebook.app' && password == 'demo123') {
      final user = User(
        id: 'demo',
        email: 'demo@sitebook.app',
        name: 'Demo User',
        createdAt: DateTime(2024, 1, 1),
      );
      await _storageService.storeUser(user);
      return AuthState.authenticated(user);
    } else {
      await _storageService.clearAll();
      return const AuthState.unauthenticated(
        'Only Demo User login is supported.',
      );
    }
  }

  /// Sign up with user details
  Future<AuthState> signUp(
    String name,
    String email,
    String password, {
    String? location,
  }) async {
    try {
      AppLogger.auth('Attempting sign up', userId: email);

      final registerRequest = RegisterRequest(
        name: name,
        email: email,
        password: password,
        location: location,
      );

      final authResponse = await _authService.register(registerRequest);

      // Store authentication data
      await Future.wait([
        _storageService.storeTokens(authResponse.tokens),
        _storageService.storeUser(authResponse.user),
      ]);

      AppLogger.auth(
        'Sign up successful',
        userId: authResponse.user.id,
        isSuccess: true,
      );
      return AuthState.authenticated(authResponse.user);
    } on AuthException catch (e) {
      AppLogger.auth('Sign up failed: ${e.message}', isSuccess: false);
      return AuthState.unauthenticated(e.message);
    } catch (e) {
      AppLogger.error('AuthRepository: Unexpected sign up error', e);
      return const AuthState.unauthenticated(
        'An unexpected error occurred during sign up',
      );
    }
  }

  /// Sign out the current user
  Future<AuthState> signOut() async {
    try {
      AppLogger.auth('Attempting sign out');

      // Get refresh token for server-side logout
      final tokens = await _storageService.getTokens();
      if (tokens != null) {
        await _authService.logout(tokens.refreshToken);
      }

      // Clear all stored authentication data
      await _storageService.clearAll();

      AppLogger.auth('Sign out successful', isSuccess: true);
      return const AuthState.unauthenticated();
    } catch (e) {
      AppLogger.warning('AuthRepository: Error during sign out', e);
      // Still clear local data even if server call fails
      await _storageService.clearAll();
      return const AuthState.unauthenticated();
    }
  }

  /// Refresh the current access token
  Future<AuthState> refreshAccessToken() async {
    try {
      AppLogger.auth('Refreshing access token');

      final currentTokens = await _storageService.getTokens();
      if (currentTokens == null) {
        AppLogger.warning('AuthRepository: No tokens found for refresh');
        return const AuthState.unauthenticated(
          'No authentication tokens found',
        );
      }

      final newTokens = await _authService.refreshToken(
        currentTokens.refreshToken,
      );
      await _storageService.updateAccessToken(
        newTokens.accessToken,
        newTokens.expiresAt,
      );

      // Get current user data
      final user = await _storageService.getUser();
      if (user == null) {
        AppLogger.warning(
          'AuthRepository: No user data found after token refresh',
        );
        await _storageService.clearAll();
        return const AuthState.unauthenticated('User data not found');
      }

      AppLogger.auth('Access token refreshed successfully', isSuccess: true);
      return AuthState.authenticated(user);
    } on AuthException catch (e) {
      AppLogger.auth('Token refresh failed: ${e.message}', isSuccess: false);
      await _storageService.clearAll();
      return const AuthState.unauthenticated(
        'Session expired. Please sign in again.',
      );
    } catch (e) {
      AppLogger.error(
        'AuthRepository: Unexpected error during token refresh',
        e,
      );
      await _storageService.clearAll();
      return const AuthState.unauthenticated(
        'Authentication error. Please sign in again.',
      );
    }
  }

  /// Update user profile
  Future<AuthState> updateProfile(Map<String, dynamic> updates) async {
    try {
      AppLogger.info('AuthRepository: Updating user profile');

      final accessToken = await _storageService.getAccessToken();
      if (accessToken == null) {
        AppLogger.warning('AuthRepository: No access token for profile update');
        return const AuthState.unauthenticated('Authentication required');
      }

      final updatedUser = await _authService.updateProfile(
        accessToken,
        updates,
      );
      await _storageService.updateUser(updatedUser);

      AppLogger.info('AuthRepository: Profile updated successfully');
      return AuthState.authenticated(updatedUser);
    } on AuthException catch (e) {
      AppLogger.warning('AuthRepository: Profile update failed - ${e.message}');

      // Check if it's an authentication error
      if (e.code == 'INVALID_CREDENTIALS' ||
          e.message.toLowerCase().contains('unauthorized')) {
        await _storageService.clearAll();
        return const AuthState.unauthenticated(
          'Session expired. Please sign in again.',
        );
      }

      // For other errors, keep current state but return error
      final currentUser = await _storageService.getUser();
      if (currentUser != null) {
        return AuthState.authenticated(
          currentUser,
        ).copyWith(errorMessage: e.message);
      }
      return AuthState.unauthenticated(e.message);
    } catch (e) {
      AppLogger.error(
        'AuthRepository: Unexpected error during profile update',
        e,
      );
      return const AuthState.unauthenticated('An unexpected error occurred');
    }
  }

  /// Get current user data (from cache/storage)
  Future<User?> getCurrentUser() async {
    try {
      return await _storageService.getUser();
    } catch (e) {
      AppLogger.error('AuthRepository: Error getting current user', e);
      return null;
    }
  }

  /// Check if user is currently authenticated
  Future<bool> isAuthenticated() async {
    try {
      final hasTokens = await _storageService.hasStoredTokens();
      final hasUser = await _storageService.hasStoredUser();

      if (!hasTokens || !hasUser) {
        return false;
      }

      final tokens = await _storageService.getTokens();
      return tokens != null && !tokens.isExpired;
    } catch (e) {
      AppLogger.error(
        'AuthRepository: Error checking authentication status',
        e,
      );
      return false;
    }
  }

  /// Get current access token for API calls
  Future<String?> getAccessToken() async {
    try {
      final tokens = await _storageService.getTokens();

      if (tokens == null) {
        return null;
      }

      // Check if token needs refresh
      if (tokens.isExpiringSoon || tokens.isExpired) {
        AppLogger.info(
          'AuthRepository: Token expiring soon, refreshing automatically',
        );
        final refreshResult = await refreshAccessToken();

        if (refreshResult.isAuthenticated) {
          final newTokens = await _storageService.getTokens();
          return newTokens?.accessToken;
        }
        return null;
      }

      return tokens.accessToken;
    } catch (e) {
      AppLogger.error('AuthRepository: Error getting access token', e);
      return null;
    }
  }

  /// Debug method to check stored data (development only)
  Future<Map<String, String?>> debugGetStorageData() async {
    return await _storageService.debugGetAllStoredData();
  }
}
