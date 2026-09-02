import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants.dart';
import '../models/company.dart';
import '../models/party.dart';
import '../models/payment.dart';
import '../models/investment.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  // --- Companies ---

  Future<List<Company>> getCompanies() async {
    try {
      final response = await _client
          .from(AppConstants.tblCompanies)
          .select()
          .order('created_at');
      final data = response as List<dynamic>;
      return data.map((e) => Company.fromJson(e)).toList();
    } catch (e) {
      debugPrint("Error fetching companies from DB: $e");
      return [];
    }
  }

  Future<void> addCompany(Company company) async {
    await _client.from(AppConstants.tblCompanies).insert(company.toJson());
  }

  Future<void> updateCompany(Company company) async {
    await _client
        .from(AppConstants.tblCompanies)
        .update(company.toJson())
        .eq('id', company.id);
  }

  // --- Parties ---

  Future<List<Party>> getParties([String? companyId]) async {
    try {
      var query = _client.from(AppConstants.tblParties).select();
      if (companyId != null) {
        query = query.eq('company_id', companyId);
      }
      final response = await query.order('created_at');
      final data = response as List<dynamic>;
      return data.map((e) => Party.fromJson(e)).toList();
    } catch (e) {
      debugPrint("Error fetching parties from DB (companyId: $companyId): $e");
      // Fallback: If query with companyId failed (e.g. column doesn't exist yet),
      // fallback to fetching all parties to keep the app working.
      if (companyId != null) {
        return getParties(null);
      }
      return [];
    }
  }

  Future<void> addParty(Party party) async {
    await _client.from(AppConstants.tblParties).insert(party.toJson());
  }

  Future<void> updateParty(Party party) async {
    await _client
        .from(AppConstants.tblParties)
        .update(party.toJson())
        .eq('id', party.id);
  }
  
  // --- Payments ---

  Future<List<Payment>> getPaymentsForParty(String partyId) async {
    try {
      final response = await _client
          .from(AppConstants.tblPayments)
          .select()
          .eq('party_id', partyId)
          .order('date', ascending: false);

      final data = response as List<dynamic>;
      return data.map((e) => Payment.fromJson(e)).toList();
    } catch (e) {
      debugPrint("Error fetching payments for party: $e");
      return [];
    }
  }
  
  // Get payments for a specific date (for Daily View)
  Future<List<Payment>> getPaymentsByDate(DateTime date) async {
    return getPaymentsInRange(
      DateTime(date.year, date.month, date.day),
      DateTime(date.year, date.month, date.day, 23, 59, 59),
    );
  }

  Future<List<Payment>> getPaymentsInRange(DateTime start, DateTime end) async {
    try {
      final response = await _client
          .from(AppConstants.tblPayments)
          .select()
          .gte('date', start.toIso8601String())
          .lte('date', end.toIso8601String());

      final data = response as List<dynamic>;
      return data.map((e) => Payment.fromJson(e)).toList();
    } catch (e) {
      debugPrint("Error fetching payments in range: $e");
      return [];
    }
  }

  Future<void> addPayment(Payment payment) async {
    await _client.from(AppConstants.tblPayments).insert(payment.toJson());
  }

  Future<void> addBulkPayments(List<Payment> payments) async {
    if (payments.isEmpty) return;
    final List<Map<String, dynamic>> data = payments.map((p) => p.toJson()).toList();
    await _client.from(AppConstants.tblPayments).insert(data);
  }

  // Calculate total paid per party
  // Note: For large datasets, use a database view or RPC.
  // For MVP, simplistic fetch and aggregate.
  Future<Map<String, double>> getAllPartyPaidAmounts() async {
    try {
      final response = await _client.from(AppConstants.tblPayments).select('party_id, amount_paid');
      
      final Map<String, double> totals = {};
      for (var row in response as List<dynamic>) {
        final pid = row['party_id'] as String;
        final amt = (row['amount_paid'] as num).toDouble();
        totals[pid] = (totals[pid] ?? 0) + amt;
      }
      return totals;
    } catch (e) {
      debugPrint("Error getting all party paid amounts: $e");
      return {};
    }
  }

  // --- Investments ---

  Future<List<Investment>> getInvestments([String? companyId]) async {
    try {
      var query = _client.from(AppConstants.tblInvestments).select();
      if (companyId != null) {
        query = query.eq('company_id', companyId);
      }
      final response = await query.order('created_at', ascending: false);
      final data = response as List<dynamic>;
      return data.map((e) => Investment.fromJson(e)).toList();
    } catch (e) {
      debugPrint("Error fetching investments: $e");
      if (companyId != null) {
        return getInvestments(null);
      }
      return [];
    }
  }

  Future<void> addInvestment(Investment investment) async {
    await _client.from(AppConstants.tblInvestments).insert(investment.toJson());
  }

  Future<void> updateInvestment(Investment investment) async {
    await _client
        .from(AppConstants.tblInvestments)
        .update(investment.toJson())
        .eq('id', investment.id);
  }

  Future<void> deleteInvestment(String id) async {
    await _client.from(AppConstants.tblInvestments).delete().eq('id', id);
  }
}
