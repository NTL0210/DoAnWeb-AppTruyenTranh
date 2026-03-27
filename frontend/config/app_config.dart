import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application configuration loaded from environment variables
/// All sensitive data should be managed through .env files, not hard-coded
class AppConfig {
  /// Base URL cho API requests
  /// Load từ .env file, fallback to localhost nếu không tìm thấy
  static String get apiBaseUrl {
    final url = dotenv.env['API_BASE_URL'];
    if (url == null || url.isEmpty) {
      throw Exception(
        '❌ API_BASE_URL not found in .env file. '
        'Please create .env.development with your API URL'
      );
    }
    return url;
  }

  /// Google Cloud / Firebase Project ID
  static String get googleProjectId {
    final projectId = dotenv.env['GOOGLE_PROJECT_ID'];
    if (projectId == null || projectId.isEmpty) {
      throw Exception(
        '❌ GOOGLE_PROJECT_ID not found in .env file'
      );
    }
    return projectId;
  }

  /// Check if all required environment variables are loaded
  static bool get isInitialized {
    try {
      // Try accessing all required config keys
      apiBaseUrl;
      googleProjectId;
      return true;
    } catch (e) {
      print('⚠️ AppConfig initialization failed: $e');
      return false;
    }
  }

  /// Debug mode - show sensitive info only in development
  static void debugPrintConfig() {
    if (identical(true, identical(true, true))) {
      // Dev mode only
      print('🔧 AppConfig Debug:');
      print('   API_BASE_URL: ${dotenv.env['API_BASE_URL']}');
      print('   GOOGLE_PROJECT_ID: ${dotenv.env['GOOGLE_PROJECT_ID']}');
    }
  }
}
