import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rentalkuy/models/booking_model.dart';
import 'package:rentalkuy/services/base_service.dart';

class BookingService extends BaseService {
  // Get all bookings (customer & admin)
  static Future<List<Booking>> getBookings(String token) async {
    final response = await http.get(
      Uri.parse('${BaseService.baseUrl}/api/booking'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Debugging untuk membantu developer
      print("📦 BookingService response type: ${data.runtimeType}");

      List<dynamic> rawList;

      // Cek tipe response
      if (data is List) {
        rawList = data;
      } else if (data is Map<String, dynamic>) {
        // Jika bentuk: { bookings: [...] }
        if (data.containsKey('bookings') && data['bookings'] is List) {
          rawList = data['bookings'];
        } else {
          // Kasus gagal
          throw Exception("Format respons booking tidak dikenali: $data");
        }
      } else {
        throw Exception("Data booking tidak berupa list: $data");
      }

      // Parsing setiap elemen
      final bookings = <Booking>[];
      for (var item in rawList) {
        try {
          final booking = Booking.fromJson(item);
          bookings.add(booking);
        } catch (e) {
          print("❌ Gagal parse 1 booking: $e\nData: $item");
          // Optional: lanjutkan atau hentikan
        }
      }

      return bookings;
    } else {
      try {
        final errorData = jsonDecode(response.body);
        final message = errorData['message'] ?? response.body;
        throw Exception('Gagal load bookings: $message');
      } catch (_) {
        throw Exception('Gagal load bookings: ${response.body}');
      }
    }
  }

  // Get booking by ID (parsing sesuai response backend terbaru)
  static Future<Booking> getBookingById(String token, int id) async {
    final response = await http.get(
      Uri.parse('${BaseService.baseUrl}/api/booking/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // --- Handle response sesuai struktur baru ---
      if (data is Map && data.containsKey('bookingId')) {
        final vehicle = data['vehicle'] ?? {};
        final schedule = data['schedule'] ?? {};
        final payment = data['payment'] ?? {};

        // Parse tanggal
        final startDatetime = BookingService.parseApiDate(
          schedule['startDate'] ?? '',
        );
        final endDatetime = BookingService.parseApiDate(
          schedule['endDate'] ?? '',
        );

        // Durasi
        final durationDays =
            schedule['durationDays'] is int
                ? schedule['durationDays']
                : int.tryParse(schedule['durationDays']?.toString() ?? '1') ??
                    1;

        // Total harga
        final pricePerDay = payment['pricePerDay'] ?? 0;
        final totalPrice =
            payment['totalPrice'] ?? (pricePerDay * durationDays);

        return Booking(
          id: data['bookingId'],
          vehicleUnitId: null, // Jika ada, isi sesuai field backend
          vehicle: {
            'name': vehicle['name'] ?? '',
            'type': vehicle['type'] ?? '',
            'unitCode': vehicle['unitCode'] ?? '',
            'hasImage': vehicle['hasImage'] ?? false,
          },
          vehicleUnit: {
            'code': vehicle['unitCode'] ?? '',
            'pricePerDay': pricePerDay,
            'id': null, // Jika ada id unit, isi di sini
            'hasImage': vehicle['hasImage'] ?? false,
          },
          startDatetime: startDatetime,
          endDatetime: endDatetime,
          status: BookingStatus.values.firstWhere(
            (e) =>
                e.toString().split('.').last ==
                (data['status'] ?? '').toLowerCase(),
            orElse: () => BookingStatus.pending,
          ),
          statusNote: data['statusNote'] ?? '',
          transactionId: payment['transactionId'],
          transaction: {
            'paymentStatus': payment['status'],
            'amount': totalPrice,
            'paymentImageUrl': payment['paymentImageUrl'],
            'method': payment['method'],
            'pricePerDay': pricePerDay,
            'totalPrice': totalPrice,
          },
          user: null,
          requestDate: null, // Jika ada createdAt, parse di sini
        );
      }

      // Fallback: jika response admin atau format lama
      if (data is Map &&
          (data.containsKey('id') || data.containsKey('bookingId'))) {
        return Booking.fromJson(Map<String, dynamic>.from(data));
      }

      throw Exception("Format respons booking tidak dikenali: $data");
    } else {
      try {
        final errorData = jsonDecode(response.body);
        final message = errorData['message'] ?? response.body;
        throw Exception('Gagal load booking: $message');
      } catch (_) {
        throw Exception('Gagal load booking: ${response.body}');
      }
    }
  }

  // Get bookings by status
  static Future<List<Booking>> getBookingsByStatus(
    String token,
    String status,
  ) async {
    final response = await http.get(
      Uri.parse('${BaseService.baseUrl}/api/booking/status/$status'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((json) => Booking.fromJson(json)).toList();
      }
      throw Exception('Unexpected response format');
    } else {
      throw Exception(
        'Failed to load bookings by status: ${response.statusCode}',
      );
    }
  }

  // Get bookings by vehicle unit ID
  static Future<List<Booking>> getBookingsByVehicleUnit(
    String token,
    int vehicleUnitId,
  ) async {
    final response = await http.get(
      Uri.parse('${BaseService.baseUrl}/api/booking/vehicle/$vehicleUnitId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((json) => Booking.fromJson(json)).toList();
      }
      throw Exception('Unexpected response format');
    } else {
      throw Exception(
        'Failed to load bookings by vehicle: ${response.statusCode}',
      );
    }
  }

  // Create a new booking
  static Future<Booking> createBooking(
    String token,
    int vehicleUnitId,
    String startDate,
    String endDate, {
    String? note,
  }) async {
    final Map<String, dynamic> requestData = {
      'vehicleUnitId': vehicleUnitId,
      'startDate': startDate,
      'endDate': endDate,
    };
    if (note != null) requestData['note'] = note;

    final response = await http.post(
      Uri.parse('${BaseService.baseUrl}/api/booking'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestData),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      // If response is wrapped, unwrap
      if (data is Map && data.containsKey('booking')) {
        return Booking.fromJson(data['booking']);
      }
      return Booking.fromJson(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to create booking');
    }
  }

  // Reject booking (admin or system)
  static Future<bool> rejectBooking(
    String token,
    int bookingId, {
    String reason = "Ditolak oleh admin",
  }) async {
    final response = await http.patch(
      Uri.parse('${BaseService.baseUrl}/api/booking/$bookingId/reject'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'reason': reason}),
    );
    return response.statusCode == 200;
  }

  // Reject booking by admin
  static Future<bool> rejectBookingByAdmin(
    String token,
    int bookingId,
    String reason, {
    String? paymentStatus,
  }) async {
    final Map<String, dynamic> body = {'reason': reason};
    if (paymentStatus != null) {
      body['paymentStatus'] = paymentStatus;
    }

    final response = await http.patch(
      Uri.parse('${BaseService.baseUrl}/api/booking/$bookingId/reject'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    return response.statusCode == 200;
  }

  // Approve booking (admin only)
  static Future<bool> approveBooking(String token, int bookingId) async {
    final response = await http.put(
      Uri.parse('${BaseService.baseUrl}/api/admin/bookings/$bookingId/approve'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      return true;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Gagal menyetujui booking');
    }
  }

  // Start booking (ubah status menjadi on_going)
  static Future<bool> startBooking(String token, int bookingId) async {
    final response = await http.post(
      Uri.parse('${BaseService.baseUrl}/api/booking/$bookingId/start'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      return true;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Gagal memulai booking');
    }
  }

  // PERBAIKAN: Fungsi universalDateFormat menjadi UTC-safe
  static DateTime parseApiDate(String dateStr) {
    if (dateStr.isEmpty) return DateTime.now().toUtc();

    // Format YYYYMMDD - PERBAIKAN: Gunakan DateTime.utc
    if (dateStr.length == 8) {
      try {
        return DateTime.utc(
          int.parse(dateStr.substring(0, 4)), // year
          int.parse(dateStr.substring(4, 6)), // month
          int.parse(dateStr.substring(6, 8)), // day
          12,
          0,
          0, // noon UTC untuk hindari pergeseran hari
        );
      } catch (e) {
        print("Error parsing date $dateStr: $e");
        return DateTime.now().toUtc();
      }
    }

    // Default parsing
    try {
      final parsed = DateTime.parse(dateStr);
      // Jika bukan UTC, konversi ke UTC dengan mempertahankan tanggal
      if (!parsed.isUtc) {
        return DateTime.utc(parsed.year, parsed.month, parsed.day, 12, 0, 0);
      }
      return parsed;
    } catch (e) {
      print("Error parsing date $dateStr: $e");
      return DateTime.now().toUtc();
    }
  }
}
