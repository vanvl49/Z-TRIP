import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:rentalkuy/models/transaction_model.dart';
import 'package:rentalkuy/services/base_service.dart';

class TransactionService extends BaseService {
  // Get all transactions
  static Future<List<Transaction>> getTransactions(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${BaseService.baseUrl}/api/transaksi'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Transaction.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load transactions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching transactions: $e');
    }
  }

  // Get transaction by ID
  static Future<Transaction> getTransactionById(String token, int id) async {
    try {
      final response = await http.get(
        Uri.parse('${BaseService.baseUrl}/api/transaksi/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return Transaction.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load transaction: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching transaction: $e');
    }
  }

  // Get payment image URL
  static String getPaymentImageUrl(int transactionId) {
    return '${BaseService.baseUrl}/api/transaksi/payment-image/$transactionId';
  }

  // Upload payment proof
  static Future<bool> uploadPaymentProof(
    String token,
    int transactionId,
    Uint8List imageBytes,
  ) async {
    try {
      print('📤 Memulai upload bukti pembayaran untuk transaksi $transactionId');
      print('📤 Ukuran gambar: ${imageBytes.length} bytes');

      // Gunakan Dio yang lebih handal untuk upload
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          imageBytes,
          filename: 'payment.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      });

      // Tambahkan logging
      print(
          '📤 Mengirim request ke: ${BaseService.baseUrl}/api/transaksi/upload-payment/$transactionId');

      final response = await BaseService.dio.post(
        '${BaseService.baseUrl}/api/transaksi/upload-payment/$transactionId',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      // Log hasil response
      print('📥 Response status: ${response.statusCode}');
      print('📥 Response data: ${response.data}');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      // Log error secara detail
      print('❌ Error upload bukti pembayaran: $e');

      if (e is DioException) {
        print('❌ Dio error type: ${e.type}');
        if (e.response != null) {
          print('❌ Error status: ${e.response!.statusCode}');
          print('❌ Error response: ${e.response!.data}');

          if (e.response!.statusCode == 400) {
            throw Exception('File tidak valid atau terlalu besar');
          } else if (e.response!.statusCode == 401) {
            throw Exception('Tidak diizinkan mengakses transaksi ini');
          } else if (e.response!.statusCode == 404) {
            throw Exception('Transaksi tidak ditemukan');
          }
        } else if (e.type == DioExceptionType.connectionTimeout) {
          throw Exception('Koneksi timeout, periksa jaringan Anda');
        }
      }
      throw Exception('Error mengupload bukti pembayaran: $e');
    }
  }

  // Get unpaid transactions
  static Future<List<Transaction>> getUnpaidTransactions(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${BaseService.baseUrl}/api/transaksi/unpaid'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Transaction.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load unpaid transactions: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching unpaid transactions: $e');
    }
  }

  // Approve payment (admin only)
  static Future<bool> approvePayment(String token, int transactionId) async {
    try {
      final response = await http.post(
        Uri.parse(
          '${BaseService.baseUrl}/api/transaksi/$transactionId/approve-payment',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error approving payment: $e');
    }
  }

  // Reject payment (admin only)
  static Future<bool> rejectPayment(
    String token,
    int transactionId,
    String reason,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(
          '${BaseService.baseUrl}/api/transaksi/$transactionId/reject-payment',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'reason': reason}),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error rejecting payment: $e');
    }
  }

  // Update payment status (admin only)
  static Future<bool> updatePaymentStatus(
    String token,
    int transactionId,
    String status,
  ) async {
    try {
      final response = await http.put(
        Uri.parse(
          '${BaseService.baseUrl}/api/transaksi/$transactionId/update-status',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': status}),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error updating payment status: $e');
    }
  }
}
