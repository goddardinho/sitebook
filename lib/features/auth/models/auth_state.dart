import 'user.dart';

/// Authentication state representing the current auth status
enum AuthStatus {
  /// Authentication state is unknown (app is initializing)
  unknown,

  /// User is not authenticated
  unauthenticated,

  /// User is authenticated
  authenticated,

  /// Authentication is in progress
  authenticating,
}

/// Authentication state with user data and status
class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  const AuthState({required this.status, this.user, this.errorMessage});

  /// Initial unknown state
  const AuthState.unknown() : this(status: AuthStatus.unknown);

  /// Unauthenticated state
  const AuthState.unauthenticated([String? errorMessage])
    : this(status: AuthStatus.unauthenticated, errorMessage: errorMessage);

  /// Authenticated state with user
  const AuthState.authenticated(User user)
    : this(status: AuthStatus.authenticated, user: user);

  /// Authenticating state
  const AuthState.authenticating() : this(status: AuthStatus.authenticating);

  /// Copy with new values
  AuthState copyWith({AuthStatus? status, User? user, String? errorMessage}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Convenience getters
  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;
  bool get isAuthenticating => status == AuthStatus.authenticating;
  bool get isUnknown => status == AuthStatus.unknown;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          user == other.user &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => status.hashCode ^ user.hashCode ^ errorMessage.hashCode;

  @override
  String toString() {
    return 'AuthState{status: $status, user: ${user?.email}, error: $errorMessage}';
  }
}

/// Authentication tokens for API access
class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  /// Factory constructor from JSON response
  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresAt: DateTime.now().add(
        Duration(seconds: json['expiresIn'] as int? ?? 3600),
      ),
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  /// Check if access token is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Check if token expires soon (within 5 minutes)
  bool get isExpiringSoon =>
      DateTime.now().add(const Duration(minutes: 5)).isAfter(expiresAt);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthTokens &&
          runtimeType == other.runtimeType &&
          accessToken == other.accessToken &&
          refreshToken == other.refreshToken;

  @override
  int get hashCode => accessToken.hashCode ^ refreshToken.hashCode;

  @override
  String toString() {
    return 'AuthTokens{expires: $expiresAt, isExpired: $isExpired}';
  }
}

/// Login request data
class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password};
  }
}

/// Registration request data
class RegisterRequest {
  final String name;
  final String email;
  final String password;
  final String? location;

  const RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
    this.location,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
      if (location != null) 'location': location,
    };
  }
}

/// Authentication response from API
class AuthResponse {
  final User user;
  final AuthTokens tokens;

  const AuthResponse({required this.user, required this.tokens});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      tokens: AuthTokens.fromJson(json['tokens'] as Map<String, dynamic>),
    );
  }
}
