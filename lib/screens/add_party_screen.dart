import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/party.dart';
import '../providers/finance_provider.dart';

class AddPartyScreen extends StatefulWidget {
  final Party? party;
  const AddPartyScreen({super.key, this.party});

  @override
  State<AddPartyScreen> createState() => _AddPartyScreenState();
}

class _AddPartyScreenState extends State<AddPartyScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  late TextEditingController _principalController;
  late TextEditingController _interestController;
  late TextEditingController _bimaController;
  late TextEditingController _numberOfDuesController;
  
  late CollectionType _collectionType;
  late PaymentType _paymentType;
  late DateTime _startDate;
  bool _isDebtU = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.party;
    _nameController = TextEditingController(text: p?.name ?? '');
    _mobileController = TextEditingController(text: p?.mobileNo ?? '');
    _principalController = TextEditingController(text: p?.principal.toString() ?? '');
    _interestController = TextEditingController(text: p?.interestPercent.toString() ?? '');
    _bimaController = TextEditingController(text: p?.bima.toString() ?? '0');
    _numberOfDuesController = TextEditingController(text: p?.numberOfDues?.toString() ?? '');
    _collectionType = p?.collectionType ?? CollectionType.weekly;
    _paymentType = p?.paymentType ?? PaymentType.due;
    _startDate = p?.startDate ?? DateTime.now();
    _isDebtU = p?.isDebtU ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _principalController.dispose();
    _interestController.dispose();
    _bimaController.dispose();
    _numberOfDuesController.dispose();
    super.dispose();
  }

  Future<void> _saveParty() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final mobileNo = _mobileController.text.trim().isEmpty ? null : _mobileController.text.trim();
      final principal = double.parse(_principalController.text);
      final interest = double.parse(_interestController.text);
      final bima = double.tryParse(_bimaController.text) ?? 0.0;
      final numberOfDues = _paymentType == PaymentType.due 
          ? int.tryParse(_numberOfDuesController.text) 
          : null;

      if (widget.party == null) {
        // Create
        final provider = Provider.of<FinanceProvider>(context, listen: false);
        final party = Party.create(
          name: name,
          mobileNo: mobileNo,
          principal: principal,
          interestPercent: interest,
          bima: bima,
          isDebtU: _isDebtU,
          numberOfDues: numberOfDues,
          collectionType: _collectionType,
          paymentType: _paymentType,
          startDate: _startDate,
          companyId: provider.currentCompany?.id,
        );
        await provider.addParty(party);
      } else {
        // Update
        final updatedParty = Party(
          id: widget.party!.id,
          companyId: widget.party!.companyId,
          name: name,
          mobileNo: mobileNo,
          principal: principal,
          interestPercent: interest,
          bima: bima,
          isDebtU: _isDebtU,
          numberOfDues: numberOfDues,
          collectionType: _collectionType,
          paymentType: _paymentType,
          startDate: _startDate,
          createdAt: widget.party!.createdAt,
          durationDays: widget.party!.durationDays,
        );
        await Provider.of<FinanceProvider>(context, listen: false).updateParty(updatedParty);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.party == null ? 'Party added!' : 'Party updated!')),
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
    return Scaffold(
      appBar: AppBar(title: Text(widget.party == null ? 'Add New Party' : 'Edit Party')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Party Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mobileController,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number (Optional)',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _principalController,
                decoration: const InputDecoration(
                  labelText: 'Principal Amount (₹)',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _interestController,
                decoration: const InputDecoration(
                  labelText: 'Interest Percentage (%)',
                  prefixIcon: Icon(Icons.percent),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bimaController,
                decoration: const InputDecoration(
                  labelText: 'BIMA / Insurance Amount (₹)',
                  prefixIcon: Icon(Icons.security),
                  hintText: 'e.g. 100',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PaymentType>(
                value: _paymentType,
                decoration: const InputDecoration(labelText: 'Due / Interest'),
                items: PaymentType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _paymentType = v);
                },
              ),
              const SizedBox(height: 16),
              if (_paymentType == PaymentType.due)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextFormField(
                    controller: _numberOfDuesController,
                    decoration: const InputDecoration(labelText: 'No of Due (Weeks/Months)'),
                    keyboardType: TextInputType.number,
                    validator: (v) => _paymentType == PaymentType.due && (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                ),
              DropdownButtonFormField<CollectionType>(
                value: _collectionType,
                decoration: const InputDecoration(labelText: 'Collection Frequency'),
                items: CollectionType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _collectionType = v);
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text("Debt-U Status (Defaulter / Special Flag)"),
                subtitle: const Text("Mark if borrower has overdue debt status"),
                value: _isDebtU,
                activeColor: Colors.red,
                onChanged: (val) => setState(() => _isDebtU = val),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Start Date"),
                subtitle: Text(DateFormat.yMMMd().format(_startDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _startDate = picked);
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveParty,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save Party"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
