import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/investment.dart';
import '../providers/finance_provider.dart';

class AddInvestmentScreen extends StatefulWidget {
  const AddInvestmentScreen({super.key});

  @override
  State<AddInvestmentScreen> createState() => _AddInvestmentScreenState();
}

class _AddInvestmentScreenState extends State<AddInvestmentScreen> {
  final _formKey = GlobalKey<FormState>();

  final _investorNameController = TextEditingController();
  final _mobileNoController = TextEditingController();
  final _amountController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _notesController = TextEditingController();

  InvestmentReturnType _returnType = InvestmentReturnType.monthly;
  DateTime _startDate = DateTime.now();
  DateTime? _maturityDate;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _investorNameController.dispose();
    _mobileNoController.dispose();
    _amountController.dispose();
    _interestRateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF0D9488)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectMaturityDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _maturityDate ?? _startDate.add(const Duration(days: 365)),
      firstDate: _startDate,
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF0D9488)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _maturityDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final provider = Provider.of<FinanceProvider>(context, listen: false);
      final newInvestment = Investment.create(
        investorName: _investorNameController.text.trim(),
        mobileNo: _mobileNoController.text.trim().isEmpty ? null : _mobileNoController.text.trim(),
        amountInvested: double.parse(_amountController.text.trim()),
        interestRate: double.parse(_interestRateController.text.trim()),
        returnType: _returnType,
        startDate: _startDate,
        maturityDate: _maturityDate,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        companyId: provider.currentCompany?.id,
      );

      await provider.addInvestment(newInvestment);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Investment recorded successfully!"),
            backgroundColor: Color(0xFF0D9488),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving investment: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();

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
          "Add New Investment",
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Title
              Text(
                "Investor Information",
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),

              // Investor Name Field
              TextFormField(
                controller: _investorNameController,
                decoration: _inputDecoration(
                  label: "Investor Name",
                  hint: "e.g. John Doe",
                  icon: Icons.person_rounded,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Please enter investor name";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Mobile Number Field
              TextFormField(
                controller: _mobileNoController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration(
                  label: "Mobile Number (Optional)",
                  hint: "e.g. 9876543210",
                  icon: Icons.phone_rounded,
                ),
              ),
              const SizedBox(height: 28),

              // Investment Terms Section
              Text(
                "Investment Details",
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),

              // Amount Invested
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDecoration(
                  label: "Capital Amount (₹)",
                  hint: "e.g. 100000",
                  icon: Icons.currency_rupee_rounded,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Please enter capital amount";
                  }
                  if (double.tryParse(val.trim()) == null || double.parse(val.trim()) <= 0) {
                    return "Enter a valid positive amount";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Interest Rate (%)
              TextFormField(
                controller: _interestRateController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDecoration(
                  label: "Promised Interest Rate (%)",
                  hint: "e.g. 2.0 (per month/period)",
                  icon: Icons.percent_rounded,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Please enter interest rate";
                  }
                  if (double.tryParse(val.trim()) == null) {
                    return "Enter a valid interest rate";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Return Type Dropdown/Selector
              Text(
                "Return Payout Type",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _typeRadioTile(
                      title: "Monthly Interest",
                      type: InvestmentReturnType.monthly,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _typeRadioTile(
                      title: "Lump Sum at End",
                      type: InvestmentReturnType.lumpSum,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Dates Selection
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Start Date",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _selectStartDate,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF0D9488)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    dateFormat.format(_startDate),
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Maturity Date (Optional)",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _selectMaturityDate,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.event_available_rounded, size: 18, color: Color(0xFF0D9488)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _maturityDate != null ? dateFormat.format(_maturityDate!) : "No Date",
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: _maturityDate != null ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),
                                if (_maturityDate != null)
                                  GestureDetector(
                                    onTap: () => setState(() => _maturityDate = null),
                                    child: const Icon(Icons.clear_rounded, size: 16, color: Colors.grey),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Notes Field
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: _inputDecoration(
                  label: "Notes / Remarks (Optional)",
                  hint: "e.g. Bank transfer reference or terms",
                  icon: Icons.notes_rounded,
                ),
              ),
              const SizedBox(height: 36),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          "Save Investment",
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeRadioTile({required String title, required InvestmentReturnType type}) {
    final isSelected = _returnType == type;
    return InkWell(
      onTap: () => setState(() => _returnType = type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFCCFBF1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0D9488) : const Color(0xFFCBD5E1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? const Color(0xFF0D9488) : const Color(0xFF64748B),
              size: 18,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF334155),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF0D9488)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0D9488), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }
}
