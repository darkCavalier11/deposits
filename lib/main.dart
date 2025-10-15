import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

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
        Provider<PolicyRepository>(create: (_) => PolicyRepositoryImpl()),
        Provider<PersonRepository>(create: (_) => PersonRepositoryImpl()),

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
          seedColor: const Color(0xFF2E7D32), // Darker green
          primary: const Color(0xFF2E7D32),
          secondary: const Color(0xFF4CAF50),
          surfaceTint: Colors.white,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 4,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            elevation: 3,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
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
      home: const MyHomePage(title: 'POSTAL DEPOSIT'),
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

  @override
  Widget build(BuildContext context) {
    final policyProvider = context.watch<PolicyProvider>();
    final personProvider = context.watch<PersonProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(widget.title),
        actions: [
          if (policyProvider.hasPolicies)
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () => _showPersonDetails(context, personProvider),
              tooltip: 'Agent Details',
            ),
          if (policyProvider.hasPolicies)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: policyProvider.isLoading
                  ? null
                  : () => _showClearConfirmation(context),
              tooltip: 'Clear All Policies',
            ),
        ],
      ),
      body: _buildBody(context, policyProvider, personProvider),
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

      return const ImportExcelButton();
    }

    return Column(
      children: [
        if (personProvider.hasPerson)
          _buildPersonSummary(context, personProvider),
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search by policy holder name...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              filled: true,
              fillColor: Colors.grey[100],
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
                          final success = await context
                              .read<PolicyProvider>()
                              .deletePolicy(entry.policyNumber);
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Policy deleted successfully'),
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

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agent Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Name'),
                subtitle: Text(personProvider.person!.agentName),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.credit_card),
                title: const Text('Agent ID'),
                subtitle: Text(personProvider.person!.agentId),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.date_range),
                title: const Text('Active Period'),
                subtitle: Text(
                  '${_formatDate(personProvider.person!.issuedDateFrom)} - ${_formatDate(personProvider.person!.issuedDateTo)}',
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet),
                title: const Text('Total Sum Assured'),
                trailing: Text(
                  '₹${personProvider.person!.totalSumAssured.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.payments),
                title: const Text('Total Premium'),
                trailing: Text(
                  '₹${personProvider.person!.totalPremiumAssured.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Total Policies'),
                trailing: Text(
                  '${personProvider.person!.policyCount}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditPersonDialog(
                context,
                personProvider,
                personProvider.person!,
              );
            },
            child: const Text('Edit'),
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
