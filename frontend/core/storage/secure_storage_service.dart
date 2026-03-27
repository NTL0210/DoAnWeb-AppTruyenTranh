import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage service for sensitive data like auth tokens
/// Uses flutter_secure_storage which encrypts data on device
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // Keys
  static const String _authTokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';
  static const String _cachedAvatarKey = 'cached_avatar';

  // ==================== AUTH TOKEN ====================
  
  /// Save authentication token securely
  Future<void> saveAuthToken(String token) async {
    try {
      await _storage.write(key: _authTokenKey, value: token);
      print('✅ Auth token saved securely');
    } catch (e) {
      print('❌ Error saving auth token: $e');
      rethrow;
    }
  }

  /// Get authentication token
  Future<String?> getAuthToken() async {
    try {
      return await _storage.read(key: _authTokenKey);
    } catch (e) {
      print('❌ Error reading auth token: $e');
      return null;
    }
  }

  /// Delete authentication token (logout)
  Future<void> deleteAuthToken() async {
    try {
      await _storage.delete(key: _authTokenKey);
      print('✅ Auth token deleted');
    } catch (e) {
      print('❌ Error deleting auth token: $e');
      rethrow;
    }
  }

  /// Check if user has valid auth token
  Future<bool> hasAuthToken() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }

  // ==================== USER DATA ====================

  /// Save user data as JSON string
  Future<void> saveUserData(String userData) async {
    try {
      await _storage.write(key: _userDataKey, value: userData);
      print('✅ User data saved securely');
    } catch (e) {
      print('❌ Error saving user data: $e');
      rethrow;
    }
  }

  /// Get user data
  Future<String?> getUserData() async {
    try {
      return await _storage.read(key: _userDataKey);
    } catch (e) {
      print('❌ Error reading user data: $e');
      return null;
    }
  }

  /// Delete user data
  Future<void> deleteUserData() async {
    try {
      await _storage.delete(key: _userDataKey);
      print('✅ User data deleted');
    } catch (e) {
      print('❌ Error deleting user data: $e');
      rethrow;
    }
  }

  // ==================== CACHED AVATAR ====================

  /// Save cached avatar URL/data
  Future<void> saveCachedAvatar(String avatarData) async {
    try {
      await _storage.write(key: _cachedAvatarKey, value: avatarData);
      print('✅ Cached avatar saved');
    } catch (e) {
      print('❌ Error saving cached avatar: $e');
      rethrow;
    }
  }

  /// Get cached avatar
  Future<String?> getCachedAvatar() async {
    try {
      return await _storage.read(key: _cachedAvatarKey);
    } catch (e) {
      print('❌ Error reading cached avatar: $e');
      return null;
    }
  }

  // ==================== UTILITIES ====================

  /// Clear all secure storage (logout completely)
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
      print('✅ All secure storage cleared');
    } catch (e) {
      print('❌ Error clearing secure storage: $e');
      rethrow;
    }
  }

  /// Check if storage contains a key
  Future<bool> containsKey(String key) async {
    try {
      final value = await _storage.read(key: key);
      return value != null;
    } catch (e) {
      print('❌ Error checking key existence: $e');
      return false;
    }
  }
}

