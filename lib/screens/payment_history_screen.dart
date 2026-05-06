import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/party.dart';
import '../models/payment.dart';
import '../providers/finance_provider.dart';
import '../services/data_service.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Payment> _payments = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchPayments();
  }

  Future<void> _fetchPayments() async {
    setState(() => _isLoading = true);
    try {
      final payments = await DataService().getPaymentsByDate(_selectedDate);
      setState(() {
        _payments = payments;
      });
    } catch (e) {
      debugPrint("Error fetching history: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
     final currency = NumberFormat.simpleCurrency(name: 'INR');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Payment History"),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
                _fetchPayments();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat.yMMMd().format(_selectedDate),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  "${_payments.length} Payments",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _payments.isEmpty 
                  ? const Center(child: Text("No payments found for this date."))
                  : ListView.builder(
                      itemCount: _payments.length,
                      itemBuilder: (context, index) {
                        final payment = _payments[index];
                        // Look up party name from Provider
                        // We need access to the list of parties.
                        // Assuming FinanceProvider is above in the tree.
                        // We can't access Provider cleanly inside ListView without passing context properly or Consumer.
                        return Consumer<FinanceProvider>(
                          builder: (context, provider, child) {
                            final party = provider.parties.firstWhere(
                              (p) => p.id == payment.partyId, 
                              orElse: () => Party.create(name: 'Unknown', principal: 0, interestPercent: 0, collectionType: CollectionType.daily, paymentType: PaymentType.due), 
                            );
                            
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.withAlpha(20),
                                  child: Text(party.name.isNotEmpty ? party.name[0] : '?', style: const TextStyle(color: Colors.blue)),
                                ),
                                title: Text(party.name),
                                subtitle: Text(DateFormat.jm().format(payment.date)),
                                trailing: Text(
                                  currency.format(payment.amountPaid),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
                                ),
                              ),
                            );
                          }
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
