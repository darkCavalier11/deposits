import 'package:postal_deposit/features/policy/domain/entities/policy_entity.dart';

abstract class PolicyRepository {
  Future<List<PolicyEntity>> getPolicies();
  Future<void> savePolicies(List<PolicyEntity> policies);
  Future<void> clearPolicies();
}
