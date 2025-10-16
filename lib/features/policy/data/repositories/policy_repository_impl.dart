import 'dart:io';

import 'package:postal_deposit/core/storage/hive_service.dart';
import 'package:postal_deposit/features/person/domain/entities/person_entity.dart';
import 'package:postal_deposit/features/person/domain/repositories/person_repository.dart';
import 'package:postal_deposit/features/policy/data/datasources/policy_csv_parser.dart';
import 'package:postal_deposit/features/policy/domain/entities/policy_entity.dart';
import 'package:postal_deposit/features/policy/domain/repositories/policy_repository.dart';

class PolicyRepositoryImpl implements PolicyRepository {
  final PersonRepository _personRepository;

  PolicyRepositoryImpl(this._personRepository);
  @override
  Future<List<PolicyEntity>> getPolicies() async {
    try {
      final policies = HiveService.getPolicies();
      return policies.map((map) => PolicyEntity.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to load policies: $e');
    }
  }

  @override
  Future<void> savePolicies(List<PolicyEntity> policies) async {
    try {
      await HiveService.savePolicies(
        policies.map((policy) => policy.toMap()).toList(),
      );
    } catch (e) {
      throw Exception('Failed to save policies: $e');
    }
  }

  @override
  Future<void> clearPolicies() async {
    try {
      await HiveService.clearPolicies();
    } catch (e) {
      throw Exception('Failed to clear policies: $e');
    }
  }

  @override
  Future<({
    List<PolicyEntity> policies,
    String agentName,
    String agentId,
    DateTime fromDate,
    DateTime toDate,
  })> importPoliciesFromFile(File file) async {
    try {
      // Check if file exists
      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      // Parse the CSV file
      final result = await PolicyCsvParser.parseCsv(file);
      
      // Save the parsed policies and agent details
      if (result.policies.isNotEmpty) {
        await savePolicies(result.policies);
        
        // Save agent details
        final person = PersonEntity(
          agentName: result.agentName,
          agentId: result.agentId,
          issuedDateFrom: result.fromDate,
          issuedDateTo: result.toDate,
          totalSumAssured: result.policies.fold(0, (sum, policy) => sum + policy.sumAssured),
          totalPremiumAssured: result.policies.fold(0, (sum, policy) => sum + policy.premiumAmt),
          policyCount: result.policies.length,
        );
        
        await _personRepository.savePerson(person);
      }
      
      return result;
    } catch (e) {
      throw Exception('Failed to import policies from file: $e');
    }
  }
  @override
  Future<bool> deletePolicy(String policyNumber) async {
    try {
      final policies = await getPolicies();
      final initialCount = policies.length;
      policies.removeWhere((policy) => policy.policyNumber == policyNumber);
      
      if (policies.length < initialCount) {
        await savePolicies(policies);
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to delete policy: $e');
    }
  }

  @override
  Future<PolicyEntity?> updatePolicy(PolicyEntity policy) async {
    try {
      final policies = await getPolicies();
      final index = policies.indexWhere((p) => p.policyNumber == policy.policyNumber);
      
      if (index != -1) {
        policies[index] = policy;
        await savePolicies(policies);
        return policy;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to update policy: $e');
    }
  }
}
