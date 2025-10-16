import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:postal_deposit/features/policy/presentation/widgets/import_policy_button.dart';

class ImportExcelButton extends StatelessWidget {
  final VoidCallback? onImported;

  const ImportExcelButton({super.key, this.onImported});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            CupertinoIcons.list_bullet,
            size: 80,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome to Postal Deposit',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Get started by importing your policy data from a CSV or Excel file',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
            ),
          ),
          const SizedBox(height: 32),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 250),
            child: ImportPolicyButton(onImported: onImported),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              _showFileFormatHelp(context);
            },
            icon: const Icon(Icons.help_outline),
            label: const Text('How to format your file'),
          ),
        ],
      ),
    );
  }

  void _showFileFormatHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('File Format Guide'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Your CSV/Excel file should include the following columns:',
              ),
              const SizedBox(height: 16),
              _buildHelpRow('Policy Number', 'Unique policy identifier'),
              _buildHelpRow('Insured Name', 'Name of the policyholder'),
              _buildHelpRow('Sum Assured', 'Policy coverage amount'),
              _buildHelpRow('Premium Amount', 'Regular payment amount'),
              _buildHelpRow('Premium Frequency', 'Monthly/Quarterly/Yearly'),
              _buildHelpRow('Product Name', 'Name of the insurance product'),
              _buildHelpRow('Payment Mode', 'Payment method'),
              _buildHelpRow('Issue Date', 'Policy start date (DD/MM/YYYY)'),
              _buildHelpRow(
                'Date of Birth',
                'Policyholder\'s DOB (DD/MM/YYYY)',
              ),
              const SizedBox(height: 16),
              const Text('The first row should contain column headers.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpRow(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• $title:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(description)),
        ],
      ),
    );
  }
}
