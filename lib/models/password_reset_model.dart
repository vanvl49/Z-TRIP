class PasswordReset {
  final int id;
  final int userId;
  final String token;
  final DateTime expiresAt;
  final bool used;
  final DateTime createdAt;

  PasswordReset({
    required this.id,
    required this.userId,
    required this.token,
    required this.expiresAt,
    required this.used,
    required this.createdAt,
  });

  factory PasswordReset.fromJson(Map<String, dynamic> json) {
    return PasswordReset(
      id: json['id'],
      userId: json['userId'],
      token: json['token'],
      expiresAt: DateTime.parse(json['expiresAt']),
      used: json['used'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'token': token,
      'expiresAt': expiresAt.toIso8601String(),
      'used': used,
    };
  }
}
