enum BookingStatus { pending, approved, on_going, done, rejected, overtime }

class Booking {
  final int id;
  final int? userId;
  final String? userName;
  final dynamic vehicleUnitId; // bisa int atau string
  final DateTime startDatetime;
  final DateTime endDatetime;
  final BookingStatus status;
  final String? statusNote;
  final int? transactionId;
  final DateTime? requestDate;
  final Map<String, dynamic>? vehicle;
  final Map<String, dynamic>? vehicleUnit;
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? transaction;

  Booking({
    required this.id,
    this.userId,
    this.userName,
    required this.vehicleUnitId,
    required this.startDatetime,
    required this.endDatetime,
    required this.status,
    this.statusNote,
    this.transactionId,
    this.requestDate,
    this.vehicle,
    this.vehicleUnit,
    this.user,
    this.transaction,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    final id = json['id'] ?? json['bookingId'] ?? json['BookingId'] ?? 0;

    // ⏱️ Parser tanggal fleksibel
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now().toUtc();

      // Format YYYYMMDD
      if (value is String && value.length == 8 && int.tryParse(value) != null) {
        try {
          return DateTime.utc(
            int.parse(value.substring(0, 4)),
            int.parse(value.substring(4, 6)),
            int.parse(value.substring(6, 8)),
          );
        } catch (_) {}
      }

      // Format ISO / lainnya
      try {
        final parsed = DateTime.parse(value.toString());
        return parsed.isUtc
            ? parsed
            : DateTime.utc(parsed.year, parsed.month, parsed.day, 12);
      } catch (_) {
        return DateTime.now().toUtc();
      }
    }

    // Ambil tanggal start dan end
    final startDate = parseDate(
      json['startDatetime'] ??
          json['StartDate'] ??
          json['period']?['startDate'],
    );

    final endDate = parseDate(
      json['endDatetime'] ?? json['EndDate'] ?? json['period']?['endDate'],
    );

    // Ambil ID unit kendaraan
    final rawUnitId = json['vehicleUnitId'] ?? json['unitCode'];
    final unitId = rawUnitId ?? 'UNKNOWN';

    // Status booking
    final statusStr =
        (json['status'] ?? json['Status'] ?? 'pending')
            .toString()
            .toLowerCase();
    final status = BookingStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => BookingStatus.pending,
    );

    // Kendaraan bisa string atau Map
    Map<String, dynamic>? parseVehicle(dynamic val) {
      if (val is Map<String, dynamic>) return val;
      if (val != null) return {'name': val.toString()};
      return null;
    }

    // Fallback transaction jika tidak ada objek 'transaction'
    final fallbackTransaction = {
      'amount': json['totalPrice'] ?? json['price'],
      'totalPrice': json['totalPrice'],
      'price': json['price'],
      'paymentStatus': json['paymentStatus'],
      'paymentImageUrl': json['paymentImageUrl'],
    };

    return Booking(
      id: id is int ? id : int.tryParse(id.toString()) ?? 0,
      userId: json['userId'],
      userName: json['userName'],
      vehicleUnitId: unitId,
      startDatetime: startDate,
      endDatetime: endDate,
      status: status,
      statusNote: json['statusNote'] ?? json['StatusNote'],
      transactionId:
          json['transactionId'] ??
          json['Payment']?['TransactionId'] ??
          json['payment']?['transactionId'],
      requestDate:
          json['requestDate'] != null
              ? DateTime.tryParse(json['requestDate'])
              : null,
      vehicle: parseVehicle(json['vehicle']),
      vehicleUnit:
          json['vehicleUnit'] is Map
              ? json['vehicleUnit'] as Map<String, dynamic>
              : json['Vehicle'] is Map
              ? json['Vehicle'] as Map<String, dynamic>
              : null,
      user: json['user'] is Map ? json['user'] as Map<String, dynamic> : null,
      transaction:
          json['transaction'] is Map
              ? json['transaction'] as Map<String, dynamic>
              : fallbackTransaction,
    );
  }
}
