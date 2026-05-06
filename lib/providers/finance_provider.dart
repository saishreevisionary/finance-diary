import 'package:flutter/material.dart';
import '../models/party.dart';
import '../models/payment.dart';
import '../services/data_service.dart';

class FinanceProvider with ChangeNotifier {
  final DataService _dataService = DataService();

  List<Party> _parties = [];
  List<Payment> _todayPayments = [];
  bool _isLoading = false;

  Map<String, double> _partyPaidAmounts = {};

  List<Party> get parties => _parties;
  List<Payment> get todayPayments => _todayPayments;
  bool get isLoading => _isLoading;
  
  double getPaidAmount(String partyId) => _partyPaidAmounts[partyId] ?? 0.0;
  double getBalance(Party party) => party.totalPayable - getPaidAmount(party.id);

  // --- Dashboard Stats ---

  int get totalParties => _parties.length;

  double get totalAmountGiven {
    return _parties.fold(0, (sum, party) => sum + party.principal);
  }

  double get todaysDueAmount {
    return _parties
        .where((p) => p.collectionType == CollectionType.daily)
        .fold(0, (sum, p) => sum + p.duePerPeriod);
  }

  double get todaysCollectedAmount {
    return _todayPayments.fold(0, (sum, p) => sum + p.amountPaid);
  }

  int get pendingPaymentsCount {
    final paidPartyIds = _todayPayments.map((p) => p.partyId).toSet();
    final dailyParties = _parties.where((p) => p.collectionType == CollectionType.daily);
    return dailyParties.where((p) => !paidPartyIds.contains(p.id)).length;
  }

  // --- Actions ---

  Future<void> fetchDashboardData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _parties = await _dataService.getParties();
      _todayPayments = await _dataService.getPaymentsByDate(DateTime.now());
      await _fetchAllBalances();
    } catch (e) {
      debugPrint("Error fetching dashboard data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchAllBalances() async {
    // For MVP, we might fetch all payments or use a DB view. 
    // Fetching all payments for all parties might be heavy.
    // Let's implement a 'getBalances' in DataService that uses a Postgres function or grouping.
    // For now, falling back to a simpler approach: 
    // If parties < 100, we can fetch all payments? Or just assume we lazy load?
    // Let's add a method in DataService to get total paid per party.
    try {
      final balances = await _dataService.getAllPartyPaidAmounts();
      _partyPaidAmounts = balances;
    } catch (e) {
      debugPrint("Error fetching balances: $e");
    }
  }

  Future<void> addParty(Party party) async {
    await _dataService.addParty(party);
    await fetchDashboardData();
  }

  Future<void> updateParty(Party party) async {
    await _dataService.updateParty(party);
    await fetchDashboardData();
  }

  Future<void> recordPayment(Payment payment) async {
    await _dataService.addPayment(payment);
    // Refresh today's payments and balances
    final isToday = DateUtils.isSameDay(payment.date, DateTime.now());
    if (isToday) {
      _todayPayments.add(payment);
    }
    // Update local balance cache
    final currentPaid = _partyPaidAmounts[payment.partyId] ?? 0.0;
    _partyPaidAmounts[payment.partyId] = currentPaid + payment.amountPaid;
    notifyListeners();
  }
}
