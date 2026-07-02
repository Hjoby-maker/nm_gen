import 'package:nm_gen/data/datasources/local/database/db_helper.dart';
import 'package:nm_gen/data/datasources/local/database/family_model.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:injectable/injectable.dart';

@injectable
class FamilyLocalDataSource {
  FamilyLocalDataSource(this.dbHelper);
  final DatabaseHelper dbHelper;

  /// Вставить новую семью
  Future<FamilyModel> insertFamily(FamilyModel family) async {
    final Database db = await dbHelper.database;
    await db.insert('families', family.toMap());
    return family;
  }

  /// Получить семью по ID
  Future<FamilyModel?> getFamily(String id) async {
    final Database db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'families',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );

    if (maps.isEmpty) return null;
    return FamilyModel.fromMap(maps.first);
  }

  /// Получить все семьи (с фильтром по treeId)
  Future<List<FamilyModel>> getAllFamilies({String? treeId}) async {
    final Database db = await dbHelper.database;

    final List<Map<String, dynamic>> maps;

    if (treeId != null && treeId.isNotEmpty) {
      maps = await db.query(
        'families',
        where: 'tree_id = ?',
        whereArgs: <Object?>[treeId],
        orderBy: 'marriage_date DESC',
      );
    } else {
      maps = await db.query('families', orderBy: 'marriage_date DESC');
    }

    return maps
        .map((Map<String, dynamic> map) => FamilyModel.fromMap(map))
        .toList();
  }

  /// Обновить семью
  Future<FamilyModel> updateFamily(FamilyModel family) async {
    final Database db = await dbHelper.database;
    await db.update(
      'families',
      family.toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[family.id],
    );
    return family;
  }

  /// Удалить семью
  Future<void> deleteFamily(String id) async {
    final Database db = await dbHelper.database;
    await db.delete('families', where: 'id = ?', whereArgs: <Object?>[id]);
  }

  /// Удалить все семьи в древе
  Future<void> deleteAllFamilies({String? treeId}) async {
    final Database db = await dbHelper.database;
    if (treeId != null && treeId.isNotEmpty) {
      await db.delete(
        'families',
        where: 'tree_id = ?',
        whereArgs: <Object?>[treeId],
      );
    } else {
      await db.delete('families');
    }
  }

  /// Получить семьи, где участвует человек (с фильтром по treeId)
  Future<List<FamilyModel>> getFamiliesByPerson(
    String personId, {
    String? treeId,
  }) async {
    final Database db = await dbHelper.database;

    final List<String> whereClauses = [
      'husband_id = ? OR wife_id = ? OR children_ids LIKE ?',
    ];
    final List<Object?> whereArgs = [personId, personId, '%$personId%'];

    if (treeId != null && treeId.isNotEmpty) {
      whereClauses.add('tree_id = ?');
      whereArgs.add(treeId);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'families',
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
    );

    return maps
        .map((Map<String, dynamic> map) => FamilyModel.fromMap(map))
        .toList();
  }

  /// Получить семьи, где человек является родителем (с фильтром по treeId)
  Future<List<FamilyModel>> getFamiliesAsParent(
    String personId, {
    String? treeId,
  }) async {
    final Database db = await dbHelper.database;

    final List<String> whereClauses = ['husband_id = ? OR wife_id = ?'];
    final List<Object?> whereArgs = [personId, personId];

    if (treeId != null && treeId.isNotEmpty) {
      whereClauses.add('tree_id = ?');
      whereArgs.add(treeId);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'families',
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
    );

    return maps
        .map((Map<String, dynamic> map) => FamilyModel.fromMap(map))
        .toList();
  }

  /// Получить семьи, где человек является ребенком (с фильтром по treeId)
  Future<List<FamilyModel>> getFamiliesAsChild(
    String personId, {
    String? treeId,
  }) async {
    final Database db = await dbHelper.database;

    final List<String> whereClauses = ['children_ids LIKE ?'];
    final List<Object?> whereArgs = ['%$personId%'];

    if (treeId != null && treeId.isNotEmpty) {
      whereClauses.add('tree_id = ?');
      whereArgs.add(treeId);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'families',
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
    );

    return maps
        .map((Map<String, dynamic> map) => FamilyModel.fromMap(map))
        .toList();
  }

  /// Добавить ребенка в семью
  Future<void> addChildToFamily(String familyId, String childId) async {
    final FamilyModel? family = await getFamily(familyId);
    if (family == null) return;

    final List<String> childrenIds = family.childrenIds.isEmpty
        ? <String>[childId]
        : <String>[...family.childrenIds.split(','), childId];

    final FamilyModel updatedFamily = FamilyModel(
      id: family.id,
      treeId: family.treeId,
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
    final FamilyModel? family = await getFamily(familyId);
    if (family == null) return;

    final List<dynamic> childrenIds = family.childrenIds.isEmpty
        ? <dynamic>[]
        : family.childrenIds
              .split(',')
              .where((String id) => id != childId)
              .toList();

    final FamilyModel updatedFamily = FamilyModel(
      id: family.id,
      treeId: family.treeId,
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
    final Database db = await dbHelper.database;
    await db.delete('families');
  }
}
