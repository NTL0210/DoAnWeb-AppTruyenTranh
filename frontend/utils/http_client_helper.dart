import 'dart:io';
import 'package:flutter/foundation.dart';

/// Helper class for creating HttpClient instances with environment-specific SSL configuration.
/// 
/// In development mode, SSL certificate verification is bypassed to allow connections
/// to servers with self-signed certificates. In production mode, full SSL verification
/// is enforced for security.
class HttpClientHelper {
  /// Creates an HttpClient configured for the current environment.
  /// 
  /// - In development (kDebugMode = true): Returns HttpClient with SSL bypass enabled
  /// - In production (kDebugMode = false): Returns HttpClient with full SSL verification
  /// 
  /// Returns an [HttpClient] instance configured appropriately for the environment.
  static HttpClient createHttpClient() {
    final client = HttpClient();
    
    // HttpClient automatically follows redirects by default, including HTTP 307 redirects that preserve the request method and body
    
    if (kDebugMode) {
      // Development mode: bypass SSL certificate verification
      // This callback applies to ALL hosts, including redirected HTTPS URLs
      client.badCertificateCallback = (X509Certificate cert, String host, int port) {
        if (kDebugMode) {
          print('⚠️ SSL Certificate verification bypassed for development (host: $host:$port)');
        }
        return true;
      };
    }
    // Production mode: use default SSL verification (no callback needed)
    
    return client;
  }
}
