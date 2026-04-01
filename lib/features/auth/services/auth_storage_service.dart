import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../models/auth_state.dart';
import '../models/user.dart';

/// Secure storage service for authentication tokens and user data
class AuthStorageService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: IOSAccessibility.first_unlock_this_device,
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
      print('🔐 AuthStorage: Storing authentication tokens');
      
      await Future.wait([
        _secureStorage.write(key: _accessTokenKey, value: tokens.accessToken),
        _secureStorage.write(key: _refreshTokenKey, value: tokens.refreshToken),
        _secureStorage.write(key: _tokenExpiresAtKey, value: tokens.expiresAt.toIso8601String()),
      ]);
      
      print('✅ AuthStorage: Tokens stored successfully');
    } catch (e) {
      print('❌ AuthStorage: Failed to store tokens - $e');
      throw AuthStorageException('Failed to store authentication tokens');
    }
  }

  /// Retrieve stored authentication tokens
  Future<AuthTokens?> getTokens() async {
    try {
      print('🔍 AuthStorage: Retrieving stored tokens');
      
      final results = await Future.wait([
        _secureStorage.read(key: _accessTokenKey),
        _secureStorage.read(key: _refreshTokenKey),
        _secureStorage.read(key: _tokenExpiresAtKey),
      ]);
      
      final accessToken = results[0];
      final refreshToken = results[1];
      final expiresAtString = results[2];
      
      if (accessToken == null || refreshToken == null || expiresAtString == null) {
        print('⚠️ AuthStorage: No stored tokens found');
        return null;
      }
      
      final expiresAt = DateTime.parse(expiresAtString);
      final tokens = AuthTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: expiresAt,
      );
      
      print('✅ AuthStorage: Tokens retrieved successfully (expires: ${tokens.expiresAt})');
      return tokens;
    } catch (e) {
      print('❌ AuthStorage: Failed to retrieve tokens - $e');
      return null;
    }
  }

  /// Update only the access token (during refresh)
  Future<void> updateAccessToken(String accessToken, DateTime expiresAt) async {
    try {
      print('🔄 AuthStorage: Updating access token');
      
      await Future.wait([
        _secureStorage.write(key: _accessTokenKey, value: accessToken),
        _secureStorage.write(key: _tokenExpiresAtKey, value: expiresAt.toIso8601String()),
      ]);
      
      print('✅ AuthStorage: Access token updated successfully');
    } catch (e) {
      print('❌ AuthStorage: Failed to update access token - $e');
      throw AuthStorageException('Failed to update access token');
    }
  }

  /// Store user data
  Future<void> storeUser(User user) async {
    try {
      print('👤 AuthStorage: Storing user data for ${user.email}');
      
      final userJson = jsonEncode(user.toJson());
      await _secureStorage.write(key: _userDataKey, value: userJson);
      
      print('✅ AuthStorage: User data stored successfully');
    } catch (e) {
      print('❌ AuthStorage: Failed to store user data - $e');
      throw AuthStorageException('Failed to store user data');
    }
  }

  /// Retrieve stored user data
  Future<User?> getUser() async {
    try {
      print('🔍 AuthStorage: Retrieving stored user data');
      
      final userJson = await _secureStorage.read(key: _userDataKey);
      
      if (userJson == null) {
        print('⚠️ AuthStorage: No stored user data found');
        return null;
      }

      final userData = jsonDecode(userJson) as Map<String, dynamic>;
      final user = User.fromJson(userData);
      
      print('✅ AuthStorage: User data retrieved successfully for ${user.email}');
      return user;
    } catch (e) {
      print('❌ AuthStorage: Failed to retrieve user data - $e');
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
      print('🧹 AuthStorage: Clearing all authentication data');
      
      await Future.wait([
        _secureStorage.delete(key: _accessTokenKey),
        _secureStorage.delete(key: _refreshTokenKey),
        _secureStorage.delete(key: _tokenExpiresAtKey),
        _secureStorage.delete(key: _userDataKey),
      ]);
      
      print('✅ AuthStorage: All authentication data cleared');
    } catch (e) {
      print('❌ AuthStorage: Failed to clear authentication data - $e');
      // Don't throw exception for cleanup operations
    }
  }

  /// Check if user is stored (quick check without retrieving full data)
  Future<bool> hasStoredUser() async {
    try {
      final userJson = await _secureStorage.read(key: _userDataKey);
      return userJson != null;
    } catch (e) {
      print('❌ AuthStorage: Error checking stored user - $e');
      return false;
    }
  }

  /// Check if tokens are stored (quick check without retrieving full data)
  Future<bool> hasStoredTokens() async {
    try {
      final accessToken = await _secureStorage.read(key: _accessTokenKey);
      return accessToken != null;
    } catch (e) {
      print('❌ AuthStorage: Error checking stored tokens - $e');
      return false;
    }
  }

  /// Get current access token without full token object
  Future<String?> getAccessToken() async {
    try {
      return await _secureStorage.read(key: _accessTokenKey);
    } catch (e) {
      print('❌ AuthStorage: Error getting access token - $e');
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
        'accessToken': results[0] != null ? '***${results[0]!.substring(results[0]!.length - 8)}' : null,
        'refreshToken': results[1] != null ? '***${results[1]!.substring(results[1]!.length - 8)}' : null,
        'expiresAt': results[2],
        'userData': results[3] != null ? 'Present (${results[3]!.length} chars)' : null,
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