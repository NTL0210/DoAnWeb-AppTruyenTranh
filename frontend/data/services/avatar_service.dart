import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../utils/dio_helper.dart';

/// Avatar service
/// Handles avatar upload and username updates
class AvatarService {
  static const String _baseUrl =
      'https://cytostomal-nonsubtractive-bryanna.ngrok-free.dev/api';

  final SecureStorageService _secureStorage = SecureStorageService();

  // ==================== AVATAR UPLOAD ====================

  /// Upload avatar with optional username update
  Future<Map<String, dynamic>> uploadAvatar(
    String imagePath,
    String userName,
  ) async {
    try {
      print('📤 Uploading avatar: $imagePath for user: $userName');

      final token = await _secureStorage.getAuthToken();
      if (token == null || token.isEmpty) {
        print('❌ No auth token found');
        return {
          'success': false,
          'error': 'Bạn cần đăng nhập để thực hiện chức năng này',
        };
      }

      print('🔑 Using auth token: ${token.substring(0, 20)}...');

      final formData = FormData.fromMap({
        'UserName': userName,
        'ImageFile': await MultipartFile.fromFile(
          imagePath,
          filename: 'avatar.jpg',
        ),
      });

      print('📤 Uploading to: $_baseUrl/Auth/upload-avatar');
      print('📝 UserName: $userName');

      final response = await DioHelper.createDio().post(
        '$_baseUrl/Auth/upload-avatar',
        data: formData,
        options: Options(
          headers: {
            'accept': '*/*',
            'Content-Type': 'multipart/form-data',
            'Authorization': 'Bearer $token',
          },
          validateStatus: (status) {
            print('📡 Response status: $status');
            return status != null && status < 500;
          },
        ),
      );

      if (response.statusCode == 200) {
        print('✅ Avatar uploaded successfully');
        print('📦 Response: ${response.data}');
        return {
          'success': true,
          'message': response.data['message'] ?? 'Avatar uploaded successfully',
          'data': response.data,
          'image': response.data['image'],
          'userName': response.data['userName'],
        };
      } else if (response.statusCode == 401) {
        print('❌ Upload failed: 401 Unauthorized');
        print('📏 Response body: ${response.data}');
        return {
          'success': false,
          'error': 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
        };
      } else {
        print('❌ Upload failed: ${response.statusCode}');
        print('📏 Response body: ${response.data}');
        return {
          'success': false,
          'error': 'Upload failed: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Upload error: $e');
      return {
        'success': false,
        'error': 'Upload failed: $e',
      };
    }
  }

  // ==================== UPDATE USERNAME ONLY ====================

  /// Update username without changing avatar
  Future<Map<String, dynamic>> updateUsernameOnly(String newUserName) async {
    try {
      print('📝 Updating username to: $newUserName');

      final token = await _secureStorage.getAuthToken();
      if (token == null || token.isEmpty) {
        print('❌ No auth token found');
        return {
          'success': false,
          'error': 'Bạn cần đăng nhập để thực hiện chức năng này',
        };
      }

      final formData = FormData.fromMap({
        'UserName': newUserName,
      });

      final response = await DioHelper.createDio().post(
        '$_baseUrl/Auth/upload-avatar',
        data: formData,
        options: Options(
          headers: {
            'accept': '*/*',
            'Content-Type': 'multipart/form-data',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        print('✅ Username updated successfully');
        print('📦 Response: ${response.data}');
        return {
          'success': true,
          'message': response.data['message'] ?? 'Cập nhật username thành công',
          'userName': response.data['userName'],
          'image': response.data['image'],
        };
      } else {
        print('❌ Update failed: ${response.statusCode}');
        return {
          'success': false,
          'error': 'Update failed: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Update error: $e');
      return {
        'success': false,
        'error': 'Lỗi: $e',
      };
    }
  }

  // ==================== VALIDATION ====================

  /// Validate image file
  bool validateImage(String imagePath) {
    final file = File(imagePath);
    if (!file.existsSync()) {
      print('❌ Image file does not exist');
      return false;
    }

    // Check file size (max 5MB)
    final fileSize = file.lengthSync();
    if (fileSize > 5 * 1024 * 1024) {
      print('❌ Image too large: ${fileSize / 1024 / 1024}MB');
      return false;
    }

    // Check file extension
    final extension = imagePath.toLowerCase().split('.').last;
    final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    if (!allowedExtensions.contains(extension)) {
      print('❌ Invalid file extension: $extension');
      return false;
    }

    print('✅ Image validation passed');
    return true;
  }
}

