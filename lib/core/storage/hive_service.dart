import 'package:hive_flutter/hive_flutter.dart';
import 'package:postal_deposit/features/person/domain/entities/person_entity.dart';

class HiveService {
  static const String _policyBoxName = 'policies';
  static const String _personBoxName = 'person';
  static const String _personKey = 'current_person';
  
  static Box? _policyBox;
  static Box? _personBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    // Register adapters here if needed
    // Hive.registerAdapter(PolicyModelAdapter());
    
    _policyBox = await Hive.openBox(_policyBoxName);
    _personBox = await Hive.openBox(_personBoxName);
  }

  static bool get isInitialized => _policyBox != null && _personBox != null;

  static Future<void> savePolicies(List<Map<String, dynamic>> policies) async {
    if (!isInitialized) await init();
    await _policyBox!.clear();
    await _policyBox!.putAll(Map.fromIterable(
      policies,
      key: (policy) => policy['policyNumber'],
      value: (policy) => policy,
    ));
  }

  static List<Map<String, dynamic>> getPolicies() {
    if (!isInitialized) return [];
    return _policyBox!.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<void> clearPolicies() async {
    if (!isInitialized) await init();
    await _policyBox!.clear();
  }

  // Person related methods
  static Future<void> savePerson(PersonEntity person) async {
    if (!isInitialized) await init();
    await _personBox!.put(_personKey, person.toMap());
  }

  static PersonEntity? getPerson() {
    if (!isInitialized) return null;
    final data = _personBox!.get(_personKey);
    return data != null ? PersonEntity.fromMap(Map<String, dynamic>.from(data)) : null;
  }

  static Future<void> updatePerson(PersonEntity person) async {
    if (!isInitialized) await init();
    await _personBox!.put(_personKey, person.toMap());
  }

  static Future<void> deletePerson() async {
    if (!isInitialized) await init();
    await _personBox!.delete(_personKey);
  }

  static Future<void> close() async {
    if (_policyBox != null) {
      await _policyBox!.close();
      _policyBox = null;
    }
    if (_personBox != null) {
      await _personBox!.close();
      _personBox = null;
    }
  }
}
