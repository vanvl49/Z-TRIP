import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rentalkuy/models/vehicle_model.dart';
import 'package:rentalkuy/services/base_service.dart';

class VehicleService extends BaseService {
  // Get all vehicles (templates)
  static Future<List<Vehicle>> fetchVehicles(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${BaseService.baseUrl}/api/vehicle'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Vehicle.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load vehicles: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching vehicles: $e');
    }
  }

  // Get vehicle by ID
  static Future<Vehicle> fetchVehicleById(String token, int id) async {
    try {
      final response = await http.get(
        Uri.parse('${BaseService.baseUrl}/api/vehicle/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return Vehicle.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load vehicle: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching vehicle: $e');
    }
  }

  // Get vehicles by merk
  static Future<List<Vehicle>> fetchVehiclesByMerk(
      String token, String merk) async {
    try {
      final response = await http.get(
        Uri.parse('${BaseService.baseUrl}/api/vehicle/merk/$merk'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Vehicle.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load vehicles by merk: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching vehicles by merk: $e');
    }
  }

  // Get vehicles by capacity
  static Future<List<Vehicle>> fetchVehiclesByCapacity(
      String token, int capacity) async {
    try {
      final response = await http.get(
        Uri.parse('${BaseService.baseUrl}/api/vehicle/kapasitas/$capacity'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Vehicle.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load vehicles by capacity: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching vehicles by capacity: $e');
    }
  }

  // Filter vehicles
  static Future<List<Vehicle>> filterVehicles(
    String token, {
    String? category,
    String? merk,
    int? kapasitas,
    double? priceMin,
    double? priceMax,
    String? name,
  }) async {
    final queryParams = <String, String>{};
    
    if (category != null) queryParams['category'] = category;
    if (merk != null) queryParams['merk'] = merk;
    if (kapasitas != null) queryParams['kapasitas'] = kapasitas.toString();
    if (priceMin != null) queryParams['priceMin'] = priceMin.toString();
    if (priceMax != null) queryParams['priceMax'] = priceMax.toString();
    if (name != null) queryParams['name'] = name;

    try {
      final uri = Uri.parse('${BaseService.baseUrl}/api/vehicle/filter')
          .replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Vehicle.fromJson(json)).toList();
      } else {
        throw Exception('Failed to filter vehicles: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error filtering vehicles: $e');
    }
  }

  // Get vehicle categories
  static Future<List<String>> getVehicleCategories(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${BaseService.baseUrl}/api/vehicle/categories'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<String>();
      } else {
        throw Exception('Failed to load vehicle categories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching vehicle categories: $e');
    }
  }

  // Add a new vehicle (admin only)
  static Future<bool> addVehicle(String token, Vehicle vehicle) async {
    try {
      final response = await http.post(
        Uri.parse('${BaseService.baseUrl}/api/vehicle'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(vehicle.toJson()),
      );

      return response.statusCode == 201;
    } catch (e) {
      throw Exception('Error adding vehicle: $e');
    }
  }

  // Update vehicle (admin only)
  static Future<bool> updateVehicle(String token, Vehicle vehicle) async {
    try {
      final response = await http.put(
        Uri.parse('${BaseService.baseUrl}/api/vehicle/${vehicle.id}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(vehicle.toJson()),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error updating vehicle: $e');
    }
  }

  // Delete vehicle (admin only)
  static Future<bool> deleteVehicle(String token, int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${BaseService.baseUrl}/api/vehicle/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error deleting vehicle: $e');
    }
  }
}
