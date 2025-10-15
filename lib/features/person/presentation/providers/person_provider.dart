import 'package:flutter/foundation.dart';
import 'package:postal_deposit/features/person/domain/entities/person_entity.dart';
import 'package:postal_deposit/features/person/domain/repositories/person_repository.dart';

class PersonProvider with ChangeNotifier {
  final PersonRepository _repository;
  PersonEntity? _person;
  bool _isLoading = false;
  String? _error;

  PersonProvider(this._repository);

  PersonEntity? get person => _person;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasPerson => _person != null;

  Future<void> loadPerson() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _person = await _repository.getPerson();
    } catch (e) {
      _error = 'Failed to load person: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> savePerson(PersonEntity person) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_person == null) {
        await _repository.savePerson(person);
      } else {
        await _repository.updatePerson(person);
      }
      _person = person;
    } catch (e) {
      _error = 'Failed to save person: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deletePerson() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.deletePerson();
      _person = null;
    } catch (e) {
      _error = 'Failed to delete person: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateFromPolicies({
    required double totalSumAssured,
    required double totalPremiumAssured,
    required int policyCount,
  }) async {
    if (_person == null) return;

    final updatedPerson = _person!.copyWith(
      totalSumAssured: totalSumAssured,
      totalPremiumAssured: totalPremiumAssured,
      policyCount: policyCount,
    );

    await savePerson(updatedPerson);
  }
}
