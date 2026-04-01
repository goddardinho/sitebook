import '../models/auth_state.dart';
import '../models/user.dart';
import 'auth_service.dart';
import 'auth_storage_service.dart';

/// Repository that manages authentication state and operations
class AuthRepository {
  final AuthService _authService;
  final AuthStorageService _storageService;

  AuthRepository({AuthService? authService, AuthStorageService? storageService})
    : _authService = authService ?? AuthService(),
      _storageService = storageService ?? AuthStorageService();

  /// Initialize repository and check for existing authentication
  Future<AuthState> initialize() async {
    try {
      print('🚀 AuthRepository: Initializing authentication state');

      // Check if we have stored tokens and user data
      final hasTokens = await _storageService.hasStoredTokens();
      final hasUser = await _storageService.hasStoredUser();

      if (!hasTokens || !hasUser) {
        print('ℹ️ AuthRepository: No stored authentication data found');
        return const AuthState.unauthenticated();
      }

      // Get stored tokens and user data
      final tokens = await _storageService.getTokens();
      final user = await _storageService.getUser();

      if (tokens == null || user == null) {
        print(
          '⚠️ AuthRepository: Failed to retrieve stored authentication data',
        );
        await _storageService.clearAll(); // Clear corrupted data
        return const AuthState.unauthenticated();
      }

      // Check if tokens are expired
      if (tokens.isExpired) {
        print('🔄 AuthRepository: Access token expired, attempting refresh');

        try {
          final newTokens = await _authService.refreshToken(
            tokens.refreshToken,
          );
          await _storageService.updateAccessToken(
            newTokens.accessToken,
            newTokens.expiresAt,
          );

          print('✅ AuthRepository: Token refreshed successfully');
          return AuthState.authenticated(user);
        } catch (e) {
          print('❌ AuthRepository: Token refresh failed - $e');
          await _storageService.clearAll();
          return const AuthState.unauthenticated(
            'Session expired. Please sign in again.',
          );
        }
      }

      print('✅ AuthRepository: User authenticated from stored data');
      return AuthState.authenticated(user);
    } catch (e) {
      print('❌ AuthRepository: Error during initialization - $e');
      // Clear potentially corrupted data
      await _storageService.clearAll();
      return const AuthState.unauthenticated(
        'Error loading authentication state',
      );
    }
  }

  /// Sign in with email and password
  Future<AuthState> signIn(String email, String password) async {
    try {
      print('🔐 AuthRepository: Attempting sign in for $email');

      final loginRequest = LoginRequest(email: email, password: password);
      final authResponse = await _authService.login(loginRequest);

      // Store authentication data
      await Future.wait([
        _storageService.storeTokens(authResponse.tokens),
        _storageService.storeUser(authResponse.user),
      ]);

      print(
        '✅ AuthRepository: Sign in successful for ${authResponse.user.email}',
      );
      return AuthState.authenticated(authResponse.user);
    } on AuthException catch (e) {
      print('❌ AuthRepository: Sign in failed - ${e.message}');
      return AuthState.unauthenticated(e.message);
    } catch (e) {
      print('❌ AuthRepository: Unexpected sign in error - $e');
      return const AuthState.unauthenticated(
        'An unexpected error occurred during sign in',
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
      print('📝 AuthRepository: Attempting sign up for $email');

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

      print(
        '✅ AuthRepository: Sign up successful for ${authResponse.user.email}',
      );
      return AuthState.authenticated(authResponse.user);
    } on AuthException catch (e) {
      print('❌ AuthRepository: Sign up failed - ${e.message}');
      return AuthState.unauthenticated(e.message);
    } catch (e) {
      print('❌ AuthRepository: Unexpected sign up error - $e');
      return const AuthState.unauthenticated(
        'An unexpected error occurred during sign up',
      );
    }
  }

  /// Sign out the current user
  Future<AuthState> signOut() async {
    try {
      print('👋 AuthRepository: Attempting sign out');

      // Get refresh token for server-side logout
      final tokens = await _storageService.getTokens();
      if (tokens != null) {
        await _authService.logout(tokens.refreshToken);
      }

      // Clear all stored authentication data
      await _storageService.clearAll();

      print('✅ AuthRepository: Sign out successful');
      return const AuthState.unauthenticated();
    } catch (e) {
      print('⚠️ AuthRepository: Error during sign out - $e');
      // Still clear local data even if server call fails
      await _storageService.clearAll();
      return const AuthState.unauthenticated();
    }
  }

  /// Refresh the current access token
  Future<AuthState> refreshAccessToken() async {
    try {
      print('🔄 AuthRepository: Refreshing access token');

      final currentTokens = await _storageService.getTokens();
      if (currentTokens == null) {
        print('❌ AuthRepository: No tokens found for refresh');
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
        print('❌ AuthRepository: No user data found after token refresh');
        await _storageService.clearAll();
        return const AuthState.unauthenticated('User data not found');
      }

      print('✅ AuthRepository: Access token refreshed successfully');
      return AuthState.authenticated(user);
    } on AuthException catch (e) {
      print('❌ AuthRepository: Token refresh failed - ${e.message}');
      await _storageService.clearAll();
      return AuthState.unauthenticated(
        'Session expired. Please sign in again.',
      );
    } catch (e) {
      print('❌ AuthRepository: Unexpected error during token refresh - $e');
      await _storageService.clearAll();
      return const AuthState.unauthenticated(
        'Authentication error. Please sign in again.',
      );
    }
  }

  /// Update user profile
  Future<AuthState> updateProfile(Map<String, dynamic> updates) async {
    try {
      print('📝 AuthRepository: Updating user profile');

      final accessToken = await _storageService.getAccessToken();
      if (accessToken == null) {
        print('❌ AuthRepository: No access token for profile update');
        return const AuthState.unauthenticated('Authentication required');
      }

      final updatedUser = await _authService.updateProfile(
        accessToken,
        updates,
      );
      await _storageService.updateUser(updatedUser);

      print('✅ AuthRepository: Profile updated successfully');
      return AuthState.authenticated(updatedUser);
    } on AuthException catch (e) {
      print('❌ AuthRepository: Profile update failed - ${e.message}');

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
      print('❌ AuthRepository: Unexpected error during profile update - $e');
      return const AuthState.unauthenticated('An unexpected error occurred');
    }
  }

  /// Get current user data (from cache/storage)
  Future<User?> getCurrentUser() async {
    try {
      return await _storageService.getUser();
    } catch (e) {
      print('❌ AuthRepository: Error getting current user - $e');
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
      print('❌ AuthRepository: Error checking authentication status - $e');
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
        print(
          '🔄 AuthRepository: Token expiring soon, refreshing automatically',
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
      print('❌ AuthRepository: Error getting access token - $e');
      return null;
    }
  }

  /// Debug method to check stored data (development only)
  Future<Map<String, String?>> debugGetStorageData() async {
    return await _storageService.debugGetAllStoredData();
  }
}
