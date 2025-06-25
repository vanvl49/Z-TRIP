import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart' as dio;
import 'package:http_parser/http_parser.dart';
import 'package:rentalkuy/services/base_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';

class AuthService extends BaseService {
  /// Register user (email, name, password, profile image optional)
  static Future<http.Response> register({
    required String email,
    required String name,
    required String password,
    Uint8List? profileImageBytes,
  }) async {
    try {
      final formData = dio.FormData.fromMap({
        'email': email,
        'name': name,
        'password': password,
        if (profileImageBytes != null)
          'ProfileImage': dio.MultipartFile.fromBytes(
            profileImageBytes,
            filename: 'profile.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
      });

      final dioResponse = await BaseService.dio.post(
        '${BaseService.baseUrl}/api/auth/register',
        data: formData,
      );

      return http.Response(
        jsonEncode(dioResponse.data),
        dioResponse.statusCode ?? 500,
        headers: {'content-type': 'application/json'},
      );
    } on dio.DioException catch (e) {
      // Log error detail
      print('❌ Register error response: ${e.response?.data}');
      final message =
          e.response?.data?['message'] ?? 'Terjadi kesalahan saat register';
      throw Exception(message);
    } catch (e) {
      throw Exception('Error registering: $e');
    }
  }

  /// Login user
  static Future<http.Response> login(String email, String password) async {
    try {
      if (BaseService.debugMode) {
        print('🔐 Attempting login to: ${BaseService.baseUrl}/api/auth/login');
      }

      final response = await http
          .post(
            Uri.parse('${BaseService.baseUrl}/api/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      if (BaseService.debugMode) {
        print('📡 Gagal terhubung dengan server');
      }
      return response;
    } on TimeoutException {
      throw Exception('Koneksi timeout. Silakan coba lagi nanti.');
    } catch (e) {
      throw Exception('Error logging in: $e');
    }
  }
}

class AuthController extends GetxController {
  Rx<Uint8List?> profileImageBytes = Rx<Uint8List?>(null);

  // Pilih dari kamera
  Future<void> pickProfileImageFromCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (image != null) {
      profileImageBytes.value = await image.readAsBytes();
    }
  }

  // Pilih dari galeri
  Future<void> pickProfileImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (image != null) {
      profileImageBytes.value = await image.readAsBytes();
    }
  }
}
