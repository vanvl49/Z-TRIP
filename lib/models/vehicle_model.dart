enum VehicleCategory { mobil, motor }

class Vehicle {
  final int? id;
  final String merk;
  final VehicleCategory category; // Ubah ke enum
  final String name;
  final String? description;
  final int capacity;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Vehicle({
    this.id,
    required this.merk,
    required this.category,
    required this.name,
    this.description,
    required this.capacity,
    this.createdAt,
    this.updatedAt,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
    id: json['id'],
    merk: json['merk'],
    category:
        (json['category'].toString().toLowerCase() == 'motor')
            ? VehicleCategory.motor
            : VehicleCategory.mobil,
    name: json['name'],
    description: json['description'],
    capacity: json['capacity'] ?? 0,
    createdAt:
        json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    updatedAt:
        json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'merk': merk,
    'category': category.name, // Simpan sebagai string
    'name': name,
    'description': description,
    'capacity': capacity,
  };

  String get categoryText =>
      category == VehicleCategory.motor ? 'Motor' : 'Mobil';
}

// HAPUS SELURUH DEFINISI TRANSACTION DI FILE INI
// Gunakan import dari transaction_model.dart sebagai gantinya
