import 'package:rentalkuy/models/vehicle_model.dart';

class VehicleUnit {
  final int id;
  final String code;
  final int vehicleId;
  final double pricePerDay;
  final String? description;
  final bool hasImage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Optional parent vehicle reference
  final Vehicle? vehicle;

  VehicleUnit({
    required this.id,
    required this.code,
    required this.vehicleId,
    required this.pricePerDay,
    this.description,
    required this.hasImage,
    this.createdAt,
    this.updatedAt,
    this.vehicle,
  });

  factory VehicleUnit.fromJson(Map<String, dynamic> json) {
    if (json['id'] == null) {
      throw Exception('VehicleUnit.fromJson: id is null');
    }
    return VehicleUnit(
      id: json['id'],
      code: json['code'] ?? '',
      vehicleId: json['vehicleId'] ?? json['vehicle_id'],
      pricePerDay:
          (json['pricePerDay'] ?? json['price_per_day'] as num).toDouble(),
      description: json['description'],
      hasImage: json['hasImage'] ?? json['has_image'] ?? false,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      vehicle: json['vehicle'] != null ? Vehicle.fromJson(json['vehicle']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'vehicleId': vehicleId,
      'pricePerDay': pricePerDay,
      'description': description,
    };
  }
}
