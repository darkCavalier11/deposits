import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' show min;
import 'package:csv/csv.dart';
import 'package:postal_deposit/features/policy/domain/entities/policy_entity.dart';

class PolicyCsvParser {
  static const int headerRowIndex = 9; // Row index where the data starts
  static const int agentNameRow = 2;
  static const int agentIdRow = 3;
  static const int dateRangeRow = 5;

  static Future<
    ({
      List<PolicyEntity> policies,
      String agentName,
      String agentId,
      DateTime fromDate,
      DateTime toDate,
    })
  >
  parseCsv(File file) async {
    try {
      log('Starting CSV parsing...');
      final csvFile = file.openRead();
      final csvData = await csvFile.transform(utf8.decoder).join();

      // Convert CSV to list of rows
      List<List<dynamic>> rows;

      // First try parsing with default settings
      rows = const CsvToListConverter().convert(csvData);

      // If we only got one row with many columns, try parsing with different settings
      if (rows.length == 1 && rows[0].length > 10) {
        // Assuming more than 10 columns might indicate a parsing issue
        log(
          'Detected single row with many columns, trying alternative parsing...',
        );
        // Try with different line delimiters and field separators
        rows = const CsvToListConverter(
          fieldDelimiter: ',',
          textDelimiter: '"',
          eol: '\n',
          shouldParseNumbers: true,
        ).convert(csvData);
      }

      log(
        'CSV parsed into ${rows.length} rows with ${rows.isNotEmpty ? rows[0].length : 0} columns',
      );

      // Validate minimum required rows
      if (rows.length <= headerRowIndex) {
        throw FormatException(
          'Invalid CSV format: Not enough rows (${rows.length} found, at least ${headerRowIndex + 1} required)',
        );
      }

      // Log first few rows for debugging
      log('First 5 rows of CSV:');
      for (var i = 0; i < min(5, rows.length); i++) {
        final row = rows[i];
        final endIndex = row.length > 5 ? 5 : row.length;
        log(
          'Row $i: ${row.sublist(0, endIndex).map((e) => e?.toString().trim()).toList()}${row.length > 5 ? '...' : ''}',
        );
      }

      // Extract agent information with bounds checking
      final agentName = _extractCellValue(rows, agentNameRow, 3, 'Agent Name');
      final agentId = _extractCellValue(rows, agentIdRow, 3, 'Agent ID');
      log('Agent: $agentName (ID: $agentId)');

      // Parse date range with bounds checking
      final fromDate = _parseDate(
        _extractCellValue(rows, dateRangeRow, 6, 'From Date'),
      );
      final toDate = _parseDate(
        _extractCellValue(rows, dateRangeRow, 7, 'To Date'),
      );
      log('Date range: ${_formatDate(fromDate)} to ${_formatDate(toDate)}');

      // Process policy data rows (skip the last row as it contains totals)
      final policies = <PolicyEntity>[];
      int successCount = 0;
      int errorCount = 0;
      final lastDataRow = rows.length - 1; // Last row index

      log('Processing policy data from row $headerRowIndex to $lastDataRow (skipping last row as it contains totals)...');
      for (var i = headerRowIndex; i < lastDataRow; i++) {
        try {
          final row = rows[i];

          // Skip empty or invalid rows
          if (_shouldSkipRow(row)) {
            log('Skipping row $i: Empty or invalid row');
            continue;
          }

          log(
            'Processing row $i: ${row.take(5).map((e) => e?.toString()).toList()}...',
          );

          final policy = _parsePolicyRow(row);
          if (policy != null) {
            policies.add(policy);
            successCount++;
          } else {
            log('Skipping row $i: Could not parse policy data');
            errorCount++;
          }
        } catch (e) {
          log('Error processing row ${i + 1}: $e');
          errorCount++;
          // Continue processing other rows even if one fails
        }
      }

      log(
        'CSV import completed: $successCount policies imported successfully, $errorCount rows had errors',
      );

      return (
        policies: policies,
        agentName: agentName,
        agentId: agentId,
        fromDate: fromDate,
        toDate: toDate,
      );
    } catch (e) {
      print('Error parsing CSV file: $e');
      rethrow;
    }
  }

  static String _extractCellValue(
    List<List<dynamic>> rows,
    int rowIndex,
    int colIndex,
    String fieldName,
  ) {
    try {
      if (rows.isEmpty) {
        throw FormatException('CSV file is empty');
      }

      if (rowIndex < 0 || rowIndex >= rows.length) {
        throw FormatException(
          'Row index $rowIndex out of bounds (0-${rows.length - 1}) while looking for $fieldName',
        );
      }

      final row = rows[rowIndex];
      if (colIndex < 0 || colIndex >= row.length) {
        throw FormatException(
          'Column index $colIndex out of bounds (0-${row.length - 1}) in row $rowIndex while looking for $fieldName',
        );
      }

      final value = row[colIndex]?.toString().trim() ?? '';
      log('Extracted $fieldName at [$rowIndex][$colIndex]: "$value"');
      return value;
    } catch (e) {
      log('Error extracting $fieldName at [$rowIndex][$colIndex]: $e');
      return '';
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static bool _shouldSkipRow(List<dynamic> row) {
    // Skip rows that don't have enough columns or have empty policy number
    if (row.length < 2 || row[1] == null || row[1].toString().trim().isEmpty) {
      return true;
    }

    // Skip total rows or summary rows
    final firstCell = row[0]?.toString().toLowerCase() ?? '';
    return firstCell.contains('total') || firstCell.contains('summary');
  }

  static PolicyEntity? _parsePolicyRow(List<dynamic> row) {
    try {
      // Parse dates with error handling
      final policyNumber = (row[1]?.toString().trim() ?? '').padLeft(13, '0');
      final insuredName = (row[3]?.toString().trim() ?? '').toUpperCase();
      final issueDate = _parseDate(row[12]?.toString().trim() ?? '');
      final dob = _parseDate(row[13]?.toString().trim() ?? '');

      // Parse amounts with error handling
      final sumAssured = _parseAmount(row[6]?.toString().trim() ?? '0');
      final premiumAmt = _parseAmount(row[7]?.toString().trim() ?? '0');

      return PolicyEntity(
        policyNumber: policyNumber,
        insured: insuredName,
        sumAssured: sumAssured,
        premiumAmt: premiumAmt,
        premiumFrequency: _parsePremiumFrequency(
          row[8]?.toString().trim() ?? '',
        ),
        productName: (row[10]?.toString().trim() ?? '').toUpperCase(),
        paymentMode: (row[11]?.toString().trim() ?? '').toUpperCase(),
        issueDate: issueDate,
        insuredDateOfBirth: dob,
      );
    } catch (e) {
      print('Error parsing policy row: $row\nError: $e');
      return null;
    }
  }

  static double _parseAmount(String amountStr) {
    try {
      return double.tryParse(amountStr.replaceAll(RegExp(r'[^\d.-]'), '')) ??
          0.0;
    } catch (e) {
      print('Error parsing amount: $amountStr, Error: $e');
      return 0.0;
    }
  }

  static DateTime _parseDate(String dateStr) {
    try {
      if (dateStr.isEmpty) return DateTime.now();

      // Try DD/MM/YYYY format first
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        final day = int.tryParse(parts[0]) ?? 1;
        final month = int.tryParse(parts[1]) ?? 1;
        final year = int.tryParse(parts[2]) ?? DateTime.now().year;

        // Basic date validation
        if (year > 1900 &&
            year < 2100 &&
            month >= 1 &&
            month <= 12 &&
            day >= 1 &&
            day <= 31) {
          return DateTime(year, month, day);
        }
      }

      // Try other common date formats if needed
      // ...

      print('Warning: Using current date as fallback for: $dateStr');
      return DateTime.now();
    } catch (e) {
      print('Error parsing date: $dateStr, Error: $e');
      return DateTime.now();
    }
  }

  static PremiumFrequency _parsePremiumFrequency(String frequency) {
    if (frequency.isEmpty) return PremiumFrequency.monthly;

    final freq = frequency.toUpperCase().trim();
    if (freq.contains('MONTH')) return PremiumFrequency.monthly;
    if (freq.contains('QUARTER')) return PremiumFrequency.quarterly;
    if (freq.contains('HALF') || freq == 'SEMI-ANNUAL')
      return PremiumFrequency.halfYearly;
    if (freq.contains('ANNUAL') || freq.contains('YEARLY'))
      return PremiumFrequency.annual;
    if (freq == 'SINGLE') return PremiumFrequency.single;

    // Default to monthly if frequency is not recognized
    print(
      'Warning: Unknown premium frequency: $frequency, defaulting to monthly',
    );
    return PremiumFrequency.monthly;
  }
}
