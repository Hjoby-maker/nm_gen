import 'package:nm_gen/domain/entities/person.dart';

abstract class PersonRepository {
  Future<Person> addPerson(Person person);
  Future<Person?> getPerson(String id);
  Future<List<Person>> getAllPersons({String? treeId}); // <-- ДОБАВЛЯЕМ
  Future<Person> updatePerson(Person person);
  Future<void> deletePerson(String id);
  Future<void> deleteAllPersons({String? treeId}); // <-- ДОБАВЛЯЕМ
  Future<List<Person>> searchPersons(
    String query, {
    String? treeId,
  }); // <-- ДОБАВЛЯЕМ
  Future<List<Person>> getPersonsByIds(
    List<String> ids, {
    String? treeId,
  }); // <-- ДОБАВЛЯЕМ
  Future<int> getPersonsCount({String? treeId}); // <-- ДОБАВЛЯЕМ
}
