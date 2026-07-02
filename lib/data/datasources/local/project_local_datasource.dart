import 'package:nm_gen/data/datasources/local/database/db_helper.dart';
import 'package:nm_gen/data/datasources/local/database/project_model.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:injectable/injectable.dart';

@injectable
class ProjectLocalDataSource {
  ProjectLocalDataSource(this.dbHelper);
  final DatabaseHelper dbHelper;

  /// Вставить новый проект
  Future<ProjectModel> insertProject(ProjectModel project) async {
    final Database db = await dbHelper.database;
    await db.insert('projects', project.toMap());
    return project;
  }

  /// Получить все проекты
  Future<List<ProjectModel>> getAllProjects() async {
    final Database db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'projects',
      orderBy: 'created_at DESC',
    );
    return maps.map(ProjectModel.fromMap).toList();
  }

  /// Получить проект по ID
  Future<ProjectModel?> getProjectById(String id) async {
    final Database db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'projects',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
    if (maps.isEmpty) return null;
    return ProjectModel.fromMap(maps.first);
  }

  /// Обновить проект
  Future<ProjectModel> updateProject(ProjectModel project) async {
    final Database db = await dbHelper.database;
    await db.update(
      'projects',
      project.toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[project.id],
    );
    return project;
  }

  /// Удалить проект
  Future<void> deleteProject(String id) async {
    final Database db = await dbHelper.database;
    await db.delete('projects', where: 'id = ?', whereArgs: <Object?>[id]);
  }

  /// Получить количество проектов
  Future<int> getProjectsCount() async {
    final Database db = await dbHelper.database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM projects',
    );
    if (result.isNotEmpty && result.first.containsKey('count')) {
      return result.first['count'] as int? ?? 0;
    }
    return 0;
  }

  /// Проверить, можно ли удалить проект (нет персон и семей)
  Future<bool> canDeleteProject({required String treeId}) async {
    final Database db = await dbHelper.database;

    // Проверяем наличие персон в проекте
    final personsResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM persons WHERE tree_id = ?',
      [treeId],
    );
    final personsCount =
        personsResult.isNotEmpty && personsResult.first.containsKey('count')
        ? personsResult.first['count'] as int? ?? 0
        : 0;

    // Проверяем наличие семей в проекте
    final familiesResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM families WHERE tree_id = ?',
      [treeId],
    );
    final familiesCount =
        familiesResult.isNotEmpty && familiesResult.first.containsKey('count')
        ? familiesResult.first['count'] as int? ?? 0
        : 0;

    // Проект можно удалить, если нет персон и нет семей
    return personsCount == 0 && familiesCount == 0;
  }

  // =========================================================================
  // ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ДЛЯ ПОДСЧЕТА СТАТИСТИКИ
  // =========================================================================

  /// Получить количество людей в проекте
  Future<int> getPersonsCountForProject({required String treeId}) async {
    final Database db = await dbHelper.database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM persons WHERE tree_id = ?',
      [treeId],
    );
    if (result.isNotEmpty && result.first.containsKey('count')) {
      return result.first['count'] as int? ?? 0;
    }
    return 0;
  }

  /// Получить количество семей в проекте
  Future<int> getFamiliesCountForProject({required String treeId}) async {
    final Database db = await dbHelper.database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM families WHERE tree_id = ?',
      [treeId],
    );
    if (result.isNotEmpty && result.first.containsKey('count')) {
      return result.first['count'] as int? ?? 0;
    }
    return 0;
  }

  /// Удалить все данные проекта (люди и семьи)
  Future<void> deleteAllProjectData({required String treeId}) async {
    final Database db = await dbHelper.database;

    // Удаляем всех людей из проекта
    await db.delete(
      'persons',
      where: 'tree_id = ?',
      whereArgs: <Object?>[treeId],
    );

    // Удаляем все семьи из проекта
    await db.delete(
      'families',
      where: 'tree_id = ?',
      whereArgs: <Object?>[treeId],
    );
  }

  /// Получить проект по умолчанию
  Future<ProjectModel?> getDefaultProject() async {
    final Database db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'projects',
      where: 'is_default = ?',
      whereArgs: [1],
    );
    if (maps.isEmpty) return null;
    return ProjectModel.fromMap(maps.first);
  }

  /// Установить проект как проект по умолчанию
  Future<void> setDefaultProject(String id) async {
    final Database db = await dbHelper.database;

    // Сбрасываем флаг у всех проектов
    await db.update('projects', {'is_default': 0});

    // Устанавливаем флаг у выбранного проекта
    await db.update(
      'projects',
      {'is_default': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
