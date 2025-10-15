import 'package:flutter/foundation.dart';
import 'package:postal_deposit/features/policy/domain/entities/policy_entity.dart';
import 'package:postal_deposit/features/policy/domain/repositories/policy_repository.dart';

class PolicyProvider with ChangeNotifier {
  final PolicyRepository _repository;
  List<PolicyEntity> _policies = [];
  bool _isLoading = false;
  String? _error;

  PolicyProvider(this._repository);

  List<PolicyEntity> get policies => _policies;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasPolicies => _policies.isNotEmpty;

  Future<void> loadPolicies() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _policies = await _repository.getPolicies();
    } catch (e) {
      _error = 'Failed to load policies: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> savePolicies(List<PolicyEntity> policies) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.savePolicies(policies);
      _policies = await _repository.getPolicies();
    } catch (e) {
      _error = 'Failed to save policies: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearPolicies() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.clearPolicies();
      _policies = [];
    } catch (e) {
      _error = 'Failed to clear policies: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
