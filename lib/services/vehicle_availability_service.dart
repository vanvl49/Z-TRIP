import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rentalkuy/models/vehicle_unit_model.dart';
import 'base_service.dart';

class VehicleAvailabilityService extends BaseService {
  // Check availability by unit code
  static Future<Map<String, dynamic>> checkAvailabilityByCode(
    String token,
    String unitCode, {
    String? startDate,
    String? endDate,
  }) async {
    try {
      String url =
          '${BaseService.baseUrl}/api/vehicle-availability/code/$unitCode';

      if (startDate != null || endDate != null) {
        url += '?';
        if (startDate != null) url += 'startDate=$startDate';
        if (startDate != null && endDate != null) url += '&';
        if (endDate != null) url += 'endDate=$endDate';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to check availability: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error checking availability: $e');
    }
  }

  // Check availability by vehicle unit ID
  static Future<Map<String, dynamic>> checkAvailabilityById(
    String token,
    int vehicleUnitId, {
    required String startDate,
    required String endDate,
    bool excludeRejected = true,
    bool excludeDone = true,
  }) async {
    try {
      // Buat query parameters
      final queryParams = <String, String>{};
      queryParams['startDate'] = startDate;
      queryParams['endDate'] = endDate;

      // Tambahkan parameter exclude jika perlu
      if (excludeRejected) {
        queryParams['excludeRejected'] = 'true';
      }
      if (excludeDone) {
        queryParams['excludeDone'] = 'true';
      }

      // Buat URL dengan query parameters
      final uri = Uri.parse(
        '${BaseService.baseUrl}/api/vehicle-availability/$vehicleUnitId/check',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to check availability: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error checking availability: $e');
    }
  }

  // Get all available vehicles
  static Future<List<VehicleUnit>> getAvailableVehicles(
    String token, {
    String? startDate,
    String? endDate,
    String? category,
  }) async {
    try {
      String url = '${BaseService.baseUrl}/api/vehicle-availability/available';

      final queryParams = <String, String>{};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (category != null) queryParams['category'] = category;

      final uri = Uri.parse(url).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> units = data['availableUnits'];
        // Tambahkan filter: hanya unit yang memiliki id valid
        return units
            .where((json) => json != null && json['id'] != null)
            .map((json) => VehicleUnit.fromJson(json))
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('401');
      } else {
        throw Exception(
          'Failed to get available vehicles: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error getting available vehicles: $e');
    }
  }
}
