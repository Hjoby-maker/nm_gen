import 'package:injectable/injectable.dart';
import 'package:nm_gen/data/datasources/local/database/db_helper.dart';
import 'package:nm_gen/data/datasources/local/database/event_model.dart';
import 'package:sqflite_common/sqlite_api.dart';

@injectable
class EventLocalDataSource {
  EventLocalDataSource(this.dbHelper);
  final DatabaseHelper dbHelper;

  /// Вставить новое событие
  Future<EventModel> insertEvent(EventModel event) async {
    final Database db = await dbHelper.database;
    await db.insert('events', event.toMap());
    return event;
  }

  /// Получить событие по ID
  Future<EventModel?> getEvent(String id) async {
    final Database db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
    if (maps.isEmpty) return null;
    return EventModel.fromMap(maps.first);
  }

  /// Получить все события для человека
  Future<List<EventModel>> getEventsByPersonId(
    String personId, {
    String? treeId,
  }) async {
    final Database db = await dbHelper.database;

    final List<String> whereClauses = <String>['person_id = ?'];
    final List<Object?> whereArgs = <Object?>[personId];

    if (treeId != null && treeId.isNotEmpty) {
      whereClauses.add('tree_id = ?');
      whereArgs.add(treeId);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'start_date DESC, created_at DESC',
    );

    return maps.map(EventModel.fromMap).toList();
  }

  /// Получить все события в проекте
  Future<List<EventModel>> getAllEvents({String? treeId}) async {
    final Database db = await dbHelper.database;

    final List<Map<String, dynamic>> maps;

    if (treeId != null && treeId.isNotEmpty) {
      maps = await db.query(
        'events',
        where: 'tree_id = ?',
        whereArgs: <Object?>[treeId],
        orderBy: 'start_date DESC, created_at DESC',
      );
    } else {
      maps = await db.query(
        'events',
        orderBy: 'start_date DESC, created_at DESC',
      );
    }

    return maps.map(EventModel.fromMap).toList();
  }

  /// Обновить событие
  Future<EventModel> updateEvent(EventModel event) async {
    final Database db = await dbHelper.database;
    await db.update(
      'events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[event.id],
    );
    return event;
  }

  /// Удалить событие
  Future<void> deleteEvent(String id) async {
    final Database db = await dbHelper.database;
    await db.delete('events', where: 'id = ?', whereArgs: <Object?>[id]);
  }

  /// Удалить все события человека
  Future<void> deleteEventsByPersonId(String personId, {String? treeId}) async {
    final Database db = await dbHelper.database;
    final List<String> whereClauses = <String>['person_id = ?'];
    final List<Object?> whereArgs = <Object?>[personId];

    if (treeId != null && treeId.isNotEmpty) {
      whereClauses.add('tree_id = ?');
      whereArgs.add(treeId);
    }

    await db.delete(
      'events',
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
    );
  }

  /// Получить количество событий для человека
  Future<int> getEventsCountForPerson(String personId, {String? treeId}) async {
    final Database db = await dbHelper.database;

    final List<String> whereClauses = <String>['person_id = ?'];
    final List<Object?> whereArgs = <Object?>[personId];

    if (treeId != null && treeId.isNotEmpty) {
      whereClauses.add('tree_id = ?');
      whereArgs.add(treeId);
    }

    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM events WHERE ${whereClauses.join(' AND ')}',
      whereArgs,
    );

    if (result.isNotEmpty && result.first.containsKey('count')) {
      return result.first['count'] as int? ?? 0;
    }
    return 0;
  }
}
