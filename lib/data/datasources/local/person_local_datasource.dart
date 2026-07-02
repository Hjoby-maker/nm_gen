import 'package:nm_gen/data/datasources/local/database/db_helper.dart';
import 'package:nm_gen/data/datasources/local/database/person_model.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:injectable/injectable.dart';

@injectable
class PersonLocalDataSource {
  PersonLocalDataSource(this.dbHelper);
  final DatabaseHelper dbHelper;

  /// Вставить нового человека
  Future<PersonModel> insertPerson(PersonModel person) async {
    final Database db = await dbHelper.database;
    await db.insert('persons', person.toMap());
    return person;
  }

  /// Получить человека по ID
  Future<PersonModel?> getPerson(String id) async {
    final Database db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'persons',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );

    if (maps.isEmpty) return null;
    return PersonModel.fromMap(maps.first);
  }

  /// Получить всех людей (с фильтром по treeId)
  Future<List<PersonModel>> getAllPersons({String? treeId}) async {
    final Database db = await dbHelper.database;

    final List<Map<String, dynamic>> maps;

    if (treeId != null && treeId.isNotEmpty) {
      maps = await db.query(
        'persons',
        where: 'tree_id = ?',
        whereArgs: <Object?>[treeId],
        orderBy: 'last_name ASC, first_name ASC',
      );
    } else {
      maps = await db.query(
        'persons',
        orderBy: 'last_name ASC, first_name ASC',
      );
    }

    return maps
        .map((Map<String, dynamic> map) => PersonModel.fromMap(map))
        .toList();
  }

  /// Обновить человека
  Future<PersonModel> updatePerson(PersonModel person) async {
    final Database db = await dbHelper.database;
    await db.update(
      'persons',
      person.toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[person.id],
    );
    return person;
  }

  /// Удалить человека
  Future<void> deletePerson(String id) async {
    final Database db = await dbHelper.database;
    await db.delete('persons', where: 'id = ?', whereArgs: <Object?>[id]);
  }

  /// Удалить всех людей в древе
  Future<void> deleteAllPersons({String? treeId}) async {
    final Database db = await dbHelper.database;
    if (treeId != null && treeId.isNotEmpty) {
      await db.delete(
        'persons',
        where: 'tree_id = ?',
        whereArgs: <Object?>[treeId],
      );
    } else {
      await db.delete('persons');
    }
  }

  /// Поиск людей по запросу (с фильтром по treeId)
  Future<List<PersonModel>> searchPersons(
    String query, {
    String? treeId,
  }) async {
    final Database db = await dbHelper.database;

    final List<Map<String, dynamic>> maps;

    if (treeId != null && treeId.isNotEmpty) {
      maps = await db.query(
        'persons',
        where: 'tree_id = ? AND (first_name LIKE ? OR last_name LIKE ?)',
        whereArgs: <Object?>[treeId, '%$query%', '%$query%'],
        orderBy: 'last_name ASC, first_name ASC',
      );
    } else {
      maps = await db.query(
        'persons',
        where: 'first_name LIKE ? OR last_name LIKE ?',
        whereArgs: <Object?>['%$query%', '%$query%'],
        orderBy: 'last_name ASC, first_name ASC',
      );
    }

    return maps
        .map((Map<String, dynamic> map) => PersonModel.fromMap(map))
        .toList();
  }

  /// Получить людей по списку ID (с фильтром по treeId)
  Future<List<PersonModel>> getPersonsByIds(
    List<String> ids, {
    String? treeId,
  }) async {
    if (ids.isEmpty) return <PersonModel>[];

    final Database db = await dbHelper.database;
    final String placeholders = ids.map((_) => '?').join(',');

    final List<Map<String, dynamic>> maps;

    if (treeId != null && treeId.isNotEmpty) {
      maps = await db.query(
        'persons',
        where: 'id IN ($placeholders) AND tree_id = ?',
        whereArgs: <Object?>[...ids, treeId],
      );
    } else {
      maps = await db.query(
        'persons',
        where: 'id IN ($placeholders)',
        whereArgs: <Object?>[...ids],
      );
    }

    return maps
        .map((Map<String, dynamic> map) => PersonModel.fromMap(map))
        .toList();
  }

  /// Получить количество людей в древе
  Future<int> getPersonsCount({String? treeId}) async {
    final Database db = await dbHelper.database;

    final List<Map<String, dynamic>> result;

    if (treeId != null && treeId.isNotEmpty) {
      result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM persons WHERE tree_id = ?',
        [treeId],
      );
    } else {
      result = await db.rawQuery('SELECT COUNT(*) as count FROM persons');
    }

    // Безопасное получение значения
    if (result.isNotEmpty && result.first.containsKey('count')) {
      return result.first['count'] as int? ?? 0;
    }
    return 0;
  }

  /// Очистить все данные (для тестирования)
  Future<void> clearAll() async {
    final Database db = await dbHelper.database;
    await db.delete('persons');
  }
}
