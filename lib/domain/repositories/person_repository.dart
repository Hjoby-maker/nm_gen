import '../entities/person.dart';

/// Интерфейс репозитория для работы с персонами
abstract class PersonRepository {
  /// Добавить нового человека
  Future<Person> addPerson(Person person);

  /// Получить человека по ID
  Future<Person?> getPerson(String id);

  /// Получить всех людей
  Future<List<Person>> getAllPersons();

  /// Обновить данные человека
  Future<Person> updatePerson(Person person);

  /// Удалить человека
  Future<void> deletePerson(String id);

  /// Поиск людей по имени или фамилии
  Future<List<Person>> searchPersons(String query);

  /// Получить всех людей с указанными ID
  Future<List<Person>> getPersonsByIds(List<String> ids);
}
