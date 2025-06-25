import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class BaseService {
  // Debug mode flag for detailed logging
  static bool debugMode = true;

  // Get base URL with platform-specific considerations
  static String get baseUrl {
    // PERBAIKAN: Gunakan IP yang berbeda untuk emulator dan perangkat fisik
    String actualUrl;

    if (kIsWeb) {
      actualUrl = 'http://localhost:5165';
    } else if (Platform.isAndroid) {
      // Selalu gunakan format URL lengkap dengan http://
      actualUrl = 'http://10.0.2.2:5165'; // Default untuk emulator

      // Fallback ke IP alternatif jika diperlukan
      if (debugMode) {
        try {
          // Alternatif untuk perangkat fisik atau emulator non-standard
          actualUrl = 'http://172.20.10.3:5165';
        } catch (e) {
          print('Fallback to alternative IP: $e');
        }
      }
    } else {
      // iOS dan platform lain
      actualUrl = 'http://192.168.18.65:5165';
    }

    // Log network information when in debug mode
    if (debugMode) {
      print('🌐 API URL: $actualUrl');
      print('📱 Platform: ${Platform.operatingSystem}');
    }

    return actualUrl;
  }

  // Configure Dio with timeout
  static final Dio dio =
      Dio()
        ..options.connectTimeout = const Duration(seconds: 15)
        ..options.receiveTimeout = const Duration(seconds: 15)
        ..interceptors.add(
          LogInterceptor(
            requestBody: debugMode,
            responseBody: debugMode,
            error: debugMode,
            request: debugMode,
          ),
        );

  // Metode helper untuk menambahkan token ke headers
  static Map<String, String> getAuthHeaders(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  static void logRequest(
    String method,
    String url,
    Map<String, dynamic>? params,
  ) {
    if (!debugMode) return;

    print('🚀 API REQUEST: $method $url');
    if (params != null) {
      print('📦 PARAMS: ${jsonEncode(params)}');
    }
  }

  static void logResponse(String url, int statusCode, dynamic body) {
    if (!debugMode) return;

    print('✅ API RESPONSE: $url');
    print('📊 STATUS: $statusCode');
    if (body != null) {
      print('📄 BODY: ${body is String ? body : jsonEncode(body)}');
    }
  }

  static void logError(String url, dynamic error) {
    if (!debugMode) return;

    print('❌ API ERROR: $url');
    print('💥 ERROR: $error');
    if (error is DioException && error.response != null) {
      print('📄 RESPONSE: ${error.response?.data}');
    }
  }

  // Perbaikan: Tambahkan metode standar untuk menangani respons
  static T handleResponse<T>(
    http.Response response,
    T Function(dynamic data) parser, {
    String errorPrefix = 'Failed to process request',
  }) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final data = jsonDecode(response.body);
        return parser(data);
      } catch (e) {
        throw Exception('$errorPrefix: Invalid response format - $e');
      }
    } else if (response.statusCode == 401) {
      throw Exception('$errorPrefix: Unauthorized access');
    } else if (response.statusCode == 403) {
      throw Exception('$errorPrefix: Access forbidden');
    } else if (response.statusCode == 404) {
      throw Exception('$errorPrefix: Resource not found');
    } else {
      throw Exception('$errorPrefix: Status ${response.statusCode}');
    }
  }

  static Future<T> withRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    int attempt = 0;
    while (attempt < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) rethrow;
        await Future.delayed(retryDelay);
      }
    }
    throw Exception('Max retries exceeded');
  }
}
