import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;
import '../models/investment.dart';
import '../providers/finance_provider.dart';
import 'add_investment_screen.dart';

class InvestmentsScreen extends StatefulWidget {
  const InvestmentsScreen({super.key});

  @override
  State<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends State<InvestmentsScreen> {
  String _searchQuery = '';
  InvestmentStatus? _filterStatus;

  final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');
  final dateFormat = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final investments = provider.investments;

    // Filter list
    final filteredList = investments.where((i) {
      final matchesSearch = i.investorName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (i.mobileNo != null && i.mobileNo!.contains(_searchQuery));
      final matchesStatus = _filterStatus == null || i.status == _filterStatus;
      return matchesSearch && matchesStatus;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          "INVESTMENTS",
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
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => provider.fetchInvestments(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. TOP SUMMARY CARD
          _buildSummaryHeader(provider),

          // 2. SEARCH AND FILTER BAR
          _buildFilterBar(),

          // 3. INVESTMENT CARDS LIST
          Expanded(
            child: filteredList.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      return _buildInvestmentCard(context, provider, item);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0D9488),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          "Add Investment",
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Colors.white,
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddInvestmentScreen()),
          );
        },
      ),
    );
  }

  // --- 1. TOP SUMMARY HEADER ---

  Widget _buildSummaryHeader(FinanceProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF0F766E),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _summaryBox(
              title: "TOTAL CAPITAL",
              value: currency.format(provider.totalInvestmentAmount),
              bgColor: const Color(0xFF115E59),
              textColor: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _summaryBox(
              title: "RETURNED",
              value: currency.format(provider.totalInvestmentReturned),
              bgColor: const Color(0xFF065F46),
              textColor: const Color(0xFF6EE7B7),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _summaryBox(
              title: "BALANCE OWED",
              value: currency.format(provider.totalInvestmentBalance),
              bgColor: const Color(0xFF881337),
              textColor: const Color(0xFFFDA4AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryBox({
    required String title,
    required String value,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
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
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. FILTER & SEARCH BAR ---

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Search Field
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "Search by investor name or phone...",
                hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0D9488)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip("All", null),
                const SizedBox(width: 8),
                _filterChip("Active", InvestmentStatus.active),
                const SizedBox(width: 8),
                _filterChip("Closed", InvestmentStatus.closed),
                const SizedBox(width: 8),
                _filterChip("Overdue", InvestmentStatus.overdue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, InvestmentStatus? status) {
    final isSelected = _filterStatus == status;
    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : const Color(0xFF475569),
        ),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFF0D9488),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFF0D9488) : const Color(0xFFE2E8F0),
        ),
      ),
      onSelected: (selected) {
        setState(() => _filterStatus = selected ? status : null);
      },
    );
  }

  // --- 3. INVESTMENT CARD ---

  Widget _buildInvestmentCard(BuildContext context, FinanceProvider provider, Investment item) {
    final statusColor = item.status == InvestmentStatus.active
        ? const Color(0xFF059669)
        : item.status == InvestmentStatus.closed
            ? const Color(0xFF64748B)
            : const Color(0xFFDC2626);

    final returnTypeLabel = item.returnType == InvestmentReturnType.monthly ? "Monthly" : "Lump Sum";

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Name & Status Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCCFBF1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.savings_rounded, color: Color(0xFF0D9488), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.investorName,
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      if (item.mobileNo != null && item.mobileNo!.isNotEmpty)
                        GestureDetector(
                          onTap: () => _makePhoneCall(item.mobileNo!),
                          child: Row(
                            children: [
                              const Icon(Icons.phone_rounded, size: 13, color: Color(0xFF0D9488)),
                              const SizedBox(width: 4),
                              Text(
                                item.mobileNo!,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF0D9488),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.status.name.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Middle Grid Stats
            Row(
              children: [
                Expanded(
                  child: _cardStat(
                    "Invested Capital",
                    currency.format(item.amountInvested),
                    const Color(0xFF0F766E),
                  ),
                ),
                Expanded(
                  child: _cardStat(
                    "Interest Rate",
                    "${item.interestRate}% ($returnTypeLabel)",
                    const Color(0xFF475569),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _cardStat(
                    "Returned So Far",
                    currency.format(item.amountReturned),
                    const Color(0xFF059669),
                  ),
                ),
                Expanded(
                  child: _cardStat(
                    "Balance Owed",
                    currency.format(item.balance),
                    item.balance > 0 ? const Color(0xFFDC2626) : const Color(0xFF059669),
                    isBold: true,
                  ),
                ),
              ],
            ),

            // Date Info
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Started: ${dateFormat.format(item.startDate)}",
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                ),
                if (item.maturityDate != null)
                  Text(
                    "Maturity: ${dateFormat.format(item.maturityDate!)}",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: item.isOverdue ? Colors.red : const Color(0xFF64748B),
                    ),
                  ),
              ],
            ),

            if (item.notes != null && item.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Notes: ${item.notes}",
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569)),
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showReturnDialog(context, provider, item),
                    icon: const Icon(Icons.payment_rounded, size: 18),
                    label: const Text("Record Return"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0D9488),
                      side: const BorderSide(color: Color(0xFF0D9488)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (val) async {
                    if (val == 'toggle_status') {
                      final newStatus = item.status == InvestmentStatus.closed
                          ? InvestmentStatus.active
                          : InvestmentStatus.closed;
                      await provider.updateInvestment(item.copyWith(status: newStatus));
                    } else if (val == 'delete') {
                      _confirmDelete(context, provider, item);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'toggle_status',
                      child: Row(
                        children: [
                          Icon(
                            item.status == InvestmentStatus.closed
                                ? Icons.replay_rounded
                                : Icons.check_circle_outline_rounded,
                            size: 18,
                            color: const Color(0xFF475569),
                          ),
                          const SizedBox(width: 8),
                          Text(item.status == InvestmentStatus.closed ? "Reopen Investment" : "Mark as Closed"),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text("Delete", style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.more_vert_rounded, color: Color(0xFF475569), size: 18),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardStat(String label, String value, Color color, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  // --- RECORD RETURN DIALOG ---

  void _showReturnDialog(BuildContext context, FinanceProvider provider, Investment item) {
    final returnController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Record Return Payment",
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                ),
                const SizedBox(height: 4),
                Text(
                  "Investor: ${item.investorName} (Balance: ${currency.format(item.balance)})",
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: returnController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: "Return Amount (₹)",
                    prefixIcon: const Icon(Icons.currency_rupee_rounded, color: Color(0xFF0D9488)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return "Enter return amount";
                    final amt = double.tryParse(val.trim());
                    if (amt == null || amt <= 0) return "Enter a valid positive amount";
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final returnAmt = double.parse(returnController.text.trim());
                      final newReturned = item.amountReturned + returnAmt;
                      final newStatus = newReturned >= item.amountInvested
                          ? InvestmentStatus.closed
                          : item.status;

                      await provider.updateInvestment(
                        item.copyWith(
                          amountReturned: newReturned,
                          status: newStatus,
                        ),
                      );

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Return payment recorded successfully!"),
                            backgroundColor: Color(0xFF0D9488),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      "Submit Payout",
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, FinanceProvider provider, Investment item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Investment?"),
        content: Text("Are you sure you want to delete investment record for '${item.investorName}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await provider.deleteInvestment(item.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.savings_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "No Investment Records Found",
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
          ),
          const SizedBox(height: 8),
          Text(
            "Tap the '+ Add Investment' button to record investor capital.",
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
