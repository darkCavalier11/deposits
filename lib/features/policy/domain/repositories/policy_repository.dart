import 'dart:io';

import 'package:postal_deposit/features/policy/domain/entities/policy_entity.dart';

abstract class PolicyRepository {
  /// Get all stored policies
  Future<List<PolicyEntity>> getPolicies();
  
  /// Save a list of policies
  Future<void> savePolicies(List<PolicyEntity> policies);
  
  /// Clear all stored policies
  Future<void> clearPolicies();
  
  /// Import policies from a CSV/Excel file
  /// Returns a tuple containing the list of policies and the agent information
  Future<({
    List<PolicyEntity> policies,
    String agentName,
    String agentId,
    DateTime fromDate,
    DateTime toDate,
  })> importPoliciesFromFile(File file);
}
