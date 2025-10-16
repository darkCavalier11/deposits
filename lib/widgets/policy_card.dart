import 'package:flutter/material.dart';
import 'package:postal_deposit/features/policy/domain/entities/policy_entity.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

// Constants for styling
const _kCardPadding = 16.0;
const _kCardElevation = 2.0;
const _kCardRadius = 12.0;
const _kElementSpacing = 8.0;
const _kSectionSpacing = 16.0;

class PolicyCard extends StatefulWidget {
  final PolicyEntity entry;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final Function(PolicyEntity)? onUpdate;
  final Function(PolicyEntity, DateTime)? onMakePayment;
  final bool showDelete;

  const PolicyCard({
    super.key,
    required this.entry,
    this.onTap,
    this.onDelete,
    this.onUpdate,
    this.onMakePayment,
    this.showDelete = true,
  });

  @override
  State<PolicyCard> createState() => _PolicyCardState();
}

class _PolicyCardState extends State<PolicyCard> {
  late final TextEditingController _nameController;
  late final TextEditingController _productController;
  late PremiumFrequency _selectedFrequency;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.entry.insured);
    _productController = TextEditingController(text: widget.entry.productName);
    _selectedFrequency = widget.entry.premiumFrequency;
  }

  @override
  void didUpdateWidget(covariant PolicyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry != widget.entry) {
      _nameController.text = widget.entry.insured;
      _productController.text = widget.entry.productName;
      _selectedFrequency = widget.entry.premiumFrequency;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _productController.dispose();
    super.dispose();
  }

  bool get _isPolicyPaid {
    if (widget.entry.paidUntil == null) return false;
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final paidUntilMonth = DateTime(
      widget.entry.paidUntil!.year,
      widget.entry.paidUntil!.month,
    );
    return paidUntilMonth.isAfter(currentMonth) ||
        paidUntilMonth.isAtSameMomentAs(currentMonth);
  }

  Future<void> _showMakePaymentDialog() async {
    final now = DateTime.now();
    PremiumFrequency selectedFrequency = widget.entry.premiumFrequency;
    DateTime paidUntilDate = _calculatePaidUntil(now, selectedFrequency);

    // Show frequency selection dialog
    final confirmedFrequency = await showDialog<PremiumFrequency>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Select Payment Frequency'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<PremiumFrequency>(
                  value: selectedFrequency,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: PremiumFrequency.values.map((frequency) {
                    return DropdownMenuItem(
                      value: frequency,
                      child: Text(
                        _formatPremiumFrequency(frequency),
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedFrequency = value;
                        paidUntilDate = _calculatePaidUntil(now, value);
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Amount: ${_formatCurrency(widget.entry.premiumAmt)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, selectedFrequency),
                child: const Text('NEXT'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmedFrequency == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Text(
          '${widget.entry.insured} will be paid until ${_formatDate(paidUntilDate, monthYearOnly: true)}\n\n'
          'Amount: ${_formatCurrency(widget.entry.premiumAmt)}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('CONFIRM PAYMENT'),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.onMakePayment != null) {
      widget.onMakePayment!(widget.entry, paidUntilDate);
    }
  }

  DateTime _calculatePaidUntil(DateTime fromDate, PremiumFrequency frequency) {
    switch (frequency) {
      case PremiumFrequency.monthly:
        return DateTime(fromDate.year, fromDate.month + 1, fromDate.day);
      case PremiumFrequency.quarterly:
        return DateTime(fromDate.year, fromDate.month + 3, fromDate.day);
      case PremiumFrequency.halfYearly:
        return DateTime(fromDate.year, fromDate.month + 6, fromDate.day);
      case PremiumFrequency.annual:
        return DateTime(fromDate.year + 1, fromDate.month, fromDate.day);
      case PremiumFrequency.single:
        // For single payment, set to a far future date (100 years)
        return DateTime(fromDate.year + 100, fromDate.month, fromDate.day);
    }
  }

  void _showEditDialog() {
    // Update controllers with current values
    _nameController.text = widget.entry.insured;
    _productController.text = widget.entry.productName;
    _selectedFrequency = widget.entry.premiumFrequency;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Policy'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Policy Holder Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.trim().isEmpty ?? true
                      ? 'Name cannot be empty'
                      : null,
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(
                      RegExp(r'\s{2,}'),
                    ), // Prevent multiple spaces
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _productController,
                  decoration: const InputDecoration(
                    labelText: 'Product Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.trim().isEmpty ?? true
                      ? 'Product name cannot be empty'
                      : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<PremiumFrequency>(
                  value: _selectedFrequency,
                  decoration: const InputDecoration(
                    labelText: 'Premium Frequency',
                    border: OutlineInputBorder(),
                  ),
                  items: PremiumFrequency.values.map((frequency) {
                    return DropdownMenuItem(
                      value: frequency,
                      child: Text(
                        _formatPremiumFrequency(frequency),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedFrequency = value);
                    }
                  },
                  validator: (value) =>
                      value == null ? 'Please select a frequency' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                final updatedPolicy = widget.entry.copyWith(
                  insured: _nameController.text.trim(),
                  productName: _productController.text.trim(),
                  premiumFrequency: _selectedFrequency,
                );
                widget.onUpdate?.call(updatedPolicy);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Policy updated successfully'),
                    ),
                  );
                }
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date, {bool monthYearOnly = false}) {
    if (monthYearOnly) {
      return DateFormat('MMM yyyy').format(date);
    }
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
      // Removed default case as all enum values are covered
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Policy'),
        content: Text(
          'Are you sure you want to delete policy #${widget.entry.policyNumber}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.onDelete != null) {
      widget.onDelete!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isPaid = _isPolicyPaid;

    return Card(
      elevation: _kCardElevation,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_kCardRadius),
        side: BorderSide(
          color: isPaid
              ? colorScheme.primary.withOpacity(0.2)
              : colorScheme.error.withOpacity(0.2),
          width: 1.5,
        ),
      ),

      child: Stack(
        children: [
          InkWell(
            onTap: widget.onTap != null
                ? widget.onTap
                : () {}, // Fix undefined name
            borderRadius: BorderRadius.circular(_kCardRadius),
            child: Container(
              padding: const EdgeInsets.all(_kCardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Policy #${widget.entry.policyNumber}',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.showDelete &&
                          (widget.onDelete != null || widget.onUpdate != null))
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.onUpdate != null)
                              IconButton(
                                icon: Icon(
                                  Icons.edit_outlined,
                                  size: 20,
                                  color: colorScheme.primary,
                                ),
                                onPressed: _showEditDialog,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Edit policy',
                                style: IconButton.styleFrom(
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            if (widget.onDelete != null)
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: colorScheme.error,
                                ),
                                onPressed: _showDeleteConfirmation,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Delete policy',
                              ),
                          ],
                        ),
                    ],
                  ),

                  const SizedBox(height: _kSectionSpacing),

                  // Policy Info Section
                  _buildInfoSection(theme),

                  const SizedBox(height: _kSectionSpacing),

                  // Financial Summary
                  _buildFinancialSection(theme),

                  const SizedBox(height: _kSectionSpacing),

                  // Tags and Actions
                  Row(
                    children: [
                      // Status and Frequency Chips
                      Expanded(
                        child: Wrap(
                          spacing: _kElementSpacing,
                          runSpacing: _kElementSpacing,
                          children: [
                            _buildStatusChip(theme),
                            _buildFrequencyChip(theme),
                          ],
                        ),
                      ),

                      // Payment Button
                      if (widget.onMakePayment != null)
                        _buildPaymentButton(theme),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(ThemeData theme) {
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.person_outline,
            label: 'Policy Holder',
            value: widget.entry.insured,
            theme: theme,
          ),
          const SizedBox(height: _kElementSpacing),
          _buildInfoRow(
            icon: Icons.description_outlined,
            label: 'Product',
            value: widget.entry.productName,
            theme: theme,
          ),
          const SizedBox(height: _kElementSpacing),
          Row(
            children: [
              Expanded(
                child: _buildInfoRow(
                  icon: Icons.calendar_month_outlined,
                  label: 'Issued On',
                  value: _formatDate(widget.entry.issueDate),
                  theme: theme,
                ),
              ),
              const SizedBox(width: _kSectionSpacing),
              Expanded(
                child: _buildInfoRow(
                  icon: Icons.cake_outlined,
                  label: 'Date of Birth',
                  value: _formatDate(widget.entry.insuredDateOfBirth),
                  theme: theme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSection(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isPaid = _isPolicyPaid;

    return Row(
      children: [
        Expanded(
          child: _buildFinancialItem(
            title: 'Sum Assured',
            value: _formatCurrency(widget.entry.sumAssured),
            icon: Icons.account_balance_wallet_outlined,
            color: colorScheme.primary,
            theme: theme,
          ),
        ),
        const SizedBox(width: _kElementSpacing),
        Expanded(
          child: _buildFinancialItem(
            title: 'Premium',
            value: _formatCurrency(widget.entry.premiumAmt),
            icon: Icons.payments_outlined,
            color: colorScheme.secondary,
            theme: theme,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(ThemeData theme) {
    if (widget.entry.paidUntil == null) return const SizedBox.shrink();

    final isPaid = _isPolicyPaid;
    final statusText = isPaid ? 'DUE ON' : 'DUE';
    final statusColor = isPaid
        ? theme.colorScheme.primary
        : theme.colorScheme.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPaid
            ? statusColor.withOpacity(0.1)
            : statusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPaid ? Icons.check_circle : Icons.warning_amber_rounded,
            size: 14,
            color: statusColor,
          ),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: theme.textTheme.labelSmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          if (isPaid) ...[
            const SizedBox(width: 4),
            Text(
              _formatDate(widget.entry.paidUntil!, monthYearOnly: true),
              style: theme.textTheme.labelSmall?.copyWith(
                color: statusColor.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFrequencyChip(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.repeat,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            _formatPremiumFrequency(widget.entry.premiumFrequency),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentButton(ThemeData theme) {
    if (widget.onMakePayment == null) return const SizedBox.shrink();

    final isPaid = _isPolicyPaid;

    if (isPaid) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              'PAID',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return FilledButton.icon(
      onPressed: _showMakePaymentDialog,
      icon: const Icon(Icons.payment_outlined, size: 16),
      label: const Text('PAY NOW'),
      style: FilledButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onError,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

  Widget _buildFinancialItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
