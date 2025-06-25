import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rentalkuy/services/base_service.dart';

class PasswordResetService extends BaseService {
  // Step 1: Request reset password (kirim email)
  static Future<bool> requestPasswordReset(String email) async {
    final url = '${BaseService.baseUrl}/api/password-reset/request';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode == 200) return true;
    final data = jsonDecode(response.body);
    throw Exception(data['message'] ?? 'Gagal mengirim permintaan reset');
  }

  // Step 2: Verifikasi OTP
  static Future<String?> verifyOTP(String email, String otp) async {
    final url = '${BaseService.baseUrl}/api/password-reset/verify-otp';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['reset_token'];
    }
    final data = jsonDecode(response.body);
    throw Exception(data['message'] ?? 'OTP salah atau expired');
  }

  // Step 3: Reset password
  static Future<bool> resetPassword(
    String email,
    String resetToken,
    String newPassword,
    String confirmPassword,
  ) async {
    final url = '${BaseService.baseUrl}/api/password-reset/reset';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'resetToken': resetToken,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      }),
    );
    if (response.statusCode == 200) return true;
    final data = jsonDecode(response.body);
    throw Exception(data['message'] ?? 'Gagal reset password');
  }
}
