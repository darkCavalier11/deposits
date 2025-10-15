import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:postal_deposit/features/policy/presentation/providers/policy_provider.dart';

class ImportPolicyButton extends StatelessWidget {
  final VoidCallback? onImported;
  
  const ImportPolicyButton({
    super.key,
    this.onImported,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PolicyProvider>(
      builder: (context, provider, _) {
        return ElevatedButton.icon(
          onPressed: provider.isImporting || provider.isLoading
              ? null
              : () => _importPolicies(context, provider),
          icon: provider.isImporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.upload_file),
          label: Text(provider.isImporting ? 'Importing...' : 'Import Policies'),
        );
      },
    );
  }

  Future<void> _importPolicies(
    BuildContext context,
    PolicyProvider provider,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      final success = await provider.importPolicies();
      
      if (!context.mounted) return;
      
      if (success) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              'Successfully imported ${provider.policies.length} policies',
            ),
            backgroundColor: Colors.green,
          ),
        );
        
        if (onImported != null) {
          onImported!();
        }
      } else if (provider.error != null) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(provider.error!),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed to import policies: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Usage example:
// ImportPolicyButton(
//   onImported: () {
//     // Optional callback after successful import
//   },
// )
