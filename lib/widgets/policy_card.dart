import 'package:flutter/material.dart';
import 'package:postal_deposit/features/policy/domain/entities/policy_entity.dart';
import 'package:intl/intl.dart';

class PolicyCard extends StatelessWidget {
  final VoidCallback? onTap;
  final PolicyEntity entry;

  const PolicyCard({super.key, required this.entry, this.onTap});

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  String _formatCurrency(double amount) {
    return '₹${NumberFormat('#,##0').format(amount)}';
  }

  String _formatPremiumFrequency(PremiumFrequency frequency) {
    switch (frequency) {
      case PremiumFrequency.monthly:
        return 'Monthly';
      case PremiumFrequency.quarterly:
        return 'Quarterly';
      case PremiumFrequency.halfYearly:
        return 'Half Yearly';
      case PremiumFrequency.annual:
        return 'Annual';
      case PremiumFrequency.single:
        return 'Single Premium';
      default:
        return frequency.toString().split('.').last;
    }
  }

  Color _getStatusColor() {
    // Add your status logic here if needed
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Policy Number and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Policy #${entry.policyNumber}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Active',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Policy Holder and Product Info
              _buildInfoSection(theme),

              const Divider(height: 24, thickness: 1),

              // Financial Info
              _buildFinancialSection(theme),

              const SizedBox(height: 12),

              // Additional Details
              _buildDetailChips(theme),

              if (onTap != null) _buildViewDetailsButton(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(ThemeData theme) {
    return Column(
      children: [
        _buildInfoRow(
          icon: Icons.person_outline,
          label: 'Policy Holder',
          value: entry.insured,
          theme: theme,
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          icon: Icons.description_outlined,
          label: 'Product',
          value: entry.productName,
          theme: theme,
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          icon: Icons.calendar_month_outlined,
          label: 'Issued On',
          value: _formatDate(entry.issueDate),
          theme: theme,
        ),
        const SizedBox(height: 4),
        _buildInfoRow(
          icon: Icons.cake_outlined,
          label: 'Date of Birth',
          value: _formatDate(entry.insuredDateOfBirth),
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildFinancialSection(ThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildFinancialInfo(
                'Sum Assured',
                _formatCurrency(entry.sumAssured),
                Icons.account_balance_wallet_outlined,
                const Color(0xFF2E7D32),
                theme,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFinancialInfo(
                'Premium',
                _formatCurrency(entry.premiumAmt),
                Icons.payments_outlined,
                const Color(0xFF1976D2),
                theme,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailChips(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildDetailChip(
          Icons.timelapse,
          '${_formatPremiumFrequency(entry.premiumFrequency)}',
          theme,
        ),
        _buildDetailChip(Icons.payment, '${entry.paymentMode}', theme),
      ],
    );
  }

  Widget _buildViewDetailsButton(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          'View Details →',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialInfo(
    String label,
    String value,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}
