import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../utils/http_client_helper.dart';

/// Follow service
/// Handles comic follow/unfollow operations
class FollowService {
  static const String _baseUrl =
      'https://cytostomal-nonsubtractive-bryanna.ngrok-free.dev/api';

  final SecureStorageService _secureStorage = SecureStorageService();

  // Create HTTP client with SSL configuration
  http.Client _createClient() {
    return IOClient(HttpClientHelper.createHttpClient());
  }

  // ==================== FOLLOW ====================

  /// Get authentication token from SharedPreferences
  Future<String?> _getAuthToken() async {
    try {
      final secureToken = await _secureStorage.getAuthToken();
      if (secureToken != null && secureToken.isNotEmpty) {
        return secureToken;
      }

      // Fallback for legacy storage
      final prefs = await SharedPreferences.getInstance();
      final legacyToken = prefs.getString('auth_token');
      if (legacyToken != null && legacyToken.isNotEmpty) {
        return legacyToken;
      }

      return null;
    } catch (e) {
      print('❌ Error getting auth token: $e');
      return null;
    }
  }

  /// Follow a comic
  Future<Map<String, dynamic>> followComic({
    required String accountId,
    required String comicId,
  }) async {
    try {
      print('=== FollowService: Following comic $comicId ===');
      final uri = Uri.parse('$_baseUrl/Follow');
      print('🌐 Follow URL: $uri');

      final requestBody = {
        'accountId': accountId,
        'comicId': comicId,
      };

      print('📤 Request body: $requestBody');

      final token = await _getAuthToken();
      final headers = {
        'Accept': '*/*',
        'Content-Type': 'application/json',
        'User-Agent': 'demo-app/1.0 (flutter)',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final client = _createClient();
      final response = await client.post(
        uri,
        headers: headers,
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 15));
      client.close();

      print('📡 Follow response status: ${response.statusCode}');
      print('📏 Follow response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Follow successful');
        return {
          'success': true,
          'message': response.body.isEmpty ? 'Đã theo dõi truyện' : response.body,
        };
      } else {
        return {
          'success': false,
          'error': 'Không thể theo dõi truyện (HTTP ${response.statusCode})',
        };
      }
    } catch (e) {
      print('❌ Follow error: $e');
      return {
        'success': false,
        'error': 'Lỗi kết nối: $e',
      };
    }
  }

  // ==================== UNFOLLOW ====================

  /// Unfollow a comic
  Future<Map<String, dynamic>> unfollowComic({
    required String accountId,
    required String comicId,
  }) async {
    try {
      print('=== FollowService: Unfollowing comic $comicId ===');
      final uri = Uri.parse('$_baseUrl/Follow/$accountId/$comicId');
      print('🌐 Unfollow URL: $uri');

      final token = await _getAuthToken();
      final headers = {
        'Accept': '*/*',
        'User-Agent': 'demo-app/1.0 (flutter)',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final client = _createClient();
      final response = await client.delete(
        uri,
        headers: headers,
      ).timeout(const Duration(seconds: 15));
      client.close();

      print('📡 Unfollow response status: ${response.statusCode}');
      print('📏 Unfollow response body: ${response.body}');

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        print('✅ Unfollow successful');
        return {
          'success': true,
          'message': 'Đã hủy theo dõi',
        };
      } else {
        return {
          'success': false,
          'error': 'Không thể bỏ theo dõi truyện (HTTP ${response.statusCode})',
        };
      }
    } catch (e) {
      print('❌ Unfollow error: $e');
      return {
        'success': false,
        'error': 'Lỗi kết nối: $e',
      };
    }
  }

  // ==================== GET FOLLOWED COMICS ====================

  /// Get list of followed comics for a user
  Future<List<String>> getFollowedComics(String accountId) async {
    try {
      print('=== FollowService: Getting followed comics for account $accountId ===');
      final uri = Uri.parse('$_baseUrl/Follow/$accountId');
      print('🌐 Get Follow URL: $uri');

      final token = await _getAuthToken();
      final headers = {
        'Accept': '*/*',
        'User-Agent': 'demo-app/1.0 (flutter)',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final client = _createClient();
      final response = await client.get(
        uri,
        headers: headers,
      ).timeout(const Duration(seconds: 15));
      client.close();

      print('📡 Get Follow response status: ${response.statusCode}');
      print('📏 Get Follow response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final List<dynamic> followList = json.decode(response.body);
          final List<String> comicIds = followList
              .map((item) => item['comicId']?.toString() ?? '')
              .where((id) => id.isNotEmpty)
              .toList();

          print('✅ Successfully loaded ${comicIds.length} followed comics');
          return comicIds;
        } catch (parseError) {
          print('❌ JSON parse error: $parseError');
          return [];
        }
      } else {
        print('❌ Get Follow HTTP error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Get Follow network error: $e');
      return [];
    }
  }

  // ==================== SYNC ====================

  /// Sync follow list from server to local storage
  Future<void> syncFollowListFromServer(String? accountId) async {
    try {
      if (accountId == null) {
        print('❌ Cannot sync: No account ID');
        return;
      }

      print('🔄 Syncing follow list from server...');
      final comicIds = await getFollowedComics(accountId);

      if (comicIds.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final key = 'followed_comics_$accountId';
        await prefs.setStringList(key, comicIds);
        print('✅ Synced ${comicIds.length} comics to local storage');
      } else {
        print('ℹ️ No followed comics found on server');
      }
    } catch (e) {
      print('❌ Error syncing follow list: $e');
    }
  }

  // ==================== LOCAL STORAGE ====================

  /// Get account ID from user data
  Future<String?> getAccountId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataJson = prefs.getString('user_data');

      if (userDataJson != null) {
        final userData = json.decode(userDataJson);
        final accountId =
            userData['id']?.toString() ?? userData['accountId']?.toString();
        print('✅ Account ID: $accountId');
        return accountId;
      }

      print('❌ No user data found');
      return null;
    } catch (e) {
      print('❌ Error getting account ID: $e');
      return null;
    }
  }
}

