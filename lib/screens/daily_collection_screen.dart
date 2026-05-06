import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/party.dart';
import '../models/payment.dart';
import '../providers/finance_provider.dart';

class DailyCollectionScreen extends StatefulWidget {
  const DailyCollectionScreen({super.key});

  @override
  State<DailyCollectionScreen> createState() => _DailyCollectionScreenState();
}

class _DailyCollectionScreenState extends State<DailyCollectionScreen> {
  DateTime _selectedDate = DateTime.now();
  CollectionType _selectedType = CollectionType.daily;
  Map<String, double> _inputAmounts = {};
  Map<String, double> _existingPaidAmounts = {}; // Changed from Set to Map
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = Provider.of<FinanceProvider>(context, listen: false);
    if (DateUtils.isSameDay(_selectedDate, DateTime.now())) {
      _updatePaidStatus(provider.todayPayments);
    } else {
       // Mock for now:
       setState(() {
         _existingPaidAmounts.clear();
         _inputAmounts.clear();
       });
    }
  }

  void _updatePaidStatus(List<Payment> payments) {
    setState(() {
      _existingPaidAmounts = {
        for (var p in payments) p.partyId: p.amountPaid
      };
    });
  }

  Future<void> _submitCollections() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<FinanceProvider>(context, listen: false);

    try {
      final filteredParties = provider.parties
          .where((p) => p.collectionType == _selectedType)
          .toList();

      List<Payment> newPayments = [];
      for (var party in filteredParties) {
        if (_existingPaidAmounts.containsKey(party.id)) continue;

        // If amount was edited, use it. Otherwise use the default 'due' amount.
        final amount = _inputAmounts[party.id] ?? party.duePerPeriod;

        if (amount > 0) {
          newPayments.add(Payment.create(
            partyId: party.id,
            amountPaid: amount,
            date: _selectedDate,
          ));
        }
      }

      for (var payment in newPayments) {
        await provider.recordPayment(payment);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${newPayments.length} payments recorded!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final filteredParties = provider.parties
        .where((p) => p.collectionType == _selectedType)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Billing / Collection"),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
                _loadData();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
             padding: const EdgeInsets.all(16),
             child: Row(
               children: [
                 Expanded(
                   child: DropdownButtonFormField<CollectionType>(
                     value: _selectedType,
                     decoration: const InputDecoration(labelText: 'Collection Type'),
                     items: CollectionType.values.map((type) {
                       return DropdownMenuItem(
                         value: type,
                         child: Text(type.name.toUpperCase()),
                       );
                     }).toList(),
                     onChanged: (v) {
                       if (v != null) setState(() => _selectedType = v);
                     },
                   ),
                 ),
                 const SizedBox(width: 16),
                 Text(DateFormat.yMMMEd().format(_selectedDate)),
               ],
             ),
          ),
          
          Expanded(
            child: ListView.builder(
              itemCount: filteredParties.length,
              itemBuilder: (context, index) {
                final party = filteredParties[index];
                final paidAmount = _existingPaidAmounts[party.id] ?? 0;
                final isPaid = paidAmount > 0; // Contains any payment
                final due = party.duePerPeriod;
                final currency = NumberFormat.simpleCurrency(name: 'INR');
                
                // Determine Status
                String status = "Pending";
                Color statusColor = Colors.red;
                if (paidAmount >= due) {
                  status = "Paid";
                  statusColor = Colors.green;
                } else if (paidAmount > 0) {
                  status = "Partial";
                  statusColor = Colors.orange;
                }

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: isPaid ? statusColor.withAlpha(20) : null,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(party.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text("Due: ${currency.format(due)}"),
                              if (party.paymentType == PaymentType.due) ...[
                                Text("Outstanding: ${currency.format(provider.getBalance(party))}", 
                                  style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.2)),
                                Text("Pending Due: ${(provider.getBalance(party) / (due > 0 ? due : 1)).ceil()}", 
                                  style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.2)),
                              ],
                              if (isPaid)
                                Text("Paid: ${currency.format(paidAmount)}",
                                    style: TextStyle(color: statusColor, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        if (isPaid)
                           Expanded(
                            child: Center(
                              child: Chip(
                                label: Text(status.toUpperCase(), style: const TextStyle(color: Colors.white)),
                                backgroundColor: statusColor,
                              ),
                            ),
                          )
                        else
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              initialValue: due.toString(), 
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                prefixText: '₹',
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                isDense: true,
                              ),
                              onChanged: (val) {
                                final amt = double.tryParse(val) ?? 0;
                                _inputAmounts[party.id] = amt;
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitCollections,
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Save Collections"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
