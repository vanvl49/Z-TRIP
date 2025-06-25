enum PaymentMethod { QRIS, TRANSFER }

class Transaction {
  final int id;
  final int bookingId;
  final PaymentMethod method;
  final String paymentStatus;
  final double amount;
  final String? paymentImageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Transaction({
    required this.id,
    required this.bookingId,
    required this.method,
    required this.paymentStatus,
    required this.amount,
    this.paymentImageUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory Transaction.fromJson(
    Map<String, dynamic> json,
  ) => Transaction(
    id: json['id'],
    bookingId: json['bookingId'],
    method: PaymentMethod.values.firstWhere(
      (e) => e.name.toUpperCase() == (json['method'] as String).toUpperCase(),
      orElse: () => PaymentMethod.QRIS,
    ),
    paymentStatus: json['paymentStatus'],
    amount: (json['amount'] as num).toDouble(),
    paymentImageUrl: json['paymentImageUrl'],
    createdAt:
        json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    updatedAt:
        json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
  );
}
