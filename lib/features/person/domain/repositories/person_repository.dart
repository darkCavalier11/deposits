import 'package:postal_deposit/features/person/domain/entities/person_entity.dart';

abstract class PersonRepository {
  Future<PersonEntity?> getPerson();
  Future<void> savePerson(PersonEntity person);
  Future<void> updatePerson(PersonEntity person);
  Future<void> deletePerson();
}
