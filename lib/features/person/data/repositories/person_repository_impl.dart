import 'package:postal_deposit/core/storage/hive_service.dart';
import 'package:postal_deposit/features/person/domain/entities/person_entity.dart';
import 'package:postal_deposit/features/person/domain/repositories/person_repository.dart';

class PersonRepositoryImpl implements PersonRepository {
  @override
  Future<PersonEntity?> getPerson() async {
    try {
      return HiveService.getPerson();
    } catch (e) {
      throw Exception('Failed to load person: $e');
    }
  }

  @override
  Future<void> savePerson(PersonEntity person) async {
    try {
      await HiveService.savePerson(person);
    } catch (e) {
      throw Exception('Failed to save person: $e');
    }
  }

  @override
  Future<void> updatePerson(PersonEntity person) async {
    try {
      await HiveService.updatePerson(person);
    } catch (e) {
      throw Exception('Failed to update person: $e');
    }
  }

  @override
  Future<void> deletePerson() async {
    try {
      await HiveService.deletePerson();
    } catch (e) {
      throw Exception('Failed to delete person: $e');
    }
  }
}
