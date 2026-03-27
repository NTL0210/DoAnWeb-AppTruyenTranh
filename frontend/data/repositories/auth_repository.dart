import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/avatar_service.dart';
import '../../core/storage/secure_storage_service.dart';

/// Authentication repository
/// Aggregates auth-related services and manages user state
class AuthRepository {
  final AuthService _authService = AuthService();
  final AvatarService _avatarService = AvatarService();
  final SecureStorageService _secureStorage = SecureStorageService();

  // ==================== AUTHENTICATION ====================

  /// Login with email/username and password
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    bool isUsername = false,
  }) async {
    final result = await _authService.login(
      mail: email,
      password: password,
      isUsername: isUsername,
    );

    if (result['success'] == true && result['user'] != null) {
      // Save user data to SharedPreferences
      await _saveUserData(result['user']);
    }

    return result;
  }

  /// Login with Google
  Future<Map<String, dynamic>> googleLogin({
    required String idToken,
  }) async {
    final result = await _authService.googleLogin(idToken: idToken);

    if (result['success'] == true && result['user'] != null) {
      // Save user data to SharedPreferences
      await _saveUserData(result['user']);
    }

    return result;
  }

  /// Register new account
  Future<Map<String, dynamic>> register({
    required String userName,
    required String email,
    required String password,
    String? image,
  }) async {
    return await _authService.register(
      userName: userName,
      mail: email,
      password: password,
      image: image,
    );
  }

  /// Logout
  Future<void> logout() async {
    await _authService.logout();
    await _clearUserData();
  }

  // ==================== PASSWORD MANAGEMENT ====================

  /// Request password reset (send OTP)
  Future<Map<String, dynamic>> requestPasswordReset({
    required String email,
  }) async {
    return await _authService.requestPasswordReset(mail: email);
  }

  /// Reset password with OTP
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    return await _authService.resetPassword(
      mail: email,
      otp: otp,
      newPassword: newPassword,
    );
  }

  // ==================== PROFILE MANAGEMENT ====================

  /// Get user profile from server
  Future<Map<String, dynamic>?> getUserProfile() async {
    final profile = await _authService.fetchUserProfile();

    if (profile != null) {
      // Update local cache
      await _updateUserDataFromProfile(profile);
      
      // Cache avatar
      if (profile['image'] != null) {
        await _secureStorage.saveCachedAvatar(profile['image']);
      }
    }

    return profile;
  }

  /// Update username
  Future<Map<String, dynamic>> updateUsername(String newUsername) async {
    final result = await _authService.updateUsername(newUsername);

    if (result['success'] == true && result['user'] != null) {
      await _updateUserDataField('userName', newUsername);
    }

    return result;
  }

  /// Upload avatar
  Future<Map<String, dynamic>> uploadAvatar({
    required String imagePath,
    required String userName,
  }) async {
    // Validate image first
    if (!_avatarService.validateImage(imagePath)) {
      return {
        'success': false,
        'error': 'Ảnh không hợp lệ',
      };
    }

    final result = await _avatarService.uploadAvatar(imagePath, userName);

    if (result['success'] == true) {
      // Update local user data
      if (result['userName'] != null) {
        await _updateUserDataField('userName', result['userName']);
      }
      if (result['image'] != null) {
        await _updateUserDataField('image', result['image']);
        await _secureStorage.saveCachedAvatar(result['image']);
      }
    }

    return result;
  }

  /// Update username only (without avatar)
  Future<Map<String, dynamic>> updateUsernameOnly(String newUsername) async {
    final result = await _avatarService.updateUsernameOnly(newUsername);

    if (result['success'] == true && result['userName'] != null) {
      await _updateUserDataField('userName', result['userName']);
    }

    return result;
  }

  // ==================== USER STATE ====================

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await _authService.isLoggedIn();
  }

  /// Get current user data from local storage
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataJson = prefs.getString('user_data');

      if (userDataJson != null && userDataJson.isNotEmpty) {
        return json.decode(userDataJson) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('❌ Error getting current user data: $e');
      return null;
    }
  }

  /// Get cached avatar
  Future<String?> getCachedAvatar() async {
    return await _secureStorage.getCachedAvatar();
  }

  /// Get auth token
  Future<String?> getAuthToken() async {
    return await _authService.getAuthToken();
  }

  // ==================== PRIVATE HELPERS ====================

  /// Save user data to SharedPreferences
  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', json.encode(userData));
      
      // Also save to secure storage
      await _secureStorage.saveUserData(json.encode(userData));
      
      print('✅ User data saved to local storage');
    } catch (e) {
      print('❌ Error saving user data: $e');
    }
  }

  /// Update user data from profile response
  Future<void> _updateUserDataFromProfile(Map<String, dynamic> profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataJson = prefs.getString('user_data');

      Map<String, dynamic> userData = {};
      if (userDataJson != null) {
        userData = json.decode(userDataJson);
      }

      // Update fields from profile
      if (profile['userName'] != null) {
        userData['userName'] = profile['userName'];
      }
      if (profile['mail'] != null) {
        userData['mail'] = profile['mail'];
      }
      if (profile['image'] != null) {
        userData['image'] = profile['image'];
      }

      await prefs.setString('user_data', json.encode(userData));
      await _secureStorage.saveUserData(json.encode(userData));
      
      print('✅ User data updated from profile');
    } catch (e) {
      print('❌ Error updating user data from profile: $e');
    }
  }

  /// Update a specific field in user data
  Future<void> _updateUserDataField(String field, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataJson = prefs.getString('user_data');

      if (userDataJson != null) {
        final userData = json.decode(userDataJson) as Map<String, dynamic>;
        userData[field] = value;
        await prefs.setString('user_data', json.encode(userData));
        await _secureStorage.saveUserData(json.encode(userData));
        print('✅ Updated user data field: $field');
      }
    } catch (e) {
      print('❌ Error updating user data field: $e');
    }
  }

  /// Clear user data from local storage
  Future<void> _clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      await _secureStorage.deleteUserData();
      print('✅ User data cleared from local storage');
    } catch (e) {
      print('❌ Error clearing user data: $e');
    }
  }
}

