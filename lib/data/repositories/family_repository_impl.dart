import 'package:injectable/injectable.dart';
import 'package:nm_gen/domain/entities/family.dart';
import 'package:nm_gen/domain/repositories/family_repository.dart';

/// Реализация репозитория семей в памяти (для разработки)
@Injectable(as: FamilyRepository) // <-- Добавляем аннотацию
class FamilyRepositoryImpl implements FamilyRepository {
  final Map<String, Family> _storage = {};

  @override
  Future<Family> addFamily(Family family) async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (_storage.containsKey(family.id)) {
      throw Exception('Family with id ${family.id} already exists');
    }

    _storage[family.id] = family;
    return family;
  }

  @override
  Future<Family?> getFamily(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _storage[id];
  }

  @override
  Future<List<Family>> getAllFamilies() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _storage.values.toList();
  }

  @override
  Future<Family> updateFamily(Family family) async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (!_storage.containsKey(family.id)) {
      throw Exception('Family with id ${family.id} not found');
    }

    _storage[family.id] = family;
    return family;
  }

  @override
  Future<void> deleteFamily(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _storage.remove(id);
  }

  @override
  Future<List<Family>> getFamiliesByPerson(String personId) async {
    await Future.delayed(const Duration(milliseconds: 100));

    return _storage.values.where((family) {
      return family.husbandId == personId ||
          family.wifeId == personId ||
          family.childrenIds.contains(personId);
    }).toList();
  }

  @override
  Future<List<Family>> getFamiliesAsParent(String personId) async {
    await Future.delayed(const Duration(milliseconds: 100));

    return _storage.values.where((family) {
      return family.husbandId == personId || family.wifeId == personId;
    }).toList();
  }

  @override
  Future<void> addChildToFamily(String familyId, String childId) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final family = _storage[familyId];
    if (family == null) {
      throw Exception('Family with id $familyId not found');
    }

    if (!family.childrenIds.contains(childId)) {
      final updatedFamily = family.copyWith(
        childrenIds: [...family.childrenIds, childId],
      );
      _storage[familyId] = updatedFamily;
    }
  }

  @override
  Future<void> removeChildFromFamily(String familyId, String childId) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final family = _storage[familyId];
    if (family == null) {
      throw Exception('Family with id $familyId not found');
    }

    final updatedChildren = family.childrenIds
        .where((id) => id != childId)
        .toList();
    final updatedFamily = family.copyWith(childrenIds: updatedChildren);
    _storage[familyId] = updatedFamily;
  }

  void clear() {
    _storage.clear();
  }
}
