import 'package:uuid/uuid.dart';

enum CollectionType { daily, weekly, monthly }
enum PaymentType { due, interest }

class Party {
  final String id;
  final String? companyId;
  final String name;
  final String? mobileNo;
  final double principal;
  final double interestPercent;
  final double bima;
  final bool isDebtU;
  final int? durationDays; // Keeping for legacy or general duration notes
  final CollectionType collectionType;
  final PaymentType paymentType;
  final int? numberOfDues; // Required for 'due' type
  final DateTime startDate;
  final DateTime createdAt;

  // Computed
  double? _cachedTotalPayable;
  double? _cachedDuePerPeriod;

  Party({
    required this.id,
    this.companyId,
    required this.name,
    this.mobileNo,
    required this.principal,
    required this.interestPercent,
    this.bima = 0.0,
    this.isDebtU = false,
    this.durationDays,
    required this.collectionType,
    required this.paymentType,
    this.numberOfDues,
    required this.startDate,
    required this.createdAt,
  });

  factory Party.create({
    required String name,
    String? mobileNo,
    required double principal,
    required double interestPercent,
    double bima = 0.0,
    bool isDebtU = false,
    required CollectionType collectionType,
    required PaymentType paymentType,
    int? numberOfDues,
    int? durationDays,
    DateTime? startDate,
    String? companyId,
  }) {
    return Party(
      id: const Uuid().v4(),
      companyId: companyId,
      name: name,
      mobileNo: mobileNo,
      principal: principal,
      interestPercent: interestPercent,
      bima: bima,
      isDebtU: isDebtU,
      collectionType: collectionType,
      paymentType: paymentType,
      numberOfDues: numberOfDues,
      durationDays: durationDays,
      startDate: startDate ?? DateTime.now(),
      createdAt: DateTime.now(),
    );
  }

  double get totalPayable {
    if (paymentType == PaymentType.interest) {
      // For interest-only, the "payable" is theoretically just principal 
      // since interest is recurring.
      return principal;
    }
    // For 'due', it's Principal + Total Interest
    _cachedTotalPayable ??= principal + (principal * interestPercent / 100);
    return _cachedTotalPayable!;
  }

  double get duePerPeriod {
    if (_cachedDuePerPeriod != null) return _cachedDuePerPeriod!;

    if (paymentType == PaymentType.interest) {
      // Interest amount per period
      _cachedDuePerPeriod = principal * interestPercent / 100;
    } else {
      // PaymentType.due
      // Total Payable / Number of Dues
      if (numberOfDues != null && numberOfDues! > 0) {
        _cachedDuePerPeriod = totalPayable / numberOfDues!;
      } else {
        _cachedDuePerPeriod = 0;
      }
    }
    return _cachedDuePerPeriod!;
  }

  double get gtPerPeriod => duePerPeriod + bima;

  factory Party.fromJson(Map<String, dynamic> json) {
    return Party(
      id: json['id'],
      companyId: json['company_id'],
      name: json['name'],
      mobileNo: json['mobile_no'],
      principal: (json['principal'] as num).toDouble(),
      interestPercent: (json['interest_percent'] as num).toDouble(),
      bima: json['bima'] != null ? (json['bima'] as num).toDouble() : 0.0,
      isDebtU: json['is_debt_u'] ?? false,
      durationDays: json['duration'],
      numberOfDues: json['number_of_dues'],
      paymentType: PaymentType.values.firstWhere(
          (e) => e.name == (json['payment_type'] ?? 'due'),
          orElse: () => PaymentType.due),
      collectionType: CollectionType.values.firstWhere(
          (e) => e.name == json['collection_type'],
          orElse: () => CollectionType.daily),
      startDate: DateTime.parse(json['start_date']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'name': name,
      'mobile_no': mobileNo,
      'principal': principal,
      'interest_percent': interestPercent,
      'bima': bima,
      'is_debt_u': isDebtU,
      'duration': durationDays ?? 0,
      'number_of_dues': numberOfDues,
      'payment_type': paymentType.name,
      'collection_type': collectionType.name,
      'start_date': startDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
