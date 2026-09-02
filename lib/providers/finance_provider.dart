import 'package:flutter/material.dart';
import '../models/company.dart';
import '../models/party.dart';
import '../models/payment.dart';
import '../models/investment.dart';
import '../services/data_service.dart';

class FinanceProvider with ChangeNotifier {
  final DataService _dataService = DataService();

  List<Company> _companies = [];
  Company? _currentCompany;
  List<Party> _parties = [];
  List<Payment> _todayPayments = [];
  List<Investment> _investments = [];
  bool _isLoading = false;

  Map<String, double> _partyPaidAmounts = {};

  List<Company> get companies => _companies;
  Company? get currentCompany => _currentCompany;
  List<Party> get parties => _parties;
  List<Payment> get todayPayments => _todayPayments;
  List<Investment> get investments => _investments;
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

  // --- Investment Stats ---

  double get totalInvestmentAmount => _investments.fold(0.0, (sum, i) => sum + i.amountInvested);
  double get totalInvestmentBalance => _investments.fold(0.0, (sum, i) => sum + i.balance);
  double get totalInvestmentReturned => _investments.fold(0.0, (sum, i) => sum + i.amountReturned);

  // --- Actions ---

  Future<void> fetchCompanies() async {
    try {
      _companies = await _dataService.getCompanies();
      if (_companies.isEmpty) {
        final defaultCompany = Company.create(name: "Default Company");
        await _dataService.addCompany(defaultCompany);
        _companies = [defaultCompany];
      }
      if (_companies.isNotEmpty) {
        _currentCompany ??= _companies.first;
      }
    } catch (e) {
      debugPrint("Error fetching companies: $e");
    }
  }

  Future<void> selectCompany(Company company) async {
    _currentCompany = company;
    notifyListeners();
    await fetchDashboardData();
  }

  Future<void> createCompany(String name) async {
    final company = Company.create(name: name);
    await _dataService.addCompany(company);
    _companies.add(company);
    _currentCompany = company;
    notifyListeners();
    await fetchDashboardData();
  }

  Future<void> updateCompany(Company updatedCompany) async {
    await _dataService.updateCompany(updatedCompany);
    final index = _companies.indexWhere((c) => c.id == updatedCompany.id);
    if (index != -1) {
      _companies[index] = updatedCompany;
      if (_currentCompany?.id == updatedCompany.id) {
        _currentCompany = updatedCompany;
      }
      notifyListeners();
    }
  }

  Future<void> fetchDashboardData() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_companies.isEmpty) {
        await fetchCompanies();
      }

      _parties = await _dataService.getParties(_currentCompany?.id);
      _investments = await _dataService.getInvestments(_currentCompany?.id);
      
      final partyIds = _parties.map((p) => p.id).toSet();
      final allTodayPayments = await _dataService.getPaymentsByDate(DateTime.now());
      _todayPayments = allTodayPayments.where((p) => partyIds.contains(p.partyId)).toList();

      await _fetchAllBalances();
    } catch (e) {
      debugPrint("Error fetching dashboard data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchAllBalances() async {
    try {
      final balances = await _dataService.getAllPartyPaidAmounts();
      final partyIds = _parties.map((p) => p.id).toSet();
      _partyPaidAmounts = Map.fromEntries(
        balances.entries.where((entry) => partyIds.contains(entry.key)),
      );
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

  // --- Investment Actions ---

  Future<void> fetchInvestments() async {
    _investments = await _dataService.getInvestments(_currentCompany?.id);
    notifyListeners();
  }

  Future<void> addInvestment(Investment investment) async {
    await _dataService.addInvestment(investment);
    await fetchInvestments();
  }

  Future<void> updateInvestment(Investment investment) async {
    await _dataService.updateInvestment(investment);
    await fetchInvestments();
  }

  Future<void> deleteInvestment(String id) async {
    await _dataService.deleteInvestment(id);
    await fetchInvestments();
  }
}
