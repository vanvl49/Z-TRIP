class User {
  final int id;
  final String email;
  final String name;
  final bool hasProfile;
  final bool hasKtp;
  final bool hasSim;
  final bool isVerified;
  final bool isAdmin; // Sesuai dengan bool Role di C#
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.hasProfile = false,
    this.hasKtp = false,
    this.hasSim = false,
    this.isVerified = false,
    this.isAdmin = false,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      hasProfile: json['hasProfile'] ?? json['has_profile'] ?? false,
      hasKtp: json['hasKtp'] ?? json['has_ktp'] ?? false,
      hasSim: json['hasSim'] ?? json['has_sim'] ?? false,
      isVerified: json['isVerified'] ?? json['is_verified'] ?? false,
      isAdmin: json['role'] ?? json['isAdmin'] ?? false, // Perhatikan field ini
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'])
              : json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'isVerified': isVerified,
      'role': isAdmin, // Pastikan menggunakan properti 'role' bukan 'isAdmin'
    };
  }
}
