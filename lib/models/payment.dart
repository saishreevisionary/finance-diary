import 'package:uuid/uuid.dart';

class Payment {
  final String id;
  final String partyId;
  final double amountPaid;
  final DateTime date; // The date this payment counts for (e.g. collection date)
  final DateTime createdAt; // when data entry happened

  Payment({
    required this.id,
    required this.partyId,
    required this.amountPaid,
    required this.date,
    required this.createdAt,
  });

  factory Payment.create({
    required String partyId,
    required double amountPaid,
    DateTime? date,
  }) {
    return Payment(
      id: const Uuid().v4(),
      partyId: partyId,
      amountPaid: amountPaid,
      date: date ?? DateTime.now(),
      createdAt: DateTime.now(),
    );
  }

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      partyId: json['party_id'],
      amountPaid: (json['amount_paid'] as num).toDouble(),
      date: DateTime.parse(json['date']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'party_id': partyId,
      'amount_paid': amountPaid,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
