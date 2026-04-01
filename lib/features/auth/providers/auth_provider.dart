import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_state.dart';
import '../models/user.dart';
import '../services/auth_repository.dart';

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
      print('🔄 AuthNotifier: Initializing authentication state');
      final authState = await _authRepository.initialize();
      state = authState;
    } catch (e) {
      print('❌ AuthNotifier: Error during initialization - $e');
      state = const AuthState.unauthenticated('Error loading authentication state');
    }
  }

  /// Sign in with email and password
  Future<void> signIn(String email, String password) async {
    if (state.isAuthenticating) {
      print('⚠️ AuthNotifier: Sign in already in progress');
      return;
    }
    
    try {
      print('🔐 AuthNotifier: Starting sign in process');
      state = const AuthState.authenticating();
      
      final result = await _authRepository.signIn(email, password);
      state = result;
      
      if (result.isAuthenticated) {
        print('✅ AuthNotifier: Sign in successful');
      } else {
        print('❌ AuthNotifier: Sign in failed - ${result.errorMessage}');
      }
    } catch (e) {
      print('❌ AuthNotifier: Unexpected error during sign in - $e');
      state = const AuthState.unauthenticated('An unexpected error occurred');
    }
  }

  /// Sign up with user details
  Future<void> signUp(String name, String email, String password, {String? location}) async {
    if (state.isAuthenticating) {
      print('⚠️ AuthNotifier: Sign up already in progress');
      return;
    }
    
    try {
      print('📝 AuthNotifier: Starting sign up process');
      state = const AuthState.authenticating();
      
      final result = await _authRepository.signUp(name, email, password, location: location);
      state = result;
      
      if (result.isAuthenticated) {
        print('✅ AuthNotifier: Sign up successful');
      } else {
        print('❌ AuthNotifier: Sign up failed - ${result.errorMessage}');
      }
    } catch (e) {
      print('❌ AuthNotifier: Unexpected error during sign up - $e');
      state = const AuthState.unauthenticated('An unexpected error occurred');
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      print('👋 AuthNotifier: Starting sign out process');
      
      final result = await _authRepository.signOut();
      state = result;
      
      print('✅ AuthNotifier: Sign out completed');
    } catch (e) {
      print('❌ AuthNotifier: Error during sign out - $e');
      // Still update state to signed out even if there was an error
      state = const AuthState.unauthenticated();
    }
  }

  /// Refresh the access token
  Future<void> refreshToken() async {
    try {
      print('🔄 AuthNotifier: Refreshing access token');
      
      final result = await _authRepository.refreshAccessToken();
      state = result;
      
      if (result.isAuthenticated) {
        print('✅ AuthNotifier: Token refresh successful');
      } else {
        print('❌ AuthNotifier: Token refresh failed - ${result.errorMessage}');
      }
    } catch (e) {
      print('❌ AuthNotifier: Error during token refresh - $e');
      state = const AuthState.unauthenticated('Session expired. Please sign in again.');
    }
  }

  /// Update user profile
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    if (!state.isAuthenticated) {
      print('⚠️ AuthNotifier: Cannot update profile - user not authenticated');
      return;
    }
    
    try {
      print('📝 AuthNotifier: Updating user profile');
      
      final result = await _authRepository.updateProfile(updates);
      state = result;
      
      if (result.isAuthenticated && result.errorMessage == null) {
        print('✅ AuthNotifier: Profile update successful');
      } else {
        print('❌ AuthNotifier: Profile update failed - ${result.errorMessage}');
      }
    } catch (e) {
      print('❌ AuthNotifier: Error during profile update - $e');
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

  Future<void> signIn(String email, String password) => _notifier.signIn(email, password);
  Future<void> signUp(String name, String email, String password, {String? location}) => 
      _notifier.signUp(name, email, password, location: location);
  Future<void> signOut() => _notifier.signOut();
  Future<void> refreshToken() => _notifier.refreshToken();
  Future<void> updateProfile(Map<String, dynamic> updates) => _notifier.updateProfile(updates);
  void clearError() => _notifier.clearError();
  Future<void> refresh() => _notifier.refresh();
  Future<String?> getAccessToken() => _notifier.getAccessToken();
  Future<Map<String, String?>> debugGetStorageData() => _notifier.debugGetStorageData();
}