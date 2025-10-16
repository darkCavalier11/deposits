import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:postal_deposit/features/policy/domain/entities/policy_entity.dart';
import 'package:postal_deposit/features/policy/domain/repositories/policy_repository.dart';

/// Manages the state and business logic for policy-related operations.
class PolicyProvider with ChangeNotifier {
  final PolicyRepository _repository;

  // State
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

  PolicyProvider(this._repository) {
    _initialize();
  }

  // Getters
  List<PolicyEntity> get policies =>
      _searchQuery.isEmpty ? _policies : _filteredPolicies;
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

  // Private methods
  Future<void> _initialize() async {
    await loadPolicies();
  }

  void _updateState({bool? isLoading, bool? isImporting, String? error}) {
    if (isLoading != null) _isLoading = isLoading;
    if (isImporting != null) _isImporting = isImporting;
    if (error != null) _error = error;
    notifyListeners();
  }

  void _updateFilteredPolicies() {
    if (_searchQuery.isEmpty) {
      _filteredPolicies = [];
      return;
    }
    _filteredPolicies = _policies.where((policy) {
      return policy.insured.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  // Public methods
  /// Updates the search query and filters the policies list
  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    _updateFilteredPolicies();
    notifyListeners();
  }

  /// Loads all policies from the repository
  Future<void> loadPolicies() async {
    if (_isLoading) return;

    _updateState(isLoading: true, error: null);

    try {
      _policies = await _repository.getPolicies();
      _updateFilteredPolicies();
    } catch (e) {
      _updateState(error: 'Failed to load policies: $e');
    } finally {
      _updateState(isLoading: false);
    }
  }

  /// Saves the current list of policies
  Future<bool> savePolicies() async {
    if (_isLoading) return false;

    _updateState(isLoading: true, error: null);

    try {
      await _repository.savePolicies(_policies);
      return true;
    } catch (e) {
      _updateState(error: 'Failed to save policies: $e');
      return false;
    } finally {
      _updateState(isLoading: false);
    }
  }

  /// Imports policies from a file
  Future<bool> importPolicies() async {
    if (_isLoading || _isImporting) return false;

    _updateState(isImporting: true, error: null);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xls', 'xlsx'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return false; // User cancelled
      }

      final file = File(result.files.single.path!);
      _fileName = result.files.single.name;
      
      final resultData = await _repository.importPoliciesFromFile(file);
      
      // Update the state with the imported data
      _policies = resultData.policies;
      _agentName = resultData.agentName;
      _agentId = resultData.agentId;
      _fromDate = resultData.fromDate;
      _toDate = resultData.toDate;
      
      _updateFilteredPolicies();
      notifyListeners();
      
      return true;
    } catch (e) {
      _updateState(error: 'Failed to import policies: $e');
      return false;
    } finally {
      _updateState(isImporting: false);
    }
  }

  /// Deletes a policy by its policy number
  Future<bool> deletePolicy(String policyNumber) async {
    if (_isLoading) return false;

    _updateState(isLoading: true, error: null);

    try {
      final success = await _repository.deletePolicy(policyNumber);
      if (success) {
        _policies.removeWhere((p) => p.policyNumber == policyNumber);
        _updateFilteredPolicies();
        await _repository.savePolicies(_policies);
      }
      return success;
    } catch (e) {
      _updateState(error: 'Failed to delete policy: $e');
      return false;
    } finally {
      _updateState(isLoading: false);
    }
  }

  /// Clears all policies and resets the state
  Future<bool> clearPolicies() async {
    if (_isLoading) return false;

    _updateState(isLoading: true, error: null);

    try {
      await _repository.clearPolicies();
      _policies = [];
      _filteredPolicies = [];
      _agentName = null;
      _agentId = null;
      _fromDate = null;
      _toDate = null;
      _fileName = null;
      _searchQuery = '';
      return true;
    } catch (e) {
      _updateState(error: 'Failed to clear policies: $e');
      return false;
    } finally {
      _updateState(isLoading: false);
    }
  }
}
