import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:postal_deposit/features/policy/domain/entities/policy_entity.dart';
import 'package:postal_deposit/features/policy/domain/repositories/policy_repository.dart';

class PolicyProvider with ChangeNotifier {
  final PolicyRepository _repository;
  List<PolicyEntity> _policies = [];
  List<PolicyEntity> _filteredPolicies = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String? _agentName;
  String? _agentId;
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _fileName;
  bool _isImporting = false;

  PolicyProvider(this._repository);

  List<PolicyEntity> get policies => _searchQuery.isEmpty ? _policies : _filteredPolicies;
  bool get isLoading => _isLoading;
  bool get isImporting => _isImporting;
  String? get error => _error;
  bool get hasPolicies => _policies.isNotEmpty;
  String? get agentName => _agentName;
  String? get agentId => _agentId;
  DateTime? get fromDate => _fromDate;
  DateTime? get toDate => _toDate;
  String? get fileName => _fileName;
  String get searchQuery => _searchQuery;

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    if (_searchQuery.isEmpty) {
      _filteredPolicies = [];
    } else {
      _filteredPolicies = _policies.where((policy) {
        return policy.insured.toLowerCase().contains(_searchQuery);
      }).toList();
    }
    notifyListeners();
  }

  Future<void> loadPolicies() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _policies = await _repository.getPolicies();
      if (_searchQuery.isNotEmpty) {
        _filteredPolicies = _policies.where((policy) {
          return policy.insured.toLowerCase().contains(_searchQuery);
        }).toList();
      }
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
      _agentName = null;
      _agentId = null;
      _fromDate = null;
      _toDate = null;
      _fileName = null;
    } catch (e) {
      _error = 'Failed to clear policies: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Handles the file picking and import process
  Future<bool> deletePolicy(String policyNumber) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _repository.deletePolicy(policyNumber);
      if (success) {
        _policies.removeWhere((policy) => policy.policyNumber == policyNumber);
      }
      return success;
    } catch (e) {
      _error = 'Failed to delete policy: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> importPolicies() async {
    try {
      _isImporting = true;
      _error = null;
      notifyListeners();

      // Pick a file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xls', 'xlsx'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        // User canceled the picker
        return false;
      }

      final file = File(result.files.single.path!);
      _fileName = result.files.single.name;
      notifyListeners();

      // Parse the file
      final resultData = await _repository.importPoliciesFromFile(file);

      // Update the state
      _policies = resultData.policies;
      _agentName = resultData.agentName;
      _agentId = resultData.agentId;
      _fromDate = resultData.fromDate;
      _toDate = resultData.toDate;

      return true;
    } catch (e) {
      _error = 'Failed to import policies: $e';
      return false;
    } finally {
      _isImporting = false;
      notifyListeners();
    }
  }
}
