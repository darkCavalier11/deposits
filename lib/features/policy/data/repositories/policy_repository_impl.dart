import 'package:postal_deposit/core/storage/hive_service.dart';
import 'package:postal_deposit/features/policy/domain/entities/policy_entity.dart';
import 'package:postal_deposit/features/policy/domain/repositories/policy_repository.dart';

class PolicyRepositoryImpl implements PolicyRepository {
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
}
