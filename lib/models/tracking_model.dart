class Tracking {
  final int id;
  final int bookingId;
  final String latitude;
  final String longitude;
  final DateTime? recordedAt;

  Tracking({
    required this.id,
    required this.bookingId,
    required this.latitude,
    required this.longitude,
    this.recordedAt,
  });

  factory Tracking.fromJson(Map<String, dynamic> json) {
    return Tracking(
      id: json['id'],
      bookingId: json['bookingId'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      recordedAt:
          json['recordedAt'] != null
              ? DateTime.parse(json['recordedAt'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'latitude': latitude,
      'longitude': longitude,
      'recordedAt': recordedAt?.toIso8601String(),
    };
  }
}
