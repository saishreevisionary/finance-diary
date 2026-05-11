import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF2563EB)),
          ),
          child: child!,
        );
      },
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
          "Advanced Reports",
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Date Range Picker
              Row(
                children: [
                  Expanded(
                    child: _datePickerButton(
                      context: context,
                      date: _startDate,
                      isStart: true,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text("to", style: GoogleFonts.inter(color: const Color(0xFF6B7280))),
                  ),
                  Expanded(
                    child: _datePickerButton(
                      context: context,
                      date: _endDate,
                      isStart: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // 2. Collection Type Filters
              Text("Collection Types", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w500, color: const Color(0xFF1F2937))),
              const SizedBox(height: 12),
              Row(
                children: CollectionType.values.map((type) {
                  final isSelected = _selectedTypes.contains(type);
                  final isLast = type == CollectionType.values.last;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: isLast ? 0 : 8.0),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedTypes.clear();
                            _selectedTypes.add(type);
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFE0E7FF) : const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isSelected ? const Color(0xFFC7D2FE) : Colors.transparent),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isSelected) ...[
                                const Icon(Icons.check_rounded, size: 14, color: Color(0xFF1E3A8A)),
                                const SizedBox(width: 4),
                              ],
                              Flexible(
                                child: Text(
                                  type.name.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF4B5563),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),

              // 3. Stats Overview
              Builder(
                builder: (context) {
                  final filteredParties = provider.parties
                      .where((p) => _selectedTypes.contains(p.collectionType))
                      .toList();
                  final totalOwed = filteredParties.fold(0.0, (sum, p) => sum + provider.getBalance(p));

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                    ),
                    child: Column(
                      children: [
                        Text("Overview", style: GoogleFonts.inter(color: const Color(0xFF0284C7), fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _statItem("Parties", filteredParties.length.toString()),
                            _statItem("Total Owed", currency.format(totalOwed)),
                          ],
                        ),
                      ],
                    ),
                  );
                }
              ),
              const SizedBox(height: 40),

              // 4. Actions
              Text("Generate Reports", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w500, color: const Color(0xFF1F2937))),
              const SizedBox(height: 16),
              
              _reportButton(
                title: "Payment Summary PDF",
                subtitle: "History within selected period & types",
                icon: Icons.history_rounded,
                iconBgColor: const Color(0xFFE0F2FE),
                iconColor: const Color(0xFF0284C7),
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
              const SizedBox(height: 16),
              _reportButton(
                title: "Unpaid Dues Report",
                subtitle: "List of parties with outstanding balances",
                icon: Icons.warning_rounded,
                iconBgColor: const Color(0xFFFEE2E2),
                iconColor: const Color(0xFFDC2626),
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

  Widget _datePickerButton({required BuildContext context, required DateTime date, required bool isStart}) {
    return InkWell(
      onTap: () => _selectDate(context, isStart),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8), // Reduced horizontal padding
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF6B7280)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF2563EB)),
            const SizedBox(width: 6), // Slightly reduced spacing
            Flexible(
              child: Text(
                DateFormat.yMMMd().format(date),
                style: GoogleFonts.inter(
                  fontSize: 13, // Slightly reduced font size to help fit
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF2563EB),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis, // Prevents text from overflowing
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w600, color: const Color(0xFF374151))),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9CA3AF))),
      ],
    );
  }

  Widget _reportButton({required String title, required String subtitle, required IconData icon, required Color iconBgColor, required Color iconColor, required VoidCallback onTap, bool isLoading = false}) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16, color: const Color(0xFF374151))),
                  const SizedBox(height: 4),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9CA3AF))),
                ],
              ),
            ),
            if (isLoading)
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            else
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 24),
          ],
        ),
      ),
    );
  }
}
