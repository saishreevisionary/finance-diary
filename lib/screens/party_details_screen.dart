import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/party.dart';
import '../models/payment.dart';
import '../services/data_service.dart';
import '../services/pdf_service.dart';

class PartyDetailsScreen extends StatefulWidget {
  final Party party;
  const PartyDetailsScreen({super.key, required this.party});

  @override
  State<PartyDetailsScreen> createState() => _PartyDetailsScreenState();
}

class _PartyDetailsScreenState extends State<PartyDetailsScreen> {
  List<Payment> _payments = [];
  bool _isLoading = true;
  double _totalPaid = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final payments = await DataService().getPaymentsForParty(widget.party.id);
      setState(() {
        _payments = payments;
        _totalPaid = payments.fold(0, (sum, p) => sum + p.amountPaid);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final party = widget.party;
    final totalPayable = party.totalPayable;
    final balance = totalPayable - _totalPaid;
    final currency = NumberFormat.simpleCurrency(name: 'INR');

    return Scaffold(
      appBar: AppBar(
        title: Text(party.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Download Report',
            onPressed: () => PdfService.generatePartyReport(party, _payments),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary Card
                Container(
                  margin: const EdgeInsets.all(16), // Fixed: wrapped in padding/margin
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color ?? Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _row("Principal", currency.format(party.principal)),
                      _row("Interest", "${party.interestPercent}%"),
                      _row("Type", party.paymentType.name.toUpperCase()),
                      if (party.paymentType == PaymentType.due) ...[
                        _row("No of Due", party.numberOfDues?.toString() ?? 'N/A'),
                        _row("Pending Dues", "${(balance / (party.duePerPeriod > 0 ? party.duePerPeriod : 1)).ceil()}", color: Colors.orange),
                      ],
                      _row("Collection", party.collectionType.name.toUpperCase()),
                      _row("Total Payable", currency.format(totalPayable), isBold: true),
                      const Divider(),
                      _row("Total Paid", currency.format(_totalPaid), color: Colors.green),
                      _row("Balance", currency.format(balance), color: Colors.red, isBold: true),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    "Payment History",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _payments.length,
                    itemBuilder: (context, index) {
                      final payment = _payments[index];
                      return ListTile(
                        leading: const Icon(Icons.payment, color: Colors.blue),
                        title: Text(currency.format(payment.amountPaid)),
                        subtitle: Text(DateFormat.yMMMd().format(payment.date)),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _row(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
