import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../models/auth_state.dart';
import '../models/user.dart';
import '../../../core/utils/app_logger.dart';

/// Secure storage service for authentication tokens and user data
class AuthStorageService {
  static final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: const AndroidOptions(encryptedSharedPreferences: true),
    iOptions: const IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Storage keys
  static const String _accessTokenKey = 'auth_access_token';
  static const String _refreshTokenKey = 'auth_refresh_token';
  static const String _tokenExpiresAtKey = 'auth_token_expires_at';
  static const String _userDataKey = 'auth_user_data';

  /// Store authentication tokens securely
  Future<void> storeTokens(AuthTokens tokens) async {
    try {
      AppLogger.storage('Storing authentication tokens');

      await Future.wait([
        _secureStorage.write(key: _accessTokenKey, value: tokens.accessToken),
        _secureStorage.write(key: _refreshTokenKey, value: tokens.refreshToken),
        _secureStorage.write(
          key: _tokenExpiresAtKey,
          value: tokens.expiresAt.toIso8601String(),
        ),
      ]);

      AppLogger.storage('Tokens stored successfully', isSuccess: true);
    } catch (e) {
      AppLogger.storage('Failed to store tokens', isSuccess: false);
      throw const AuthStorageException('Failed to store authentication tokens');
    }
  }

  /// Retrieve stored authentication tokens
  Future<AuthTokens?> getTokens() async {
    try {
      AppLogger.storage('Retrieving stored tokens');

      final results = await Future.wait([
        _secureStorage.read(key: _accessTokenKey),
        _secureStorage.read(key: _refreshTokenKey),
        _secureStorage.read(key: _tokenExpiresAtKey),
      ]);

      final accessToken = results[0];
      final refreshToken = results[1];
      final expiresAtString = results[2];

      if (accessToken == null ||
          refreshToken == null ||
          expiresAtString == null) {
        AppLogger.storage('No stored tokens found', isSuccess: false);
        return null;
      }

      final expiresAt = DateTime.parse(expiresAtString);
      final tokens = AuthTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: expiresAt,
      );

      AppLogger.storage('Tokens retrieved successfully', isSuccess: true);
      return tokens;
    } catch (e) {
      AppLogger.storage('Failed to retrieve tokens', isSuccess: false);
      return null;
    }
  }

  /// Update only the access token (during refresh)
  Future<void> updateAccessToken(String accessToken, DateTime expiresAt) async {
    try {
      AppLogger.storage('Updating access token');

      await Future.wait([
        _secureStorage.write(key: _accessTokenKey, value: accessToken),
        _secureStorage.write(
          key: _tokenExpiresAtKey,
          value: expiresAt.toIso8601String(),
        ),
      ]);

      AppLogger.storage('Access token updated successfully', isSuccess: true);
    } catch (e) {
      AppLogger.storage('Failed to update access token', isSuccess: false);
      throw const AuthStorageException('Failed to update access token');
    }
  }

  /// Store user data
  Future<void> storeUser(User user) async {
    try {
      AppLogger.storage('Storing user data');

      final userJson = jsonEncode(user.toJson());
      await _secureStorage.write(key: _userDataKey, value: userJson);

      AppLogger.storage('User data stored successfully', isSuccess: true);
    } catch (e) {
      AppLogger.storage('Failed to store user data', isSuccess: false);
      throw const AuthStorageException('Failed to store user data');
    }
  }

  /// Retrieve stored user data
  Future<User?> getUser() async {
    try {
      AppLogger.storage('Retrieving stored user data');

      final userJson = await _secureStorage.read(key: _userDataKey);

      if (userJson == null) {
        AppLogger.storage('No stored user data found', isSuccess: false);
        return null;
      }

      final userData = jsonDecode(userJson) as Map<String, dynamic>;
      final user = User.fromJson(userData);

      AppLogger.storage('User data retrieved successfully', isSuccess: true);
      return user;
    } catch (e) {
      AppLogger.storage('Failed to retrieve user data', isSuccess: false);
      return null;
    }
  }

  /// Update stored user data
  Future<void> updateUser(User user) async {
    await storeUser(user); // Same implementation as store
  }

  /// Clear all authentication data (logout)
  Future<void> clearAll() async {
    try {
      AppLogger.storage('Clearing all authentication data');

      await Future.wait([
        _secureStorage.delete(key: _accessTokenKey),
        _secureStorage.delete(key: _refreshTokenKey),
        _secureStorage.delete(key: _tokenExpiresAtKey),
        _secureStorage.delete(key: _userDataKey),
      ]);

      AppLogger.storage('All authentication data cleared', isSuccess: true);
    } catch (e) {
      AppLogger.storage(
        'Failed to clear authentication data',
        isSuccess: false,
      );
      // Don't throw exception for cleanup operations
    }
  }

  /// Check if user is stored (quick check without retrieving full data)
  Future<bool> hasStoredUser() async {
    try {
      final userJson = await _secureStorage.read(key: _userDataKey);
      return userJson != null;
    } catch (e) {
      AppLogger.error('AuthStorage: Error checking stored user', e);
      return false;
    }
  }

  /// Check if tokens are stored (quick check without retrieving full data)
  Future<bool> hasStoredTokens() async {
    try {
      final accessToken = await _secureStorage.read(key: _accessTokenKey);
      return accessToken != null;
    } catch (e) {
      AppLogger.error('AuthStorage: Error checking stored tokens', e);
      return false;
    }
  }

  /// Get current access token without full token object
  Future<String?> getAccessToken() async {
    try {
      return await _secureStorage.read(key: _accessTokenKey);
    } catch (e) {
      AppLogger.error('AuthStorage: Error getting access token', e);
      return null;
    }
  }

  /// Debug method to check what's stored (development only)
  Future<Map<String, String?>> debugGetAllStoredData() async {
    try {
      final results = await Future.wait([
        _secureStorage.read(key: _accessTokenKey),
        _secureStorage.read(key: _refreshTokenKey),
        _secureStorage.read(key: _tokenExpiresAtKey),
        _secureStorage.read(key: _userDataKey),
      ]);

      return {
        'accessToken': results[0] != null
            ? '***${results[0]!.substring(results[0]!.length - 8)}'
            : null,
        'refreshToken': results[1] != null
            ? '***${results[1]!.substring(results[1]!.length - 8)}'
            : null,
        'expiresAt': results[2],
        'userData': results[3] != null
            ? 'Present (${results[3]!.length} chars)'
            : null,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}

/// Exception thrown when secure storage operations fail
class AuthStorageException implements Exception {
  final String message;

  const AuthStorageException(this.message);

  @override
  String toString() => 'AuthStorageException: $message';
}
