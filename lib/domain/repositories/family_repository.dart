import 'package:nm_gen/domain/entities/family.dart';

abstract class FamilyRepository {
  Future<Family> addFamily(Family family);
  Future<Family?> getFamily(String id);
  Future<List<Family>> getAllFamilies({String? treeId}); // <-- ДОБАВЛЯЕМ
  Future<Family> updateFamily(Family family);
  Future<void> deleteFamily(String id);
  Future<void> deleteAllFamilies({String? treeId}); // <-- ДОБАВЛЯЕМ
  Future<List<Family>> getFamiliesByPerson(
    String personId, {
    String? treeId,
  }); // <-- ДОБАВЛЯЕМ
  Future<List<Family>> getFamiliesAsParent(
    String personId, {
    String? treeId,
  }); // <-- ДОБАВЛЯЕМ
  Future<List<Family>> getFamiliesAsChild(
    String personId, {
    String? treeId,
  }); // <-- ДОБАВЛЯЕМ
  Future<void> addChildToFamily(String familyId, String childId);
  Future<void> removeChildFromFamily(String familyId, String childId);
}
