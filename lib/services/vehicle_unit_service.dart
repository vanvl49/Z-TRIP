import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:rentalkuy/models/vehicle_unit_model.dart';
import 'package:rentalkuy/services/base_service.dart';

class VehicleUnitService extends BaseService {
  // Get all vehicle units
  static Future<List<VehicleUnit>> fetchVehicleUnits(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${BaseService.baseUrl}/api/vehicle-units'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // PERBAIKAN: Cek struktur response yang benar
        final dynamic data = jsonDecode(response.body);
        if (data is List) {
          return data.map((json) => VehicleUnit.fromJson(json)).toList();
        } else if (data is Map && data.containsKey('data')) {
          final List<dynamic> listData = data['data'];
          return listData.map((json) => VehicleUnit.fromJson(json)).toList();
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception('Failed to load vehicle units: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching vehicle units: $e');
    }
  }

  // Get vehicle unit by ID
  static Future<VehicleUnit> fetchVehicleUnitById(String token, int id) async {
    try {
      final response = await http.get(
        Uri.parse('${BaseService.baseUrl}/api/vehicle-units/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return VehicleUnit.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load vehicle unit: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching vehicle unit: $e');
    }
  }

  // Get vehicle image URL
  static String getVehicleImageUrl(int unitId) {
    return '${BaseService.baseUrl}/api/vehicle-units/image/$unitId';
  }

  // Add a new vehicle unit (admin only)
  static Future<bool> addVehicleUnit(
    String token, {
    required String code,
    required int vehicleId,
    required double pricePerDay,
    String? description,
    Uint8List? imageBytes,
  }) async {
    try {
      final formData = FormData.fromMap({
        'Code': code,
        'VehicleId': vehicleId,
        'PricePerDay': pricePerDay,
        if (description != null) 'Description': description,
        if (imageBytes != null)
          'Image': MultipartFile.fromBytes(
            imageBytes,
            filename: 'vehicle.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
      });

      final response = await BaseService.dio.post(
        '${BaseService.baseUrl}/api/vehicle-units',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        // Tangkap pesan error dari backend jika ada
        String msg = 'Gagal menambahkan unit kendaraan';
        if (response.data is Map && response.data['message'] != null) {
          msg = response.data['message'];
        }
        throw Exception(msg);
      }
    } on DioException catch (e) {
      // Tangkap error validasi dari backend
      String msg = 'Gagal menambahkan unit kendaraan';
      if (e.response != null && e.response?.data != null) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          msg = data['message'];
        } else if (data is String) {
          msg = data;
        }
      }
      throw Exception(msg);
    } catch (e) {
      throw Exception('Error adding vehicle unit: $e');
    }
  }

  // Update vehicle unit (admin only)
  static Future<bool> updateVehicleUnit(
    String token,
    int id, {
    required String code,
    required int vehicleId,
    required double pricePerDay,
    String? description,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${BaseService.baseUrl}/api/vehicle-units/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'code': code,
          'vehicleId': vehicleId,
          'pricePerDay': pricePerDay,
          'description': description,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error updating vehicle unit: $e');
    }
  }

  // Upload vehicle image (admin only)
  static Future<bool> uploadVehicleImage(
    String token,
    int unitId,
    Uint8List imageBytes,
  ) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(imageBytes, filename: 'vehicle.jpg'),
      });

      final response = await BaseService.dio.post(
        '${BaseService.baseUrl}/api/vehicle-units/upload-image/$unitId',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error uploading vehicle image: $e');
    }
  }

  // Delete vehicle image (admin only)
  static Future<bool> deleteVehicleImage(String token, int unitId) async {
    try {
      final response = await http.delete(
        Uri.parse('${BaseService.baseUrl}/api/vehicle-units/image/$unitId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error deleting vehicle image: $e');
    }
  }

  // Delete vehicle unit (admin only)
  static Future<bool> deleteVehicleUnit(String token, int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${BaseService.baseUrl}/api/vehicle-units/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error deleting vehicle unit: $e');
    }
  }

  // Check if vehicle unit has bookings
  static Future<bool> hasVehicleUnitBookings(String token, int unitId) async {
    try {
      // Menggunakan endpoint dari BookingController untuk mendapatkan booking berdasarkan vehicle unit
      final response = await http.get(
        Uri.parse('${BaseService.baseUrl}/api/booking/vehicle/$unitId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (BaseService.debugMode) {
        print('🔍 Checking bookings for vehicle unit: $unitId');
        print('🔍 Status code: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final List<dynamic> bookings = jsonDecode(response.body);
        return bookings
            .isNotEmpty; // Unit memiliki booking jika list tidak kosong
      } else if (response.statusCode == 404) {
        // Unit tidak ditemukan, lebih aman mengembalikan false
        return false;
      } else {
        // Untuk kode status lain, asumsikan ada booking untuk mencegah penghapusan
        return true;
      }
    } catch (e) {
      if (BaseService.debugMode) {
        print('❌ Error checking bookings: $e');
      }
      // Asumsikan ada booking jika terjadi error (pendekatan yang aman)
      return true;
    }
  }
}
