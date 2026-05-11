import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
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
  Map<String, double> _existingPaidAmounts = {};
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

        // If explicitly set to 0 (skipped) or not collected, skip it
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
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  '${newPayments.length} collections saved successfully!',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
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
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');
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
          "Billing & Collections",
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
      body: Column(
        children: [
          // Premium Dynamic Control Header (Tab selector + Date switcher)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Horizontal Swipeable Collection Type Selector
                Row(
                  children: CollectionType.values.map((type) {
                    final isSelected = _selectedType == type;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedType = type;
                          });
                          _loadData();
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(
                                    colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: isSelected ? null : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF4F46E5).withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              type.name.toUpperCase(),
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : const Color(0xFF4B5563),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                // Premium Date Navigator Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF4F46E5)),
                      onPressed: () {
                        setState(() {
                          _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                        });
                        _loadData();
                      },
                    ),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
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
                          setState(() => _selectedDate = picked);
                          _loadData();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_month_rounded, size: 16, color: Color(0xFF4F46E5)),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('EEE, MMM d, yyyy').format(_selectedDate),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF4F46E5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Color(0xFF4F46E5)),
                      onPressed: () {
                        setState(() {
                          _selectedDate = _selectedDate.add(const Duration(days: 1));
                        });
                        _loadData();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Interactive Collection List
          Expanded(
            child: filteredParties.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_turned_in_rounded, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          "No parties under this schedule",
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: filteredParties.length,
                    itemBuilder: (context, index) {
                      final party = filteredParties[index];
                      final paidAmount = _existingPaidAmounts[party.id] ?? 0;
                      final isPaid = paidAmount > 0;
                      final due = party.duePerPeriod;

                      // Check if skipped (explicitly set to 0)
                      final isSkipped = _inputAmounts.containsKey(party.id) && _inputAmounts[party.id] == 0;

                      String status = "PENDING";
                      Color statusColor = const Color(0xFFEF4444); // Soft Red
                      if (paidAmount >= due) {
                        status = "PAID";
                        statusColor = const Color(0xFF10B981); // Emerald Green
                      } else if (paidAmount > 0) {
                        status = "PARTIAL";
                        statusColor = const Color(0xFFF59E0B); // Amber
                      }

                      return AnimatedOpacity(
                        duration: const Duration(milliseconds: 250),
                        opacity: isSkipped ? 0.6 : 1.0,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSkipped ? const Color(0xFFF3F4F6) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isPaid 
                                  ? statusColor.withOpacity(0.3) 
                                  : (isSkipped ? Colors.grey.shade300 : Colors.grey.shade100),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isSkipped ? 0.01 : 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Tactile Avatar-Checkbox Integration
                              GestureDetector(
                                onTap: isPaid
                                    ? null
                                    : () {
                                        setState(() {
                                          if (isSkipped) {
                                            _inputAmounts.remove(party.id);
                                          } else {
                                            _inputAmounts[party.id] = 0; // Skip
                                          }
                                        });
                                      },
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isPaid
                                        ? const Color(0xFFD1FAE5)
                                        : (isSkipped ? const Color(0xFFE5E7EB) : const Color(0xFFEEF2FF)),
                                    border: Border.all(
                                      color: isPaid
                                          ? const Color(0xFF10B981).withOpacity(0.3)
                                          : (isSkipped ? Colors.grey.shade400 : const Color(0xFF4F46E5).withOpacity(0.2)),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: isPaid
                                        ? const Icon(Icons.check_rounded, color: Color(0xFF10B981), size: 24)
                                        : (isSkipped
                                            ? const Icon(Icons.block_rounded, color: Color(0xFF9CA3AF), size: 22)
                                            : Text(
                                                party.name.isNotEmpty ? party.name[0].toUpperCase() : '?',
                                                style: GoogleFonts.outfit(
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF4F46E5),
                                                  fontSize: 20,
                                                ),
                                              )),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Info Section
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      party.name,
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: isSkipped ? const Color(0xFF9CA3AF) : const Color(0xFF1F2937),
                                        decoration: isSkipped ? TextDecoration.lineThrough : null,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          "Due: ",
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: const Color(0xFF9CA3AF),
                                          ),
                                        ),
                                        Text(
                                          currencyFormatFull.format(due),
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isSkipped ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (party.paymentType == PaymentType.due && !isSkipped) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        "Pending: ${(provider.getBalance(party) / (due > 0 ? due : 1)).ceil()} days",
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: const Color(0xFFF59E0B),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                    if (isPaid) ...[
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          status,
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            color: statusColor,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ] else if (isSkipped) ...[
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          "SKIPPED",
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            color: const Color(0xFF6B7280),
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Action Box
                              if (isPaid)
                                Text(
                                  currencyFormat.format(paidAmount),
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                )
                              else if (isSkipped)
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _inputAmounts.remove(party.id);
                                    });
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                  icon: const Icon(Icons.add_circle_outline, size: 14, color: Color(0xFF4F46E5)),
                                  label: Text(
                                    "Collect",
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF4F46E5),
                                    ),
                                  ),
                                )
                              else
                                SizedBox(
                                  width: 96,
                                  child: TextFormField(
                                    initialValue: due.toInt().toString(),
                                    keyboardType: TextInputType.number,
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1F2937),
                                    ),
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      prefixText: '₹',
                                      prefixStyle: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF9CA3AF),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                      filled: true,
                                      fillColor: const Color(0xFFF9FAFB),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.grey.shade200),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.grey.shade200),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                                      ),
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
          // Gradient Bottom Button
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitCollections,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          "Save Collections",
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
