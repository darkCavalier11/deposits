import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:postal_deposit/features/policy/domain/entities/policy_entity.dart';

class AddPolicyPage extends StatefulWidget {
  const AddPolicyPage({super.key});

  @override
  State<AddPolicyPage> createState() => _AddPolicyPageState();
}

class _AddPolicyPageState extends State<AddPolicyPage> {
  final _formKey = GlobalKey<FormState>();
  final _policyNumberController = TextEditingController();
  final _insuredNameController = TextEditingController();
  final _sumAssuredController = TextEditingController();
  final _premiumAmountController = TextEditingController();
  final _productNameController = TextEditingController();
  final _paymentModeController = TextEditingController();
  
  DateTime _issueDate = DateTime.now();
  DateTime _insuredDateOfBirth = DateTime.now().subtract(const Duration(days: 365 * 25));
  DateTime? _paidUntil;
  PremiumFrequency _premiumFrequency = PremiumFrequency.monthly;

  final List<PremiumFrequency> _premiumFrequencies = PremiumFrequency.values;

  @override
  void dispose() {
    _policyNumberController.dispose();
    _insuredNameController.dispose();
    _sumAssuredController.dispose();
    _premiumAmountController.dispose();
    _productNameController.dispose();
    _paymentModeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(
      BuildContext context, String fieldName) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: fieldName == 'issueDate' ? _issueDate : _insuredDateOfBirth,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    
    if (picked != null) {
      setState(() {
        if (fieldName == 'issueDate') {
          _issueDate = picked;
        } else if (fieldName == 'dob') {
          _insuredDateOfBirth = picked;
        } else if (fieldName == 'paidUntil') {
          _paidUntil = picked;
        }
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      // Create new policy object
      final newPolicy = PolicyEntity(
        policyNumber: _policyNumberController.text.trim(),
        insured: _insuredNameController.text.trim(),
        sumAssured: double.tryParse(_sumAssuredController.text) ?? 0.0,
        premiumAmt: double.tryParse(_premiumAmountController.text) ?? 0.0,
        premiumFrequency: _premiumFrequency,
        productName: _productNameController.text.trim(),
        paymentMode: _paymentModeController.text.trim(),
        issueDate: _issueDate,
        insuredDateOfBirth: _insuredDateOfBirth,
        paidUntil: _paidUntil,
      );

      // Return the new policy to the previous screen
      Navigator.of(context).pop(newPolicy);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Policy'),
        actions: [
          TextButton(
            onPressed: _submitForm,
            child: const Text(
              'SAVE',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Policy Number
              TextFormField(
                controller: _policyNumberController,
                decoration: const InputDecoration(
                  labelText: 'Policy Number *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter policy number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Insured Name
              TextFormField(
                controller: _insuredNameController,
                decoration: const InputDecoration(
                  labelText: 'Insured Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter insured name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Sum Assured
              TextFormField(
                controller: _sumAssuredController,
                decoration: const InputDecoration(
                  labelText: 'Sum Assured (₹) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter sum assured';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Premium Amount
              TextFormField(
                controller: _premiumAmountController,
                decoration: const InputDecoration(
                  labelText: 'Premium Amount (₹) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter premium amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Product Name
              TextFormField(
                controller: _productNameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Payment Mode
              TextFormField(
                controller: _paymentModeController,
                decoration: const InputDecoration(
                  labelText: 'Payment Mode *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payment),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter payment mode';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Premium Frequency
              DropdownButtonFormField<PremiumFrequency>(
                value: _premiumFrequency,
                decoration: const InputDecoration(
                  labelText: 'Premium Frequency *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.update),
                ),
                items: _premiumFrequencies.map((freq) {
                  return DropdownMenuItem<PremiumFrequency>(
                    value: freq,
                    child: Text(
                      freq.toString().split('.').last.toUpperCase(),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _premiumFrequency = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              
              // Issue Date
              ListTile(
                title: const Text('Issue Date *'),
                subtitle: Text(DateFormat('dd MMM yyyy').format(_issueDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, 'issueDate'),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.grey, width: 0.5),
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
              const SizedBox(height: 16),
              
              // Insured Date of Birth
              ListTile(
                title: const Text('Date of Birth *'),
                subtitle: Text(DateFormat('dd MMM yyyy').format(_insuredDateOfBirth)),
                trailing: const Icon(Icons.cake),
                onTap: () => _selectDate(context, 'dob'),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.grey, width: 0.5),
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
              const SizedBox(height: 16),
              
              // Paid Until (Optional)
              ListTile(
                title: const Text('Paid Until (Optional)'),
                subtitle: Text(
                  _paidUntil == null 
                    ? 'Select paid until date' 
                    : DateFormat('dd MMM yyyy').format(_paidUntil!),
                ),
                trailing: const Icon(Icons.calendar_month),
                onTap: () => _selectDate(context, 'paidUntil'),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.grey, width: 0.5),
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
              const SizedBox(height: 24),
              
              // Submit Button
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                child: const Text(
                  'SAVE POLICY',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Required fields note
              const Text(
                '* Required fields',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                  fontSize: 12,
                ),
                textAlign: TextAlign.end,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
