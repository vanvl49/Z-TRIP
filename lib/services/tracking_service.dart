import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rentalkuy/models/tracking_model.dart';
import 'package:rentalkuy/services/base_service.dart';

class TrackingService extends BaseService {
  // Get all tracking data (admin only)
  static Future<List<Tracking>> getAllTrackingData(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${BaseService.baseUrl}/api/tracking'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> trackingList = data['data'];
        return trackingList.map((json) => Tracking.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load tracking data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching tracking data: $e');
    }
  }

  // Get tracking data by booking ID
  static Future<List<Tracking>> getTrackingByBooking(
    String token,
    int bookingId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${BaseService.baseUrl}/api/tracking/by-booking/$bookingId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> trackingList = data['data'];
        return trackingList.map((json) => Tracking.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load tracking data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching tracking data: $e');
    }
  }

  // Create tracking data
  static Future<bool> createTracking(
    String token,
    int bookingId,
    String latitude,
    String longitude,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${BaseService.baseUrl}/api/tracking'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'bookingId': bookingId,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      throw Exception('Error creating tracking data: $e');
    }
  }

  // Delete tracking data (admin only)
  static Future<bool> deleteTracking(String token, int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${BaseService.baseUrl}/api/tracking/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error deleting tracking data: $e');
    }
  }

  // Get latest tracking for booking
  static Future<Tracking?> getLatestTracking(
    String token,
    int bookingId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${BaseService.baseUrl}/api/tracking/latest/$bookingId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Tracking.fromJson(data);
      } else if (response.statusCode == 404) {
        return null; // No tracking data found
      } else {
        throw Exception(
          'Failed to load latest tracking: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching latest tracking: $e');
    }
  }
}
