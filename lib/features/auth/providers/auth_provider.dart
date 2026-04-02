import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_state.dart';
import '../models/user.dart';
import '../services/auth_repository.dart';
import '../../../core/utils/app_logger.dart';

/// Provider for the AuthRepository instance
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Provider for the current authentication state
final authStateProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

/// Provider for the current authenticated user (convenience provider)
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.user;
});

/// Provider that checks if user is authenticated (convenience provider)
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.isAuthenticated;
});

/// State notifier that manages authentication state
class AuthNotifier extends Notifier<AuthState> {
  late AuthRepository _authRepository;

  @override
  AuthState build() {
    _authRepository = ref.watch(authRepositoryProvider);
    // Initialize authentication state when provider is created
    _initialize();
    return const AuthState.unknown();
  }

  /// Initialize authentication state by checking stored credentials
  Future<void> _initialize() async {
    try {
      AppLogger.info('AuthNotifier: Initializing authentication state');
      final authState = await _authRepository.initialize();
      state = authState;
    } catch (e) {
      AppLogger.error('AuthNotifier: Error during initialization', e);
      state = const AuthState.unauthenticated(
        'Error loading authentication state',
      );
    }
  }

  /// Sign in with email and password
  Future<void> signIn(String email, String password) async {
    if (state.isAuthenticating) {
      AppLogger.warning('AuthNotifier: Sign in already in progress');
      return;
    }

    try {
      AppLogger.auth('Starting sign in process', userId: email);
      state = const AuthState.authenticating();

      final result = await _authRepository.signIn(email, password);
      state = result;

      if (result.isAuthenticated) {
        AppLogger.auth(
          'Sign in successful',
          userId: result.user?.id,
          isSuccess: true,
        );
      } else {
        AppLogger.auth(
          'Sign in failed: ${result.errorMessage}',
          isSuccess: false,
        );
      }
    } catch (e) {
      AppLogger.error('AuthNotifier: Unexpected error during sign in', e);
      state = const AuthState.unauthenticated('An unexpected error occurred');
    }
  }

  /// Sign up with user details
  Future<void> signUp(
    String name,
    String email,
    String password, {
    String? location,
  }) async {
    if (state.isAuthenticating) {
      AppLogger.warning('AuthNotifier: Sign up already in progress');
      return;
    }

    try {
      AppLogger.auth('Starting sign up process', userId: email);
      state = const AuthState.authenticating();

      final result = await _authRepository.signUp(
        name,
        email,
        password,
        location: location,
      );
      state = result;

      if (result.isAuthenticated) {
        AppLogger.auth(
          'Sign up successful',
          userId: result.user?.id,
          isSuccess: true,
        );
      } else {
        AppLogger.auth(
          'Sign up failed: ${result.errorMessage}',
          isSuccess: false,
        );
      }
    } catch (e) {
      AppLogger.error('AuthNotifier: Unexpected error during sign up', e);
      state = const AuthState.unauthenticated('An unexpected error occurred');
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      AppLogger.auth('Starting sign out process', userId: state.user?.id);

      final result = await _authRepository.signOut();
      state = result;

      AppLogger.auth('Sign out completed', isSuccess: true);
    } catch (e) {
      AppLogger.error('AuthNotifier: Error during sign out', e);
      // Still update state to signed out even if there was an error
      state = const AuthState.unauthenticated();
    }
  }

  /// Refresh the access token
  Future<void> refreshToken() async {
    try {
      AppLogger.auth('Refreshing access token');

      final result = await _authRepository.refreshAccessToken();
      state = result;

      if (result.isAuthenticated) {
        AppLogger.auth('Token refresh successful', isSuccess: true);
      } else {
        AppLogger.auth(
          'Token refresh failed: ${result.errorMessage}',
          isSuccess: false,
        );
      }
    } catch (e) {
      AppLogger.error('AuthNotifier: Error during token refresh', e);
      state = const AuthState.unauthenticated(
        'Session expired. Please sign in again.',
      );
    }
  }

  /// Update user profile
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    if (!state.isAuthenticated) {
      AppLogger.warning(
        'AuthNotifier: Cannot update profile - user not authenticated',
      );
      return;
    }

    try {
      AppLogger.info('AuthNotifier: Updating user profile');

      final result = await _authRepository.updateProfile(updates);
      state = result;

      if (result.isAuthenticated && result.errorMessage == null) {
        AppLogger.info('AuthNotifier: Profile update successful');
      } else {
        AppLogger.warning(
          'AuthNotifier: Profile update failed - ${result.errorMessage}',
        );
      }
    } catch (e) {
      AppLogger.error('AuthNotifier: Error during profile update', e);
      state = state.copyWith(errorMessage: 'Failed to update profile');
    }
  }

  /// Clear any error messages
  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(errorMessage: null);
    }
  }

  /// Force refresh of authentication state (useful after external changes)
  Future<void> refresh() async {
    await _initialize();
  }

  /// Get current access token for API calls
  Future<String?> getAccessToken() async {
    return await _authRepository.getAccessToken();
  }

  /// Debug method to check stored authentication data
  Future<Map<String, String?>> debugGetStorageData() async {
    return await _authRepository.debugGetStorageData();
  }
}

/// Provider for accessing AuthNotifier methods without watching state changes
final authActionsProvider = Provider<AuthActions>((ref) {
  final authNotifier = ref.read(authStateProvider.notifier);
  return AuthActions(authNotifier);
});

/// Helper class to provide authentication actions without state watching
class AuthActions {
  final AuthNotifier _notifier;

  AuthActions(this._notifier);

  Future<void> signIn(String email, String password) =>
      _notifier.signIn(email, password);
  Future<void> signUp(
    String name,
    String email,
    String password, {
    String? location,
  }) => _notifier.signUp(name, email, password, location: location);
  Future<void> signOut() => _notifier.signOut();
  Future<void> refreshToken() => _notifier.refreshToken();
  Future<void> updateProfile(Map<String, dynamic> updates) =>
      _notifier.updateProfile(updates);
  void clearError() => _notifier.clearError();
  Future<void> refresh() => _notifier.refresh();
  Future<String?> getAccessToken() => _notifier.getAccessToken();
  Future<Map<String, String?>> debugGetStorageData() =>
      _notifier.debugGetStorageData();
}
