import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:rentalkuy/models/user_model.dart';
import 'package:rentalkuy/services/base_service.dart';

class ProfileService extends BaseService {
  // Get user profile
  static Future<User> getProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${BaseService.baseUrl}/api/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching profile: $e');
    }
  }

  // Update profile
  static Future<bool> updateProfile(String token, String name) async {
    try {
      final response = await http.put(
        Uri.parse('${BaseService.baseUrl}/api/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'name': name}),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  // Upload KTP image - PERBAIKAN
  static Future<bool> uploadKtpImage(String token, Uint8List imageBytes) async {
    try {
      // Buat instance Dio baru khusus untuk request ini
      final dio = Dio();
      dio.options.headers['Authorization'] = 'Bearer $token';
      dio.options.headers['Accept'] = '*/*';

      // Buat form data dengan nama field yang benar
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          imageBytes,
          filename: 'ktp.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      });

      if (BaseService.debugMode) {
        print(
          '📤 Uploading KTP to: ${BaseService.baseUrl}/api/profile/upload-ktp',
        );
      }

      final response = await dio.post(
        '${BaseService.baseUrl}/api/profile/upload-ktp',
        data: formData,
      );

      // Status code 2xx berarti OK
      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
    } catch (e) {
      if (BaseService.debugMode) {
        print('❌ KTP upload error: $e');
      }
      throw Exception('Error uploading KTP image: $e');
    }
  }

  // Upload SIM image - PERBAIKAN
  static Future<bool> uploadSimImage(String token, Uint8List imageBytes) async {
    try {
      // Buat instance Dio baru khusus untuk request ini
      final dio = Dio();
      dio.options.headers['Authorization'] = 'Bearer $token';
      dio.options.headers['Accept'] = '*/*';

      // Buat form data dengan nama field yang benar
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          imageBytes,
          filename: 'sim.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      });

      if (BaseService.debugMode) {
        print(
          '📤 Uploading SIM to: ${BaseService.baseUrl}/api/profile/upload-sim',
        );
      }

      final response = await dio.post(
        '${BaseService.baseUrl}/api/profile/upload-sim',
        data: formData,
      );

      // Status code 2xx berarti OK
      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
    } catch (e) {
      if (BaseService.debugMode) {
        print('❌ SIM upload error: $e');
      }
      throw Exception('Error uploading SIM image: $e');
    }
  }

  // Upload profile image - PERBAIKAN
  static Future<bool> uploadProfileImage(
    String token,
    Uint8List imageBytes,
  ) async {
    try {
      // Buat instance Dio baru khusus untuk request ini
      final dio = Dio();
      dio.options.headers['Authorization'] = 'Bearer $token';
      dio.options.headers['Accept'] = '*/*';

      // Buat form data dengan nama field yang benar
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          imageBytes,
          filename: 'profile.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      });

      if (BaseService.debugMode) {
        print(
          '📤 Uploading Profile to: ${BaseService.baseUrl}/api/profile/upload-profile',
        );
      }

      final response = await dio.post(
        '${BaseService.baseUrl}/api/profile/upload-profile',
        data: formData,
      );

      // Status code 2xx berarti OK
      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
    } catch (e) {
      if (BaseService.debugMode) {
        print('❌ Profile upload error: $e');
      }
      throw Exception('Error uploading profile image: $e');
    }
  }

  // Get KTP image URL
  static String getKtpImageUrl() {
    return '${BaseService.baseUrl}/api/profile/ktp';
  }

  // Get SIM image URL
  static String getSimImageUrl() {
    return '${BaseService.baseUrl}/api/profile/sim';
  }

  // Get profile image URL
  static String getProfileImageUrl() {
    return '${BaseService.baseUrl}/api/profile/profile-image';
  }

  // Get verification status
  static Future<Map<String, dynamic>> getVerificationStatus(
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${BaseService.baseUrl}/api/profile/verification-status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to get verification status: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching verification status: $e');
    }
  }
}
