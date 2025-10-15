import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:postal_deposit/features/policy/domain/entities/policy_entity.dart';
import 'package:postal_deposit/features/policy/presentation/providers/policy_provider.dart';
import 'package:provider/provider.dart';

class ImportExcelButton extends StatelessWidget {
  const ImportExcelButton({super.key});

  @override
  Widget build(BuildContext context) {
    final policyProvider = context.watch<PolicyProvider>();
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.upload_file,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No policies found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload an Excel file to get started',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: policyProvider.isLoading ? null : () => _importExcel(context),
            icon: const Icon(Icons.upload_file),
            label: const Text('Import Excel File'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _importExcel(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final bytes = await file.readAsBytes();
        final excel = Excel.decodeBytes(bytes);
        
        final policies = <PolicyEntity>[];
        
        for (var table in excel.tables.keys) {
          final rows = excel.tables[table]?.rows ?? [];
          // Skip header row
          for (var i = 1; i < rows.length; i++) {
            final row = rows[i];
            if (row.length >= 9) {
              try {
                final policy = PolicyEntity(
                  policyNumber: row[0]?.value?.toString() ?? '',
                  insured: row[1]?.value?.toString() ?? '',
                  sumAssured: double.tryParse(row[2]?.value?.toString() ?? '0') ?? 0,
                  premiumAmt: double.tryParse(row[3]?.value?.toString() ?? '0') ?? 0,
                  premiumFrequency: _parsePremiumFrequency(row[4]?.value?.toString() ?? ''),
                  productName: row[5]?.value?.toString() ?? '',
                  paymentMode: row[6]?.value?.toString() ?? '',
                  issueDate: DateTime.tryParse(row[7]?.value?.toString() ?? '') ?? DateTime.now(),
                  insuredDateOfBirth: DateTime.tryParse(row[8]?.value?.toString() ?? '') ?? DateTime.now(),
                );
                policies.add(policy);
              } catch (e) {
                debugPrint('Error parsing row $i: $e');
              }
            }
          }
        }

        if (policies.isNotEmpty) {
          await context.read<PolicyProvider>().savePolicies(policies);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Successfully imported ${policies.length} policies')),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No valid policies found in the file')),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing file: $e')),
        );
      }
    }
  }

  PremiumFrequency _parsePremiumFrequency(String value) {
    value = value.toLowerCase();
    if (value.contains('month')) return PremiumFrequency.monthly;
    if (value.contains('quarter')) return PremiumFrequency.quarterly;
    if (value.contains('half')) return PremiumFrequency.halfYearly;
    if (value.contains('single')) return PremiumFrequency.single;
    return PremiumFrequency.annual; // Default to annual
  }
}
