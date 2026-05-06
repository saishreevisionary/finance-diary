import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/party.dart';
import '../models/payment.dart';
import '../providers/finance_provider.dart';
import '../services/pdf_service.dart';
import '../services/data_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  final Set<CollectionType> _selectedTypes = Set.from(CollectionType.values);
  bool _isLoading = false;

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final currency = NumberFormat.simpleCurrency(name: 'INR');

    return Scaffold(
      appBar: AppBar(title: const Text("Advanced Reports")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Date Range Picker
              Text("Select Period", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectDate(context, true),
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(DateFormat.yMMMd().format(_startDate)),
                    ),
                  ),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text("to")),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectDate(context, false),
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(DateFormat.yMMMd().format(_endDate)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Collection Type Filters
              Text("Collection Types", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: CollectionType.values.map((type) {
                  final isSelected = _selectedTypes.contains(type);
                  return FilterChip(
                    label: Text(type.name.toUpperCase()),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTypes.add(type);
                        } else {
                          _selectedTypes.remove(type);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),

              // 3. Stats Overview
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(20),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.withAlpha(50)),
                ),
                child: Column(
                  children: [
                    Text("Overview", style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _statItem("Parties", provider.parties.length.toString()),
                        _statItem("Total Owed", currency.format(provider.parties.fold(0.0, (sum, p) => sum + provider.getBalance(p)))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // 4. Actions
              Text("Generate Reports", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              
              _reportButton(
                title: "Payment Summary PDF",
                subtitle: "History within selected period & types",
                icon: Icons.history,
                color: Colors.blue,
                isLoading: _isLoading,
                onTap: () async {
                  setState(() => _isLoading = true);
                  final payments = await DataService().getPaymentsInRange(_startDate, _endDate);
                  // Filter by types in Dart for simplicity
                  final filteredPayments = payments.where((p) {
                    final party = provider.parties.firstWhere((pt) => pt.id == p.partyId, orElse: () => Party.create(name: 'Unknown', principal: 0, interestPercent: 0, collectionType: CollectionType.daily, paymentType: PaymentType.due));
                    return _selectedTypes.contains(party.collectionType);
                  }).toList();

                  await PdfService.generateFilteredHistoryReport(
                    provider.parties, 
                    filteredPayments, 
                    _startDate, 
                    _endDate, 
                    _selectedTypes.toList()
                  );
                  setState(() => _isLoading = false);
                },
              ),
              const SizedBox(height: 12),
              _reportButton(
                title: "Unpaid Dues Report",
                subtitle: "List of parties with outstanding balances",
                icon: Icons.warning_rounded,
                color: Colors.red,
                onTap: () async {
                  // Get paid amounts for everyone
                  Map<String, double> paidAmounts = {};
                  for (var p in provider.parties) {
                    paidAmounts[p.id] = provider.getPaidAmount(p.id);
                  }
                  await PdfService.generateUnpaidDuesReport(provider.parties, paidAmounts);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _reportButton({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap, bool isLoading = false}) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            if (isLoading)
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            else
              const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
