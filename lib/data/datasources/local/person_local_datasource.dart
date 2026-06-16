import 'package:nm_gen/data/datasources/local/database/db_helper.dart';
import 'package:nm_gen/data/datasources/local/database/person_model.dart';

/// Локальный источник данных для Person
class PersonLocalDataSource {
  final DatabaseHelper dbHelper;

  PersonLocalDataSource(this.dbHelper);

  /// Вставить нового человека
  Future<PersonModel> insertPerson(PersonModel person) async {
    final db = await dbHelper.database;
    await db.insert('persons', person.toMap());
    return person;
  }

  /// Получить человека по ID
  Future<PersonModel?> getPerson(String id) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'persons',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return PersonModel.fromMap(maps.first);
  }

  /// Получить всех людей
  Future<List<PersonModel>> getAllPersons() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'persons',
      orderBy: 'last_name ASC, first_name ASC',
    );

    return maps.map((map) => PersonModel.fromMap(map)).toList();
  }

  /// Обновить человека
  Future<PersonModel> updatePerson(PersonModel person) async {
    final db = await dbHelper.database;
    await db.update(
      'persons',
      person.toMap(),
      where: 'id = ?',
      whereArgs: [person.id],
    );
    return person;
  }

  /// Удалить человека
  Future<void> deletePerson(String id) async {
    final db = await dbHelper.database;
    await db.delete('persons', where: 'id = ?', whereArgs: [id]);
  }

  /// Поиск людей по запросу
  Future<List<PersonModel>> searchPersons(String query) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'persons',
      where: 'first_name LIKE ? OR last_name LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'last_name ASC, first_name ASC',
    );

    return maps.map((map) => PersonModel.fromMap(map)).toList();
  }

  /// Получить людей по списку ID
  Future<List<PersonModel>> getPersonsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    final db = await dbHelper.database;
    final placeholders = ids.map((_) => '?').join(',');
    final List<Map<String, dynamic>> maps = await db.query(
      'persons',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );

    return maps.map((map) => PersonModel.fromMap(map)).toList();
  }

  /// Очистить все данные (для тестирования)
  Future<void> clearAll() async {
    final db = await dbHelper.database;
    await db.delete('persons');
  }
}
