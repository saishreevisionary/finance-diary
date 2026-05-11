import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final currencyFormatFull = NumberFormat.currency(symbol: '₹', decimalDigits: 2, locale: 'en_IN');

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          party.name,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
            tooltip: 'Download Report',
            onPressed: () => PdfService.generatePartyReport(party, _payments),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Card
                  Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _row("Principal", currencyFormatFull.format(party.principal)),
                        _row("Interest", "${party.interestPercent}%"),
                        _row("Type", party.paymentType.name.toUpperCase()),
                        if (party.paymentType == PaymentType.due) ...[
                          _row("No of Due", party.numberOfDues?.toString() ?? 'N/A'),
                          _row("Pending Dues", "${(balance / (party.duePerPeriod > 0 ? party.duePerPeriod : 1)).ceil()}", color: const Color(0xFFF59E0B)),
                        ],
                        _row("Collection", party.collectionType.name.toUpperCase()),
                        const SizedBox(height: 8),
                        _row("Total Payable", currencyFormatFull.format(totalPayable), isBold: true, fontSize: 18, color: const Color(0xFF1F2937)),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: Color(0xFFF3F4F6)),
                        ),
                        _row("Total Paid", currencyFormatFull.format(_totalPaid), color: const Color(0xFF10B981), isBold: true, fontSize: 16),
                        _row("Balance", currencyFormatFull.format(balance), color: const Color(0xFFEF4444), isBold: true, fontSize: 18),
                      ],
                    ),
                  ),
                  
                  // Payment History Header
                  Padding(
                    padding: const EdgeInsets.only(left: 24, right: 24, bottom: 12),
                    child: Text(
                      "Payment History",
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                  ),

                  // Payments List
                  if (_payments.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(Icons.history_rounded, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              "No payments yet",
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                      itemCount: _payments.length,
                      itemBuilder: (context, index) {
                        final payment = _payments[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade100),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.01),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF10B981), size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      currencyFormatFull.format(payment.amountPaid),
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1F2937),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('MMM d, yyyy • h:mm a').format(payment.date),
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: const Color(0xFF6B7280),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _row(String label, String value, {bool isBold = false, Color? color, double? fontSize}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label, 
            style: GoogleFonts.inter(
              fontSize: 15,
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: fontSize ?? 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? const Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }
}
