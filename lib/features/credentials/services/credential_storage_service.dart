import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/reservation_credential.dart';

/// Secure storage service for reservation system credentials
class CredentialStorageService {
  static const String _credentialsKey = 'reservation_credentials';
  static final FlutterSecureStorage _secureStorage =
      const FlutterSecureStorage();

  /// Load all credentials
  Future<List<ReservationCredential>> loadCredentials() async {
    final jsonString = await _secureStorage.read(key: _credentialsKey);
    if (jsonString == null) return [];
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((e) => ReservationCredential.fromJson(e)).toList();
  }

  /// Save all credentials
  Future<void> saveCredentials(List<ReservationCredential> credentials) async {
    final jsonString = jsonEncode(credentials.map((e) => e.toJson()).toList());
    await _secureStorage.write(key: _credentialsKey, value: jsonString);
  }

  /// Add or update a credential
  Future<void> upsertCredential(ReservationCredential credential) async {
    final credentials = await loadCredentials();
    final idx = credentials.indexWhere((c) => c.id == credential.id);
    if (idx >= 0) {
      credentials[idx] = credential;
    } else {
      credentials.add(credential);
    }
    await saveCredentials(credentials);
  }

  /// Remove a credential
  Future<void> removeCredential(String id) async {
    final credentials = await loadCredentials();
    credentials.removeWhere((c) => c.id == id);
    await saveCredentials(credentials);
  }

  /// Clear all credentials
  Future<void> clearAll() async {
    await _secureStorage.delete(key: _credentialsKey);
  }
}
