import '../entities/family.dart';
import '../entities/person.dart';

/// Интерфейс репозитория для работы с семьями
abstract class FamilyRepository {
  /// Добавить новую семью
  Future<Family> addFamily(Family family);

  /// Получить семью по ID
  Future<Family?> getFamily(String id);

  /// Получить все семьи
  Future<List<Family>> getAllFamilies();

  /// Обновить данные семьи
  Future<Family> updateFamily(Family family);

  /// Удалить семью
  Future<void> deleteFamily(String id);

  /// Получить все семьи, где участвует человек
  Future<List<Family>> getFamiliesByPerson(String personId);

  /// Получить семью, где человек является родителем
  Future<List<Family>> getFamiliesAsParent(String personId);

  /// Добавить ребенка в семью
  Future<void> addChildToFamily(String familyId, String childId);

  /// Удалить ребенка из семьи
  Future<void> removeChildFromFamily(String familyId, String childId);
}
