import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants.dart';
import '../models/party.dart';
import '../models/payment.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  // --- Parties ---

  Future<List<Party>> getParties() async {
    final response = await _client
        .from(AppConstants.tblParties)
        .select()
        .order('created_at');
    
    final data = response as List<dynamic>;
    return data.map((e) => Party.fromJson(e)).toList();
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
    final response = await _client
        .from(AppConstants.tblPayments)
        .select()
        .eq('party_id', partyId)
        .order('date', ascending: false);

    final data = response as List<dynamic>;
    return data.map((e) => Payment.fromJson(e)).toList();
  }
  
  // Get payments for a specific date (for Daily View)
  Future<List<Payment>> getPaymentsByDate(DateTime date) async {
    return getPaymentsInRange(
      DateTime(date.year, date.month, date.day),
      DateTime(date.year, date.month, date.day, 23, 59, 59),
    );
  }

  Future<List<Payment>> getPaymentsInRange(DateTime start, DateTime end) async {
    final response = await _client
        .from(AppConstants.tblPayments)
        .select()
        .gte('date', start.toIso8601String())
        .lte('date', end.toIso8601String());

    final data = response as List<dynamic>;
    return data.map((e) => Payment.fromJson(e)).toList();
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
    // We can use Supabase .rpc or just fetch and group.
    // Fetching all payments columns might be huge. Just fetch stats?
    // Let's create a view in SQL later. For now, assuming relatively small data, fetch minimal columns.
    final response = await _client.from(AppConstants.tblPayments).select('party_id, amount_paid');
    
    final Map<String, double> totals = {};
    for (var row in response as List<dynamic>) {
      final pid = row['party_id'] as String;
      final amt = (row['amount_paid'] as num).toDouble();
      totals[pid] = (totals[pid] ?? 0) + amt;
    }
    return totals;
  }
}
