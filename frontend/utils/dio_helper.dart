import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

/// Helper class for creating Dio instances with environment-specific SSL configuration.
/// 
/// In development mode, SSL certificate verification is bypassed to allow connections
/// to servers with self-signed certificates. In production mode, full SSL verification
/// is enforced for security.
class DioHelper {
  /// Creates a Dio instance configured for the current environment.
  /// 
  /// - In development (kDebugMode = true): Returns Dio with SSL bypass enabled
  /// - In production (kDebugMode = false): Returns Dio with full SSL verification
  /// 
  /// Returns a [Dio] instance configured appropriately for the environment.
  static Dio createDio() {
    final dio = Dio();
    
    if (kDebugMode) {
      // Development mode: bypass SSL certificate verification
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.badCertificateCallback = (X509Certificate cert, String host, int port) {
            if (kDebugMode) {
              print('⚠️ SSL Certificate verification bypassed for Dio in development');
            }
            return true;
          };
          return client;
        },
      );
    }
    // Production mode: use default Dio configuration with SSL verification
    
    return dio;
  }
}
