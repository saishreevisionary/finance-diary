import 'package:uuid/uuid.dart';

enum InvestmentReturnType { monthly, lumpSum }
enum InvestmentStatus { active, closed, overdue }

class Investment {
  final String id;
  final String? companyId;
  final String investorName;
  final String? mobileNo;
  final double amountInvested;
  final double interestRate;
  final InvestmentReturnType returnType;
  final DateTime startDate;
  final DateTime? maturityDate;
  final double amountReturned;
  final InvestmentStatus status;
  final String? notes;
  final DateTime createdAt;

  Investment({
    required this.id,
    this.companyId,
    required this.investorName,
    this.mobileNo,
    required this.amountInvested,
    required this.interestRate,
    required this.returnType,
    required this.startDate,
    this.maturityDate,
    this.amountReturned = 0.0,
    this.status = InvestmentStatus.active,
    this.notes,
    required this.createdAt,
  });

  factory Investment.create({
    required String investorName,
    String? mobileNo,
    required double amountInvested,
    required double interestRate,
    required InvestmentReturnType returnType,
    required DateTime startDate,
    DateTime? maturityDate,
    String? notes,
    String? companyId,
  }) {
    return Investment(
      id: const Uuid().v4(),
      companyId: companyId,
      investorName: investorName,
      mobileNo: mobileNo,
      amountInvested: amountInvested,
      interestRate: interestRate,
      returnType: returnType,
      startDate: startDate,
      maturityDate: maturityDate,
      amountReturned: 0.0,
      status: InvestmentStatus.active,
      notes: notes,
      createdAt: DateTime.now(),
    );
  }

  double get balance => amountInvested - amountReturned;

  bool get isOverdue {
    if (status == InvestmentStatus.closed) return false;
    if (maturityDate == null) return false;
    return DateTime.now().isAfter(maturityDate!);
  }

  factory Investment.fromJson(Map<String, dynamic> json) {
    return Investment(
      id: json['id'],
      companyId: json['company_id'],
      investorName: json['investor_name'],
      mobileNo: json['mobile_no'],
      amountInvested: (json['amount_invested'] as num).toDouble(),
      interestRate: (json['interest_rate'] as num).toDouble(),
      returnType: InvestmentReturnType.values.firstWhere(
        (e) => e.name == (json['return_type'] == 'lump_sum' ? 'lumpSum' : json['return_type'] ?? 'monthly'),
        orElse: () => InvestmentReturnType.monthly,
      ),
      startDate: DateTime.parse(json['start_date']),
      maturityDate: json['maturity_date'] != null ? DateTime.parse(json['maturity_date']) : null,
      amountReturned: json['amount_returned'] != null ? (json['amount_returned'] as num).toDouble() : 0.0,
      status: InvestmentStatus.values.firstWhere(
        (e) => e.name == (json['status'] ?? 'active'),
        orElse: () => InvestmentStatus.active,
      ),
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'investor_name': investorName,
      'mobile_no': mobileNo,
      'amount_invested': amountInvested,
      'interest_rate': interestRate,
      'return_type': returnType == InvestmentReturnType.lumpSum ? 'lump_sum' : 'monthly',
      'start_date': startDate.toIso8601String(),
      'maturity_date': maturityDate?.toIso8601String(),
      'amount_returned': amountReturned,
      'status': status.name,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Investment copyWith({
    String? investorName,
    String? mobileNo,
    double? amountInvested,
    double? interestRate,
    InvestmentReturnType? returnType,
    DateTime? startDate,
    DateTime? maturityDate,
    double? amountReturned,
    InvestmentStatus? status,
    String? notes,
  }) {
    return Investment(
      id: id,
      companyId: companyId,
      investorName: investorName ?? this.investorName,
      mobileNo: mobileNo ?? this.mobileNo,
      amountInvested: amountInvested ?? this.amountInvested,
      interestRate: interestRate ?? this.interestRate,
      returnType: returnType ?? this.returnType,
      startDate: startDate ?? this.startDate,
      maturityDate: maturityDate ?? this.maturityDate,
      amountReturned: amountReturned ?? this.amountReturned,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }
}
