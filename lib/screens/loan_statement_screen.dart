import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;
import '../models/party.dart';
import '../providers/finance_provider.dart';
import '../services/pdf_service.dart';
import '../services/data_service.dart';
import 'add_party_screen.dart';
import 'party_details_screen.dart';

class LoanStatementScreen extends StatefulWidget {
  const LoanStatementScreen({super.key});

  @override
  State<LoanStatementScreen> createState() => _LoanStatementScreenState();
}

class _LoanStatementScreenState extends State<LoanStatementScreen> {
  String _searchQuery = '';
  CollectionType? _filterType;
  bool _showDebtUOnly = false;
  int _maxWeeks = 12;

  final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    
    // Filter parties
    final filteredParties = provider.parties.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p.mobileNo != null && p.mobileNo!.contains(_searchQuery));
      final matchesType = _filterType == null || p.collectionType == _filterType;
      final matchesDebtU = !_showDebtUOnly || p.isDebtU;
      return matchesSearch && matchesType && matchesDebtU;
    }).toList();

    // Excel Top Summary calculations
    final totalPrincipal = provider.parties.fold(0.0, (sum, p) => sum + p.principal);
    final totalPayable = provider.parties.fold(0.0, (sum, p) => sum + p.totalPayable);
    final totalCollected = provider.parties.fold(0.0, (sum, p) => sum + provider.getPaidAmount(p.id));
    final restAmount = totalPayable - totalCollected;
    final debtUCount = provider.parties.where((p) => p.isDebtU).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          "P.D. LOAN STATEMENT",
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 1.0,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.amberAccent),
            tooltip: "Export Statement PDF",
            onPressed: () => _exportPDF(provider),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => provider.fetchDashboardData(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. EXCEL-STYLE HEADER SUMMARY PANEL
          _buildExcelHeaderSummary(
            totalPrincipal: totalPrincipal,
            totalPayable: totalPayable,
            totalCollected: totalCollected,
            restAmount: restAmount,
            debtUCount: debtUCount,
          ),

          // 2. SEARCH & FILTER CONTROLS BAR
          _buildFilterBar(),

          // 3. EXCEL LOAN STATEMENT GRID TABLE
          Expanded(
            child: filteredParties.isEmpty
                ? _buildEmptyState()
                : SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _buildStatementDataTable(context, provider, filteredParties),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildExcelHeaderSummary({
    required double totalPrincipal,
    required double totalPayable,
    required double totalCollected,
    required double restAmount,
    required int debtUCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _summaryBox(
                  title: "MAIN BALANCE",
                  value: currency.format(totalPrincipal),
                  color: Colors.amber.shade300,
                  bgColor: Colors.amber.shade900.withOpacity(0.3),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _summaryBox(
                  title: "ROLLING LOAN",
                  value: currency.format(totalPayable),
                  color: Colors.lightGreenAccent,
                  bgColor: Colors.green.shade900.withOpacity(0.3),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _summaryBox(
                  title: "REST AMOUNT",
                  value: currency.format(restAmount),
                  color: restAmount > 0 ? Colors.cyanAccent : Colors.redAccent,
                  bgColor: Colors.blue.shade900.withOpacity(0.3),
                ),
              ),
            ],
          ),
          if (debtUCount > 0) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                setState(() {
                  _showDebtUOnly = !_showDebtUOnly;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _showDebtUOnly ? Colors.red.shade700 : Colors.red.shade900.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      "DEBT-U FLAG: $debtUCount DEFAULTERS",
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _showDebtUOnly ? "(Showing Debt-U Only)" : "(Tap to filter)",
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryBox({
    required String title,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade400,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "Search party or phone...",
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<CollectionType?>(
            value: _filterType,
            hint: Text("Frequency", style: GoogleFonts.inter(fontSize: 13)),
            underline: const SizedBox(),
            items: [
              const DropdownMenuItem(value: null, child: Text("ALL")),
              ...CollectionType.values.map(
                (e) => DropdownMenuItem(value: e, child: Text(e.name.toUpperCase())),
              ),
            ],
            onChanged: (val) => setState(() => _filterType = val),
          ),
        ],
      ),
    );
  }

  Widget _buildStatementDataTable(
    BuildContext context,
    FinanceProvider provider,
    List<Party> parties,
  ) {
    final TextStyle headerStyle = GoogleFonts.outfit(
      fontWeight: FontWeight.bold,
      fontSize: 12,
      color: Colors.white,
    );

    final TextStyle cellStyle = GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF1E293B),
    );

    return DataTable(
      columnSpacing: 16,
      headingRowHeight: 44,
      dataRowMinHeight: 48,
      dataRowMaxHeight: 52,
      headingRowColor: WidgetStateProperty.all(const Color(0xFF1E293B)),
      columns: [
        DataColumn(label: Text("SL", style: headerStyle)),
        DataColumn(label: Text("DATE", style: headerStyle)),
        DataColumn(label: Text("NAME", style: headerStyle)),
        DataColumn(label: Text("MOBILE", style: headerStyle)),
        DataColumn(label: Text("AMOUNT", style: headerStyle)),
        DataColumn(label: Text("BIMA", style: headerStyle)),
        DataColumn(label: Text("INST+BIMA", style: headerStyle)),
        // 1st Week to 12th Week Columns
        for (int w = 1; w <= _maxWeeks; w++)
          DataColumn(label: Text("${w}th WK", style: headerStyle)),
        DataColumn(label: Text("TOTAL PAID", style: headerStyle)),
        DataColumn(label: Text("BALANCE", style: headerStyle)),
        DataColumn(label: Text("STATUS", style: headerStyle)),
      ],
      rows: List.generate(parties.length, (index) {
        final party = parties[index];
        final paidTotal = provider.getPaidAmount(party.id);
        final balance = provider.getBalance(party);
        final dueInst = party.duePerPeriod;
        final gtInst = party.gtPerPeriod;

        final isComplete = balance <= 0;
        final isRowDebtU = party.isDebtU;

        // Alternate row background colors like Excel
        final rowColor = isRowDebtU
            ? Colors.red.shade50
            : (isComplete ? Colors.green.shade50 : (index % 2 == 0 ? Colors.white : const Color(0xFFF8FAFC)));

        return DataRow(
          color: WidgetStateProperty.all(rowColor),
          cells: [
            // SL
            DataCell(Text("${index + 1}", style: cellStyle)),
            // DATE
            DataCell(Text(DateFormat('dd/MM').format(party.startDate), style: cellStyle)),
            // NAME
            DataCell(
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PartyDetailsScreen(party: party)),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      party.name,
                      style: cellStyle.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2563EB),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    if (isRowDebtU)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text("DEBT", style: GoogleFonts.inter(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
            ),
            // MOBILE
            DataCell(
              party.mobileNo != null && party.mobileNo!.isNotEmpty
                  ? InkWell(
                      onTap: () => _makePhoneCall(party.mobileNo!),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.phone, size: 12, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(party.mobileNo!, style: cellStyle.copyWith(color: Colors.green.shade800)),
                        ],
                      ),
                    )
                  : Text("-", style: cellStyle),
            ),
            // AMOUNT (Principal)
            DataCell(Text(currency.format(party.principal), style: cellStyle.copyWith(fontWeight: FontWeight.w600))),
            // BIMA
            DataCell(Text(party.bima > 0 ? "₹${party.bima.toInt()}" : "-", style: cellStyle)),
            // INST+BIMA (GT)
            DataCell(Text("₹${gtInst.toInt()}", style: cellStyle.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF4F46E5)))),

            // 1st Week to 12th Week dynamically filled based on paidTotal
            for (int w = 1; w <= _maxWeeks; w++) ...[
              _buildWeekCell(w, dueInst, paidTotal, cellStyle),
            ],

            // TOTAL PAID
            DataCell(Text(currency.format(paidTotal), style: cellStyle.copyWith(fontWeight: FontWeight.bold, color: Colors.green.shade700))),
            // BALANCE
            DataCell(Text(currency.format(balance), style: cellStyle.copyWith(fontWeight: FontWeight.bold, color: balance > 0 ? Colors.red.shade700 : Colors.green.shade700))),
            // STATUS
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isComplete ? Colors.green.shade100 : (isRowDebtU ? Colors.red.shade100 : Colors.amber.shade100),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isComplete ? "COMPLETE" : (isRowDebtU ? "DEBT-U" : "ACTIVE"),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isComplete ? Colors.green.shade800 : (isRowDebtU ? Colors.red.shade800 : Colors.amber.shade900),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  DataCell _buildWeekCell(int weekNum, double duePerWeek, double paidTotal, TextStyle cellStyle) {
    if (duePerWeek <= 0) return DataCell(Text("-", style: cellStyle));

    final weekTarget = weekNum * duePerWeek;
    if (paidTotal >= weekTarget) {
      // Full paid for this week
      return DataCell(
        Text(
          "${duePerWeek.toInt()}",
          style: cellStyle.copyWith(color: Colors.green.shade700, fontWeight: FontWeight.bold),
        ),
      );
    } else if (paidTotal > (weekNum - 1) * duePerWeek) {
      // Partial paid for this week
      final partial = paidTotal - ((weekNum - 1) * duePerWeek);
      return DataCell(
        Text(
          "${partial.toInt()}",
          style: cellStyle.copyWith(color: Colors.amber.shade900, fontWeight: FontWeight.bold),
        ),
      );
    } else {
      // Not paid yet
      return DataCell(Text("-", style: cellStyle.copyWith(color: Colors.grey.shade400)));
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.table_chart_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "No Loan Statements Found",
            style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            "Add parties to generate weekly loan statement matrix.",
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPartyScreen()));
            },
            icon: const Icon(Icons.add),
            label: const Text("Add New Party"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E293B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await launcher.canLaunchUrl(launchUri)) {
      await launcher.launchUrl(launchUri);
    }
  }

  Future<void> _exportPDF(FinanceProvider provider) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Generating Loan Statement PDF...")),
    );
    try {
      final payments = await DataService().getPaymentsInRange(
        DateTime(2020), 
        DateTime.now().add(const Duration(days: 1)),
      );
      Map<String, double> paidAmounts = {};
      for (var p in provider.parties) {
        paidAmounts[p.id] = provider.getPaidAmount(p.id);
      }
      await PdfService.generateLoanStatementGridReport(
        provider.parties,
        payments,
        paidAmounts,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error generating PDF: $e")),
        );
      }
    }
  }
}
