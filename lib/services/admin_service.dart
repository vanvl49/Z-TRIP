import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rentalkuy/models/user_model.dart';
import 'package:rentalkuy/models/booking_model.dart';
import 'package:rentalkuy/services/base_service.dart';

class AdminService extends BaseService {
  // Metode untuk memudahkan parsing response
  static T _parseResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic> data) parser, {
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
      throw Exception('$errorPrefix: ${response.statusCode}');
    }
  }

  // Tambahkan helper method untuk standardisasi error handling
  static Future<T> _executeRequest<T>(
    Future<http.Response> request,
    T Function(http.Response response) handler, {
    String errorPrefix = 'Request failed',
  }) async {
    try {
      final response = await request.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Connection timeout. Please try again later.');
        },
      );
      return handler(response);
    } on TimeoutException catch (e) {
      throw Exception('$errorPrefix: Connection timeout: $e');
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('$errorPrefix: $e');
    }
  }

  // Tambahkan debugging helper untuk request/response
  static void _logRequest(
    String method,
    String url,
    Map<String, String> headers,
  ) {
    if (BaseService.debugMode) {
      print('🔶 REQUEST: $method $url');
      print('🔶 HEADERS: $headers');
    }
  }

  static void _logResponse(http.Response response) {
    if (BaseService.debugMode) {
      print('🔷 RESPONSE: ${response.statusCode}');
      print(
        '🔷 BODY: ${response.body.substring(0, response.body.length < 500 ? response.body.length : 500)}...',
      );
    }
  }

  // Get all customers (admin only)
  static Future<List<User>> getAllCustomers(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${BaseService.baseUrl}/api/admin/customers'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // PERBAIKAN: Cek apakah data memiliki property 'customers'
        if (data is Map && data.containsKey('customers')) {
          final List<dynamic> customers = data['customers'];
          return customers.map((json) => User.fromJson(json)).toList();
        } else if (data is List) {
          // Fallback jika response langsung berupa array
          return data.map((json) => User.fromJson(json)).toList();
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception('Failed to load customers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching customers: $e');
    }
  }

  // Get customer by ID (admin only)
  static Future<User> getCustomerById(String token, int id) async {
    try {
      final response = await http.get(
        Uri.parse('${BaseService.baseUrl}/api/admin/customers/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // Gunakan helper method untuk konsistensi
      return _parseResponse(
        response,
        (data) => User.fromJson(data),
        errorPrefix: 'Failed to load customer',
      );
    } catch (e) {
      throw Exception('Error fetching customer: $e');
    }
  }

  // Get KTP image URL for customer (admin only)
  static String getCustomerKtpImageUrl(int customerId) {
    return '${BaseService.baseUrl}/api/admin/customers/$customerId/ktp';
  }

  // Get SIM image URL for customer (admin only)
  static String getCustomerSimImageUrl(int customerId) {
    return '${BaseService.baseUrl}/api/admin/customers/$customerId/sim';
  }

  // Get profile image URL for customer (admin only)
  static String getCustomerProfileImageUrl(int customerId) {
    return '${BaseService.baseUrl}/api/admin/customers/$customerId/profile-image';
  }

  // Verify customer (admin only)
  static Future<bool> verifyCustomer(String token, int userId) async {
    try {
      final response = await http.put(
        Uri.parse('${BaseService.baseUrl}/api/admin/customers/$userId/verify'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 400) {
        // Menangani validasi error
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Validation error';
        throw Exception(
          errorMessage,
        ); // Contoh: "Customer belum mengupload KTP"
      } else if (response.statusCode == 404) {
        throw Exception('User tidak ditemukan');
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Akses ditolak: Anda tidak memiliki hak akses');
      } else {
        throw Exception(
          'Error verifying customer: Status ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow; // Rethrow exception yang sudah diformat
      }
      throw Exception('Error verifying customer: $e');
    }
  }

  // Get all bookings (admin only)
  static Future<List<Booking>> getAllBookings(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('${BaseService.baseUrl}/api/admin/bookings'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException(
                'Connection timeout. Please try again later.',
              );
            },
          );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Booking.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load bookings: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      throw Exception('Connection timeout: $e');
    } catch (e) {
      throw Exception('Error fetching bookings: $e');
    }
  }

  // Get pending bookings (admin only)
  static Future<List<Booking>> getPendingBookings(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${BaseService.baseUrl}/api/admin/bookings/pending'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Booking.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load pending bookings: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching pending bookings: $e');
    }
  }

  // Approve booking (admin only)
  static Future<bool> approveBooking(String token, int bookingId) async {
    try {
      final response = await http.put(
        Uri.parse(
          '${BaseService.baseUrl}/api/admin/bookings/$bookingId/approve',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? 'Booking sudah diproses sebelumnya',
        );
      } else if (response.statusCode == 404) {
        throw Exception('Booking tidak ditemukan');
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Akses ditolak: Anda tidak memiliki hak akses');
      } else {
        throw Exception(
          'Error approving booking: Status ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Error approving booking: $e');
    }
  }

  // Reject booking (admin only)
  static Future<bool> rejectBooking(
    String token,
    int bookingId,
    String statusNote,
  ) async {
    try {
      // PERBAIKAN: Validasi parameter
      if (statusNote.isEmpty) {
        throw Exception('Alasan penolakan (statusNote) tidak boleh kosong');
      }

      final response = await http.put(
        Uri.parse(
          '${BaseService.baseUrl}/api/admin/bookings/$bookingId/reject',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        // PERBAIKAN: Memastikan nama properti sesuai dengan yang diharapkan API
        body: jsonEncode({'statusNote': statusNote}),
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Validation error');
      } else if (response.statusCode == 404) {
        throw Exception('Booking tidak ditemukan');
      } else {
        throw Exception('Error rejecting booking: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Error rejecting booking: $e');
    }
  }

  // Get active bookings (admin only)
  static Future<List<Booking>> getActiveBookings(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${BaseService.baseUrl}/api/admin/active-bookings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Booking.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load active bookings: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching active bookings: $e');
    }
  }

  // Get customers needing verification (admin only)
  static Future<List<User>> getCustomersNeedingVerification(
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${BaseService.baseUrl}/api/admin/customers/verification-needed',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // PERBAIKAN: Handle berbagai format response yang mungkin
        if (data is Map) {
          if (data.containsKey('customers')) {
            final List<dynamic> customers = data['customers'];
            return customers.map((json) => User.fromJson(json)).toList();
          } else if (data.containsKey('data')) {
            final List<dynamic> customers = data['data'];
            return customers.map((json) => User.fromJson(json)).toList();
          }
        } else if (data is List) {
          return data.map((json) => User.fromJson(json)).toList();
        }

        throw Exception('Unexpected response format');
      } else {
        throw Exception(
          'Failed to load customers needing verification: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching customers needing verification: $e');
    }
  }
}
