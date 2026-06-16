import 'package:injectable/injectable.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/repositories/person_repository.dart';

/// Реализация репозитория в памяти (для разработки)
@Injectable(as: PersonRepository) // <-- Добавляем аннотацию
class PersonRepositoryImpl implements PersonRepository {
  final Map<String, Person> _storage = {};

  @override
  Future<Person> addPerson(Person person) async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (_storage.containsKey(person.id)) {
      throw Exception('Person with id ${person.id} already exists');
    }

    _storage[person.id] = person;
    return person;
  }

  @override
  Future<Person?> getPerson(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _storage[id];
  }

  @override
  Future<List<Person>> getAllPersons() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _storage.values.toList();
  }

  @override
  Future<Person> updatePerson(Person person) async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (!_storage.containsKey(person.id)) {
      throw Exception('Person with id ${person.id} not found');
    }

    final updatedPerson = person.copyWith(updatedAt: DateTime.now());
    _storage[person.id] = updatedPerson;
    return updatedPerson;
  }

  @override
  Future<void> deletePerson(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _storage.remove(id);
  }

  @override
  Future<List<Person>> searchPersons(String query) async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (query.isEmpty) {
      return _storage.values.toList();
    }

    final lowerQuery = query.toLowerCase();
    return _storage.values.where((person) {
      return person.firstName.toLowerCase().contains(lowerQuery) ||
          person.lastName.toLowerCase().contains(lowerQuery) ||
          person.fullName.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  @override
  Future<List<Person>> getPersonsByIds(List<String> ids) async {
    await Future.delayed(const Duration(milliseconds: 100));

    return ids.map((id) => _storage[id]).whereType<Person>().toList();
  }

  void clear() {
    _storage.clear();
  }
}
