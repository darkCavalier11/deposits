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

  Future<void> _showMakePaymentDialog() async {
    PremiumFrequency? selectedFrequency = widget.entry.premiumFrequency;
    final now = DateTime.now();
    DateTime? paidUntilDate;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Make Payment'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select payment frequency:'),
                const SizedBox(height: 16),
                DropdownButtonFormField<PremiumFrequency>(
                  value: selectedFrequency,
                  items: PremiumFrequency.values.map((frequency) {
                    return DropdownMenuItem(
                      value: frequency,
                      child: Text(_formatPremiumFrequency(frequency)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedFrequency = value;
                        // Calculate paid until date based on selected frequency
                        paidUntilDate = _calculatePaidUntil(now, value);
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                if (paidUntilDate != null)
                  Text(
                    'This payment will cover until: ${_formatDate(paidUntilDate!)}\n'
                    'Amount: ${_formatCurrency(widget.entry.premiumAmt)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('CONFIRM PAYMENT'),
          ),
        ],
      ),
    );

    if (confirmed == true &&
        paidUntilDate != null &&
        widget.onMakePayment != null) {
      widget.onMakePayment!(widget.entry, paidUntilDate!);
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

    return Card(
      elevation: _kCardElevation,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_kCardRadius),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
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
                      if (widget.onMakePayment != null) _buildPaymentButton(theme),
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
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
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
    
    return Text(
      'Paid until: ${_formatDate(widget.entry.paidUntil!, monthYearOnly: true)}',
      style: theme.textTheme.bodySmall?.copyWith(
        color: Colors.green[700],
        fontWeight: FontWeight.w500,
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
    
    return TextButton.icon(
      onPressed: _showMakePaymentDialog,
      icon: const Icon(Icons.payment_outlined, size: 16),
      label: const Text('MAKE PAYMENT'),
      style: TextButton.styleFrom(foregroundColor: Colors.green),
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
