import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../utils/http_client_helper.dart';

/// Authentication service
/// Handles login, register, password reset, Google Sign-In
class AuthService {
  static const String _baseUrl =
      'https://cytostomal-nonsubtractive-bryanna.ngrok-free.dev/api';
  static const String baseUrl =
      'https://cytostomal-nonsubtractive-bryanna.ngrok-free.dev';

  final SecureStorageService _secureStorage = SecureStorageService();

  /// Create HTTP client with SSL configuration for current environment
  http.Client _createClient() {
    return IOClient(HttpClientHelper.createHttpClient());
  }

  // ==================== LOGIN ====================

  /// Login with email/username and password
  Future<Map<String, dynamic>> login({
    required String mail,
    required String password,
    bool isUsername = false,
  }) async {
    try {
      print('=== AuthService: Logging in user ===');
      final uri = Uri.parse('$_baseUrl/Auth/login');
      print('🌐 Login URL: $uri');

      final requestBody = {
        'loginName': mail,
        'password': password,
      };

      print('📤 Request body: $requestBody');

      final client = _createClient();
      final response = await client.post(
        uri,
        headers: {
          'Accept': '*/*',
          'Content-Type': 'application/json',
          'User-Agent': 'demo-app/1.0 (flutter)',
        },
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 15));
      client.close();

      print('📡 Login response status: ${response.statusCode}');
      print('📏 Login response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final Map<String, dynamic> responseData = json.decode(response.body);
          print('✅ Login successful');

          // Save token to secure storage
          final token = responseData['token'];
          if (token != null) {
            await _secureStorage.saveAuthToken(token);
          }

          return {
            'success': true,
            'data': responseData,
            'token': token,
            'user': responseData['user'],
          };
        } catch (parseError) {
          print('❌ JSON parse error: $parseError');
          return {
            'success': false,
            'error': 'Lỗi phân tích phản hồi từ server',
          };
        }
      } else {
        try {
          final Map<String, dynamic> errorData = json.decode(response.body);
          final String errorMessage =
              errorData['message'] ?? 'Đăng nhập thất bại';
          print('❌ Login failed: $errorMessage');
          return {
            'success': false,
            'error': errorMessage,
          };
        } catch (parseError) {
          print('❌ Error response parse error: $parseError');
          return {
            'success': false,
            'error': 'Đăng nhập thất bại (HTTP ${response.statusCode})',
          };
        }
      }
    } catch (e) {
      print('❌ Login network error: $e');
      return {
        'success': false,
        'error': 'Lỗi kết nối: $e',
      };
    }
  }

  // ==================== GOOGLE LOGIN ====================

  /// Login with Google ID token
  Future<Map<String, dynamic>> googleLogin({
    required String idToken,
  }) async {
    try {
      print('=== AuthService: Google Login ===');
      final uri = Uri.parse('$_baseUrl/Auth/google-login');
      print('🌐 Google Login URL: $uri');

      final requestBody = {
        'idToken': idToken,
      };

      print('📤 Request body: {"idToken": "${idToken.substring(0, 50)}..."}');

      final client = _createClient();
      final response = await client.post(
        uri,
        headers: {
          'Accept': '*/*',
          'Content-Type': 'application/json',
          'User-Agent': 'demo-app/1.0 (flutter)',
        },
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 15));
      client.close();

      print('📡 Google Login response status: ${response.statusCode}');
      print('📏 Google Login response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final Map<String, dynamic> responseData = json.decode(response.body);
          print('✅ Google Login successful');

          // Save token to secure storage
          final token = responseData['token'];
          if (token != null) {
            await _secureStorage.saveAuthToken(token);
          }

          return {
            'success': true,
            'message': responseData['message'],
            'token': token,
            'user': responseData['user'],
            'isNewUser': responseData['isNewUser'] ?? false,
          };
        } catch (parseError) {
          print('❌ JSON parse error: $parseError');
          return {
            'success': false,
            'error': 'Lỗi phân tích phản hồi từ server',
          };
        }
      } else {
        try {
          final Map<String, dynamic> errorData = json.decode(response.body);
          final String errorMessage =
              errorData['message'] ?? 'Đăng nhập Google thất bại';
          print('❌ Google Login failed: $errorMessage');
          return {
            'success': false,
            'error': errorMessage,
          };
        } catch (parseError) {
          print('❌ Error response parse error: $parseError');
          return {
            'success': false,
            'error': 'Đăng nhập Google thất bại (HTTP ${response.statusCode})',
          };
        }
      }
    } catch (e) {
      print('❌ Google Login network error: $e');
      return {
        'success': false,
        'error': 'Lỗi kết nối: $e',
      };
    }
  }

  // ==================== REGISTER ====================

  /// Register new account
  Future<Map<String, dynamic>> register({
    required String userName,
    required String mail,
    required String password,
    String? image,
  }) async {
    try {
      print('=== AuthService: Registering new user ===');
      final uri = Uri.parse('$_baseUrl/Auth/register');
      print('🌐 Register URL: $uri');

      final requestBody = {
        'userName': userName,
        'mail': mail,
        'password': password,
        if (image != null) 'image': image,
      };

      print('📤 Request body: $requestBody');

      final client = _createClient();
      final response = await client.post(
        uri,
        headers: {
          'Accept': '*/*',
          'Content-Type': 'application/json',
          'User-Agent': 'demo-app/1.0 (flutter)',
        },
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 15));
      client.close();

      print('📡 Register response status: ${response.statusCode}');
      print('📏 Register response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final Map<String, dynamic> responseData = json.decode(response.body);
          print('✅ Registration successful');
          return {
            'success': true,
            'data': responseData,
          };
        } catch (parseError) {
          print('❌ JSON parse error: $parseError');
          return {
            'success': false,
            'error': 'Lỗi phân tích phản hồi từ server',
          };
        }
      } else {
        try {
          final Map<String, dynamic> errorData = json.decode(response.body);
          final String errorMessage =
              errorData['message'] ?? 'Đăng ký thất bại';
          print('❌ Registration failed: $errorMessage');
          return {
            'success': false,
            'error': errorMessage,
          };
        } catch (parseError) {
          print('❌ Error response parse error: $parseError');
          return {
            'success': false,
            'error': 'Đăng ký thất bại (HTTP ${response.statusCode})',
          };
        }
      }
    } catch (e) {
      print('❌ Registration network error: $e');
      return {
        'success': false,
        'error': 'Lỗi kết nối: $e',
      };
    }
  }

  // ==================== PASSWORD RESET ====================

  /// Request password reset (send OTP)
  Future<Map<String, dynamic>> requestPasswordReset({
    required String mail,
  }) async {
    try {
      print('=== AuthService: Request password reset ===');
      final uri = Uri.parse('$_baseUrl/Auth/request-reset');
      print('🌐 Request reset URL: $uri');

      final requestBody = {
        'mail': mail,
      };

      print('📤 Request body: $requestBody');

      final client = _createClient();
      final response = await client.post(
        uri,
        headers: {
          'Accept': '*/*',
          'Content-Type': 'application/json',
          'User-Agent': 'demo-app/1.0 (flutter)',
        },
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 15));
      client.close();

      print('📡 Request reset response status: ${response.statusCode}');
      print('📏 Request reset response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ OTP sent successfully');
        return {
          'success': true,
          'message': response.body,
        };
      } else {
        print('❌ HTTP error: ${response.statusCode}');
        return {
          'success': false,
          'error': 'Không thể gửi mã OTP. Vui lòng thử lại.',
        };
      }
    } catch (e) {
      print('❌ Network error: $e');
      return {
        'success': false,
        'error': 'Lỗi kết nối. Vui lòng kiểm tra internet và thử lại.',
      };
    }
  }

  /// Reset password with OTP
  Future<Map<String, dynamic>> resetPassword({
    required String mail,
    required String otp,
    required String newPassword,
  }) async {
    try {
      print('=== AuthService: Reset password ===');
      final uri = Uri.parse('$_baseUrl/Auth/reset-password');
      print('🌐 Reset password URL: $uri');

      final requestBody = {
        'mail': mail,
        'otp': otp,
        'newPassword': newPassword,
      };

      print('📤 Request body: $requestBody');

      final client = _createClient();
      final response = await client.post(
        uri,
        headers: {
          'Accept': '*/*',
          'Content-Type': 'application/json',
          'User-Agent': 'demo-app/1.0 (flutter)',
        },
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 15));
      client.close();

      print('📡 Reset password response status: ${response.statusCode}');
      print('📏 Reset password response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Password reset successful');
        return {
          'success': true,
          'message': response.body,
        };
      } else {
        print('❌ HTTP error: ${response.statusCode}');
        return {
          'success': false,
          'error': response.body.isNotEmpty
              ? response.body
              : 'Mã OTP không hợp lệ',
        };
      }
    } catch (e) {
      print('❌ Network error: $e');
      return {
        'success': false,
        'error': 'Lỗi kết nối. Vui lòng kiểm tra internet và thử lại.',
      };
    }
  }

  // ==================== PROFILE ====================

  /// Fetch user profile (userName, mail, image)
  Future<Map<String, dynamic>?> fetchUserProfile() async {
    try {
      print('=== AuthService: Fetching user profile ===');

      final token = await _secureStorage.getAuthToken();
      if (token == null || token.isEmpty) {
        print('❌ No auth token found');
        return null;
      }

      final uri = Uri.parse('$_baseUrl/Auth/profile');
      print('🌐 Fetch profile URL: $uri');

      final client = _createClient();
      final response = await client.get(
        uri,
        headers: {
          'Accept': '*/*',
          'Authorization': 'bearer $token',
          'User-Agent': 'demo-app/1.0 (flutter)',
        },
      ).timeout(const Duration(seconds: 15));
      client.close();

      print('📡 Fetch profile response status: ${response.statusCode}');
      print('📏 Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseData = json.decode(response.body);

          if (responseData.containsKey('user') &&
              responseData['user'] != null) {
            final Map<String, dynamic> userData = responseData['user'];

            final String? userName = userData['userName'];
            final String? mail = userData['mail'];
            final String? image = userData['image'];

            print('✅ Profile fetched successfully:');
            print('   - userName: $userName');
            print('   - mail: $mail');
            print('   - image: $image');

            return {
              'userName': userName,
              'mail': mail,
              'image': image,
            };
          } else {
            print('⚠️ No user data in response');
            return null;
          }
        } catch (parseError) {
          print('❌ JSON parse error: $parseError');
          return null;
        }
      } else if (response.statusCode == 401) {
        print('❌ Unauthorized - token may be expired');
        return null;
      } else if (response.statusCode == 404) {
        print('⚠️ Profile not found');
        return null;
      } else {
        print('❌ HTTP error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Network error: $e');
      return null;
    }
  }

  /// Update username
  Future<Map<String, dynamic>> updateUsername(String newUsername) async {
    try {
      print('=== AuthService: Updating username ===');

      final token = await _secureStorage.getAuthToken();
      if (token == null || token.isEmpty) {
        print('❌ No auth token found');
        return {
          'success': false,
          'error': 'Bạn cần đăng nhập để thực hiện chức năng này',
        };
      }

      final uri = Uri.parse('$_baseUrl/Auth/update-username');
      print('🌐 Update username URL: $uri');
      print('📝 New username: $newUsername');

      final requestBody = {
        'userName': newUsername,
      };

      final client = _createClient();
      final response = await client.put(
        uri,
        headers: {
          'Accept': '*/*',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'User-Agent': 'demo-app/1.0 (flutter)',
        },
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 15));
      client.close();

      print('📡 Update username response status: ${response.statusCode}');
      print('📏 Update username response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final Map<String, dynamic> responseData = json.decode(response.body);
          print('✅ Username updated successfully');

          return {
            'success': true,
            'message': responseData['message'] ?? 'Username updated successfully',
            'user': responseData['user'],
          };
        } catch (parseError) {
          print('❌ JSON parse error: $parseError');
          return {
            'success': false,
            'error': 'Lỗi phân tích phản hồi từ server',
          };
        }
      } else {
        try {
          final Map<String, dynamic> errorData = json.decode(response.body);
          final String errorMessage =
              errorData['message'] ?? 'Update username thất bại';
          print('❌ Update username failed: $errorMessage');
          return {
            'success': false,
            'error': errorMessage,
          };
        } catch (parseError) {
          print('❌ Error response parse error: $parseError');
          return {
            'success': false,
            'error': 'Update username thất bại (HTTP ${response.statusCode})',
          };
        }
      }
    } catch (e) {
      print('❌ Update username network error: $e');
      return {
        'success': false,
        'error': 'Lỗi kết nối: $e',
      };
    }
  }

  // ==================== UTILITIES ====================

  /// Get authentication token
  Future<String?> getAuthToken() async {
    return await _secureStorage.getAuthToken();
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await _secureStorage.hasAuthToken();
  }

  /// Logout (clear auth token)
  Future<void> logout() async {
    try {
      await _secureStorage.deleteAuthToken();
      await _secureStorage.deleteUserData();
      print('✅ Logout successful');
    } catch (e) {
      print('❌ Logout error: $e');
      rethrow;
    }
  }
}

