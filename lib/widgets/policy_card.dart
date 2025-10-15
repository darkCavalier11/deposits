import 'package:flutter/material.dart';
import '../features/policy/domain/entities/policy_entity.dart';
import 'policy_info_row.dart';

class PolicyCard extends StatelessWidget {
  final PolicyEntity entry;
  final VoidCallback? onTap;

  const PolicyCard({
    Key? key,
    required this.entry,
    this.onTap,
  }) : super(key: key);

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 8),
              const Divider(height: 1, color: Colors.grey),
              const SizedBox(height: 4),
              _buildPolicyDetails(),
              const SizedBox(height: 8),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.policy,
            size: 28,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            entry.productName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 0.2,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).primaryColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Text(
            entry.premiumFrequency.name.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPolicyDetails() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PolicyInfoRow(
                label: 'Policy Number',
                value: entry.policyNumber,
                icon: Icons.numbers,
              ),
              const SizedBox(height: 8),
              PolicyInfoRow(
                label: 'Insured',
                value: entry.insured,
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 8),
              PolicyInfoRow(
                label: 'Date of Birth',
                value: _formatDate(entry.insuredDateOfBirth),
                icon: Icons.cake_outlined,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PolicyInfoRow(
                label: 'Sum Assured',
                value: '₹${entry.sumAssured.toStringAsFixed(2)}',
                icon: Icons.account_balance_wallet_outlined,
                valueColor: Colors.green[700],
              ),
              const SizedBox(height: 8),
              PolicyInfoRow(
                label: 'Premium',
                value: '₹${entry.premiumAmt.toStringAsFixed(2)}',
                icon: Icons.payments_outlined,
                valueColor: Colors.blue[700],
              ),
              const SizedBox(height: 8),
              PolicyInfoRow(
                label: 'Payment Mode',
                value: entry.paymentMode,
                icon: Icons.credit_card_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        Icon(
          Icons.calendar_month_outlined,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 6),
        Text(
          'Issued ${_formatDate(entry.issueDate)}',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
