import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:postal_deposit/features/policy/domain/entities/policy_entity.dart';
import 'package:postal_deposit/features/policy/domain/entities/policy_filter.dart';
import 'package:postal_deposit/features/policy/presentation/pages/add_policy_page.dart';

import 'core/storage/hive_service.dart';
import 'features/person/data/repositories/person_repository_impl.dart';
import 'features/person/domain/repositories/person_repository.dart';
import 'features/person/domain/entities/person_entity.dart';
import 'features/person/presentation/providers/person_provider.dart';
import 'features/policy/data/repositories/policy_repository_impl.dart';
import 'features/policy/domain/repositories/policy_repository.dart';
import 'features/policy/presentation/providers/policy_provider.dart';
import 'features/policy/presentation/widgets/import_excel_button.dart';
import 'widgets/policy_card.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await HiveService.init();

  runApp(
    MultiProvider(
      providers: [
        // Repositories
        Provider<PersonRepository>(create: (_) => PersonRepositoryImpl()),
        Provider<PolicyRepository>(
          create: (context) =>
              PolicyRepositoryImpl(context.read<PersonRepository>()),
        ),

        // Providers
        ChangeNotifierProvider(
          create: (context) =>
              PolicyProvider(context.read<PolicyRepository>())..loadPolicies(),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              PersonProvider(context.read<PersonRepository>())..loadPerson(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Postal Deposit',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.greenAccent, // Darker green
        ),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
      home: const MyHomePage(title: 'Postal Deposits'),
      debugShowCheckedModeBanner: false,
    );
  }
}

String _formatDate(DateTime date) {
  return DateFormat('dd/MM/yyyy').format(date);
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    // Load policies when the widget is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PolicyProvider>().loadPolicies();
    });
  }

  Future<void> _navigateToAddPolicy(
    BuildContext context,
    PolicyProvider policyProvider,
  ) async {
    final result = await Navigator.push<PolicyEntity>(
      context,
      MaterialPageRoute(builder: (context) => const AddPolicyPage()),
    );

    if (result != null && context.mounted) {
      try {
        // Add the new policy
        await policyProvider.addPolicy(result);

        // Get the latest policies after adding
        final policies = policyProvider.policies;

        // Update person's statistics
        final personProvider = context.read<PersonProvider>();
        if (personProvider.hasPerson) {
          final totalSumAssured = policies.fold<double>(
            0,
            (sum, policy) => sum + policy.sumAssured,
          );
          final totalPremiumAssured = policies.fold<double>(
            0,
            (sum, policy) => sum + policy.premiumAmt,
          );
          final policyCount = policies.length;

          // Create an updated person with new stats
          final updatedPerson = personProvider.person!.copyWith(
            totalSumAssured: totalSumAssured,
            totalPremiumAssured: totalPremiumAssured,
            policyCount: policyCount,
          );

          // Save the updated person
          await personProvider.savePerson(updatedPerson);

          // Force a refresh of the person data
          await personProvider.loadPerson();
        }

        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Policy added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating person data: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _exportToCsv(
    BuildContext context,
    PolicyProvider policyProvider,
  ) async {
    final policies = policyProvider.policies;

    if (policies.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No policies to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Create CSV content
      final csvContent = StringBuffer();

      // Add header
      csvContent.writeln(
        'Policy Number,Insured,Product,Sum Assured,Premium,Payment Mode,Issue Date,DOB,Status',
      );

      // Add data rows
      for (final policy in policies) {
        csvContent.writeln(
          [
            policy.policyNumber,
            policy.insured,
            policy.productName,
            policy.sumAssured.toString(),
            policy.premiumAmt.toString(),
            policy.paymentMode,
            _formatDate(policy.issueDate),
            _formatDate(policy.insuredDateOfBirth),
            policy.paidUntil != null &&
                    policy.paidUntil!.isAfter(DateTime.now())
                ? 'Active'
                : 'Inactive',
          ].map((field) => '"$field"').join(','),
        );
      }

      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}/policies_export_${DateTime.now().millisecondsSinceEpoch}.csv',
      );

      // Write to file
      await file.writeAsString(csvContent.toString());

      // Share the file
      if (context.mounted) {
        await Share.shareFiles(
          [file.path],
          subject: 'Policies Export',
          text: 'Here is the exported policies data',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting to CSV: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final policyProvider = context.watch<PolicyProvider>();
    final personProvider = context.watch<PersonProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(
          widget.title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          if (policyProvider.hasPolicies) ...[
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white, size: 24),
              onPressed: () => _exportToCsv(context, policyProvider),
              tooltip: 'Export to CSV',
            ),
            const SizedBox(width: 8),
          ],
          if (policyProvider.hasPolicies)
            IconButton(
              icon: const Icon(Icons.filter_alt_outlined, color: Colors.white),
              onPressed: () => _showFilterDialog(context, policyProvider),
              tooltip: 'Filter Policies',
            ),
          if (personProvider.hasPerson || policyProvider.hasPolicies)
            IconButton(
              icon: const Icon(
                Icons.person_outline,
                size: 28,
                color: Colors.white,
              ),
              onPressed: () => _showPersonDetails(context, personProvider),
              tooltip: 'Agent Details',
            ),
        ],
      ),
      body: _buildBody(context, policyProvider, personProvider),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: () => _navigateToAddPolicy(context, policyProvider),
            backgroundColor: Theme.of(context).primaryColor,
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    PolicyProvider policyProvider,
    PersonProvider personProvider,
  ) {
    if (policyProvider.isLoading && !policyProvider.hasPolicies) {
      return const Center(child: CircularProgressIndicator());
    }

    if (policyProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error: ${policyProvider.error}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: policyProvider.loadPolicies,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (!policyProvider.hasPolicies) {
      if (personProvider.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      if (personProvider.hasPerson) {
        return _buildPersonView(context, personProvider);
      }

      return ImportExcelButton(
        onImported: () {
          // Refresh the person data after import
          final personProvider = context.read<PersonProvider>();
          personProvider.loadPerson();
        },
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search by policy holder name...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              filled: true,
              fillColor: Colors.transparent,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
            ),

            onChanged: (value) {
              policyProvider.setSearchQuery(value);
            },
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => policyProvider.loadPolicies(),
            child:
                policyProvider.policies.isEmpty &&
                    policyProvider.searchQuery.isNotEmpty
                ? Center(
                    child: Text(
                      'No policies found for "${policyProvider.searchQuery}"',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    itemCount: policyProvider.policies.length,
                    itemBuilder: (context, index) {
                      final entry = policyProvider.policies[index];
                      return PolicyCard(
                        entry: entry,
                        onDelete: () async {
                          final policyProvider = context.read<PolicyProvider>();
                          final personProvider = context.read<PersonProvider>();
                          
                          final success = await policyProvider.deletePolicy(entry.policyNumber);
                          
                          if (success && context.mounted) {
                            // Update person's statistics after successful deletion
                            if (personProvider.hasPerson) {
                              final policies = policyProvider.policies;
                              final totalSumAssured = policies.fold<double>(
                                0,
                                (sum, policy) => sum + policy.sumAssured,
                              );
                              final totalPremiumAssured = policies.fold<double>(
                                0,
                                (sum, policy) => sum + policy.premiumAmt,
                              );
                              final policyCount = policies.length;

                              // Create an updated person with new stats
                              final updatedPerson = personProvider.person!.copyWith(
                                totalSumAssured: totalSumAssured,
                                totalPremiumAssured: totalPremiumAssured,
                                policyCount: policyCount,
                              );

                              // Save the updated person
                              await personProvider.savePerson(updatedPerson);
                              
                              // Force a refresh of the person data
                              await personProvider.loadPerson();
                            }
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Policy deleted successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        onUpdate: (updatedPolicy) async {
                          final success = await context
                              .read<PolicyProvider>()
                              .updatePolicy(updatedPolicy);
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Policy updated successfully'),
                              ),
                            );
                          } else if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to update policy'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        onMakePayment: (policy, paidUntil) async {
                          final updatedPolicy = policy.copyWith(
                            paidUntil: paidUntil,
                          );
                          final success = await context
                              .read<PolicyProvider>()
                              .updatePolicy(updatedPolicy);

                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Payment recorded successfully! Valid until ${_formatDate(paidUntil)}',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to record payment'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonView(BuildContext context, PersonProvider personProvider) {
    final person = personProvider.person!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person, size: 64, color: Colors.blue),
                const SizedBox(height: 16),
                Text(
                  person.agentName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Agent ID: ${person.agentId}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatColumn(
                      context,
                      'Policies',
                      person.policyCount.toString(),
                      Icons.description,
                    ),
                    _buildStatColumn(
                      context,
                      'Total Sum',
                      '₹${person.totalSumAssured.toStringAsFixed(2)}',
                      Icons.account_balance_wallet,
                    ),
                    _buildStatColumn(
                      context,
                      'Total Premium',
                      '₹${person.totalPremiumAssured.toStringAsFixed(2)}',
                      Icons.payments,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Active Period: ${_formatDate(person.issuedDateFrom)} - ${_formatDate(person.issuedDateTo)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () =>
                      _showEditPersonDialog(context, personProvider, person),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Agent Details'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonSummary(
    BuildContext context,
    PersonProvider personProvider,
  ) {
    final person = personProvider.person!;

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const Icon(Icons.person_outline, size: 32, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.agentName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'ID: ${person.agentId} • ${person.policyCount} policies',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              '₹${person.totalSumAssured.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Future<void> _showPersonDetails(
    BuildContext context,
    PersonProvider personProvider,
  ) async {
    if (!personProvider.hasPerson) return;

    final theme = Theme.of(context);
    final person = personProvider.person!;
    final colorScheme = theme.colorScheme;

    // Format currency with Indian Rupee symbol
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_outline_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              person.agentName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ID: ${person.agentId}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Active Period Card
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.calendar_today_rounded,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Active Period',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_formatDate(person.issuedDateFrom)} - ${_formatDate(person.issuedDateTo)}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Stats Grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _buildStatCard(
                          context,
                          title: 'Sum Assured',
                          value: currencyFormat.format(person.totalSumAssured),
                          icon: Icons.account_balance_wallet_rounded,
                          color: colorScheme.primary,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _buildStatCard(
                          context,
                          title: 'Total Premium',
                          value: currencyFormat.format(
                            person.totalPremiumAssured,
                          ),
                          icon: Icons.payments_rounded,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildStatCard(
                    context,
                    title: 'Total Policies',
                    value: '${person.policyCount}',
                    icon: Icons.description_rounded,
                    color: Colors.blue.shade600,
                    isFullWidth: true,
                  ),
                ),

                const SizedBox(height: 24),

                // Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'CLOSE',
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showEditPersonDialog(
                              context,
                              personProvider,
                              person,
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'EDIT DETAILS',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isFullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              if (isFullWidth) const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditPersonDialog(
    BuildContext context,
    PersonProvider personProvider,
    PersonEntity person,
  ) async {
    final nameController = TextEditingController(text: person.agentName);
    final idController = TextEditingController(text: person.agentId);
    final fromController = TextEditingController(
      text:
          '${person.issuedDateFrom.year}-${person.issuedDateFrom.month.toString().padLeft(2, '0')}-${person.issuedDateFrom.day.toString().padLeft(2, '0')}',
    );
    final toController = TextEditingController(
      text:
          '${person.issuedDateTo.year}-${person.issuedDateTo.month.toString().padLeft(2, '0')}-${person.issuedDateTo.day.toString().padLeft(2, '0')}',
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Agent Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Agent Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: idController,
                decoration: const InputDecoration(
                  labelText: 'Agent ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: fromController,
                decoration: const InputDecoration(
                  labelText: 'From Date (YYYY-MM-DD)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: toController,
                decoration: const InputDecoration(
                  labelText: 'To Date (YYYY-MM-DD)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final updatedPerson = PersonEntity(
                  agentName: nameController.text.trim(),
                  agentId: idController.text.trim(),
                  issuedDateFrom: DateTime.parse(fromController.text),
                  issuedDateTo: DateTime.parse(toController.text),
                  totalSumAssured: person.totalSumAssured,
                  totalPremiumAssured: person.totalPremiumAssured,
                  policyCount: person.policyCount,
                );
                await personProvider.savePerson(updatedPerson);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating agent: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showFilterDialog(
    BuildContext context,
    PolicyProvider policyProvider,
  ) async {
    final currentFilter = policyProvider.currentFilter;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Policies'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterOption(
              context,
              title: 'Show All',
              isSelected: currentFilter == PolicyFilter.all,
              onTap: () {
                policyProvider.setFilter(PolicyFilter.all);
                Navigator.pop(context);
              },
            ),
            const Divider(height: 1),
            _buildFilterOption(
              context,
              title: 'Show Paid',
              isSelected: currentFilter == PolicyFilter.paid,
              onTap: () {
                policyProvider.setFilter(PolicyFilter.paid);
                Navigator.pop(context);
              },
            ),
            const Divider(height: 1),
            _buildFilterOption(
              context,
              title: 'Show Unpaid',
              isSelected: currentFilter == PolicyFilter.unpaid,
              onTap: () {
                policyProvider.setFilter(PolicyFilter.unpaid);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(
    BuildContext context, {
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(title),
      trailing: isSelected
          ? const Icon(Icons.check, color: Colors.green)
          : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      minVerticalPadding: 0,
      dense: true,
      tileColor: isSelected
          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    );
  }

  Future<void> _showClearConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Policies'),
        content: const Text(
          'Are you sure you want to delete all policies? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete All',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<PolicyProvider>().clearPolicies();
    }
  }
}
