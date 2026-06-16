import 'package:nm_gen/data/datasources/local/database/db_helper.dart';
import 'package:nm_gen/data/datasources/local/database/family_model.dart';

/// Локальный источник данных для Family
class FamilyLocalDataSource {
  final DatabaseHelper dbHelper;

  FamilyLocalDataSource(this.dbHelper);

  /// Вставить новую семью
  Future<FamilyModel> insertFamily(FamilyModel family) async {
    final db = await dbHelper.database;
    await db.insert('families', family.toMap());
    return family;
  }

  /// Получить семью по ID
  Future<FamilyModel?> getFamily(String id) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'families',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return FamilyModel.fromMap(maps.first);
  }

  /// Получить все семьи
  Future<List<FamilyModel>> getAllFamilies() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('families');

    return maps.map((map) => FamilyModel.fromMap(map)).toList();
  }

  /// Обновить семью
  Future<FamilyModel> updateFamily(FamilyModel family) async {
    final db = await dbHelper.database;
    await db.update(
      'families',
      family.toMap(),
      where: 'id = ?',
      whereArgs: [family.id],
    );
    return family;
  }

  /// Удалить семью
  Future<void> deleteFamily(String id) async {
    final db = await dbHelper.database;
    await db.delete('families', where: 'id = ?', whereArgs: [id]);
  }

  /// Получить семьи, где участвует человек
  Future<List<FamilyModel>> getFamiliesByPerson(String personId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'families',
      where: 'husband_id = ? OR wife_id = ? OR children_ids LIKE ?',
      whereArgs: [personId, personId, '%$personId%'],
    );

    return maps.map((map) => FamilyModel.fromMap(map)).toList();
  }

  /// Получить семьи, где человек является родителем
  Future<List<FamilyModel>> getFamiliesAsParent(String personId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'families',
      where: 'husband_id = ? OR wife_id = ?',
      whereArgs: [personId, personId],
    );

    return maps.map((map) => FamilyModel.fromMap(map)).toList();
  }

  /// Добавить ребенка в семью
  Future<void> addChildToFamily(String familyId, String childId) async {
    final family = await getFamily(familyId);
    if (family == null) return;

    final childrenIds = family.childrenIds.isEmpty
        ? [childId]
        : [...family.childrenIds.split(','), childId];

    final updatedFamily = FamilyModel(
      id: family.id,
      husbandId: family.husbandId,
      wifeId: family.wifeId,
      childrenIds: childrenIds.join(','),
      marriageDate: family.marriageDate,
      divorceDate: family.divorceDate,
      marriagePlace: family.marriagePlace,
      notes: family.notes,
    );

    await updateFamily(updatedFamily);
  }

  /// Удалить ребенка из семьи
  Future<void> removeChildFromFamily(String familyId, String childId) async {
    final family = await getFamily(familyId);
    if (family == null) return;

    final childrenIds = family.childrenIds.isEmpty
        ? []
        : family.childrenIds.split(',').where((id) => id != childId).toList();

    final updatedFamily = FamilyModel(
      id: family.id,
      husbandId: family.husbandId,
      wifeId: family.wifeId,
      childrenIds: childrenIds.join(','),
      marriageDate: family.marriageDate,
      divorceDate: family.divorceDate,
      marriagePlace: family.marriagePlace,
      notes: family.notes,
    );

    await updateFamily(updatedFamily);
  }

  /// Очистить все данные (для тестирования)
  Future<void> clearAll() async {
    final db = await dbHelper.database;
    await db.delete('families');
  }
}
