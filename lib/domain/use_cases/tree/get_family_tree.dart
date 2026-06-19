import 'package:dartz/dartz.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/entities/family.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/entities/tree_node.dart';
import 'package:nm_gen/domain/repositories/family_repository.dart';
import 'package:nm_gen/domain/repositories/person_repository.dart';

/// Use Case: Получение генеалогического древа с полным обходом всех связей
class GetFamilyTreeUseCase {
  final PersonRepository personRepository;
  final FamilyRepository familyRepository;

  GetFamilyTreeUseCase({
    required this.personRepository,
    required this.familyRepository,
  });

  /// Получить полное дерево, начиная с выбранного человека
  Future<Either<Failure, TreeNode>> execute(String centerPersonId) async {
    try {
      // 1. Получаем центрального человека
      final centerPerson = await personRepository.getPerson(centerPersonId);
      if (centerPerson == null) {
        return Left(NotFoundFailure('Человек с ID $centerPersonId не найден'));
      }

      // 2. Получаем все семьи
      final allFamilies = await familyRepository.getAllFamilies();

      // 3. Получаем всех людей (для построения полного дерева)
      final allPersons = await personRepository.getAllPersons();

      // 4. Строим дерево ОТ ЦЕНТРАЛЬНОГО человека, но с полным обходом всех связей
      // Сначала собираем всех связанных людей
      final allRelatedIds = <String>{};
      await _collectAllRelatives(centerPersonId, allRelatedIds, allFamilies);

      // Добавляем центрального человека
      allRelatedIds.add(centerPersonId);

      // Получаем только связанных людей
      final relatedPersons = allPersons
          .where((p) => allRelatedIds.contains(p.id))
          .toList();

      // 5. Строим дерево от центрального человека, но включаем ВСЕХ родственников
      final visited = <String>{};
      final rootNode = await _buildTreeFromCenterWithAllRelatives(
        centerPerson,
        relatedPersons,
        allFamilies,
        visited,
        centerPersonId,
      );

      return Right(rootNode);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Рекурсивный сбор всех связанных людей (BFS)
  Future<void> _collectAllRelatives(
    String personId,
    Set<String> collected,
    List<Family> allFamilies,
  ) async {
    if (collected.contains(personId)) return;
    collected.add(personId);

    // Находим все семьи, где участвует этот человек
    final relatedFamilies = allFamilies
        .where(
          (family) =>
              family.husbandId == personId ||
              family.wifeId == personId ||
              family.childrenIds.contains(personId),
        )
        .toList();

    for (final family in relatedFamilies) {
      // Добавляем супругов
      if (family.husbandId != null && !collected.contains(family.husbandId)) {
        await _collectAllRelatives(family.husbandId!, collected, allFamilies);
      }
      if (family.wifeId != null && !collected.contains(family.wifeId)) {
        await _collectAllRelatives(family.wifeId!, collected, allFamilies);
      }

      // Добавляем детей
      for (final childId in family.childrenIds) {
        if (!collected.contains(childId)) {
          await _collectAllRelatives(childId, collected, allFamilies);
        }
      }
    }
  }

  /// Построение дерева от центрального человека со ВСЕМИ родственниками
  Future<TreeNode> _buildTreeFromCenterWithAllRelatives(
    Person centerPerson,
    List<Person> allRelatedPersons,
    List<Family> allFamilies,
    Set<String> visited,
    String centerPersonId,
  ) async {
    if (visited.contains(centerPerson.id)) {
      return TreeNode(person: centerPerson);
    }
    visited.add(centerPerson.id);

    final isCenter = centerPerson.id == centerPersonId;

    // Находим семьи, где центральный человек является родителем
    final parentFamilies = allFamilies
        .where(
          (family) =>
              family.husbandId == centerPerson.id ||
              family.wifeId == centerPerson.id,
        )
        .toList();

    // Собираем детей (только если они есть в списке связанных людей)
    final childrenNodes = <TreeNode>[];
    for (final family in parentFamilies) {
      for (final childId in family.childrenIds) {
        final child = allRelatedPersons.firstWhere(
          (p) => p.id == childId,
          orElse: () => Person.empty(),
        );
        if (child.id.isNotEmpty && !visited.contains(child.id)) {
          final childNode = await _buildTreeFromCenterWithAllRelatives(
            child,
            allRelatedPersons,
            allFamilies,
            visited,
            centerPersonId,
          );
          childrenNodes.add(childNode);
        }
      }
    }

    // Собираем ВСЕХ супругов (включая родителей)
    final spouseNodes = <TreeNode>[];

    // 1. Супруги из семей, где центральный человек - родитель
    for (final family in parentFamilies) {
      final spouseId = family.husbandId == centerPerson.id
          ? family.wifeId
          : family.husbandId;
      if (spouseId != null) {
        final spouse = allRelatedPersons.firstWhere(
          (p) => p.id == spouseId,
          orElse: () => Person.empty(),
        );
        if (spouse.id.isNotEmpty && !visited.contains(spouse.id)) {
          // Для супруга строим поддерево (но ограничиваем глубину)
          final spouseNode = await _buildTreeFromCenterWithAllRelatives(
            spouse,
            allRelatedPersons,
            allFamilies,
            visited,
            centerPersonId,
          );
          spouseNodes.add(spouseNode);
        }
      }
    }

    // 2. Родители (в семьях, где центральный человек - ребенок)
    final childFamilies = allFamilies
        .where((family) => family.childrenIds.contains(centerPerson.id))
        .toList();

    for (final family in childFamilies) {
      // Отец
      if (family.husbandId != null && family.husbandId != centerPerson.id) {
        final parent = allRelatedPersons.firstWhere(
          (p) => p.id == family.husbandId,
          orElse: () => Person.empty(),
        );
        if (parent.id.isNotEmpty && !visited.contains(parent.id)) {
          // Добавляем родителя как супруга
          final parentNode = await _buildTreeFromCenterWithAllRelatives(
            parent,
            allRelatedPersons,
            allFamilies,
            visited,
            centerPersonId,
          );
          spouseNodes.add(parentNode);
        }
      }
      // Мать
      if (family.wifeId != null && family.wifeId != centerPerson.id) {
        final parent = allRelatedPersons.firstWhere(
          (p) => p.id == family.wifeId,
          orElse: () => Person.empty(),
        );
        if (parent.id.isNotEmpty && !visited.contains(parent.id)) {
          final parentNode = await _buildTreeFromCenterWithAllRelatives(
            parent,
            allRelatedPersons,
            allFamilies,
            visited,
            centerPersonId,
          );
          spouseNodes.add(parentNode);
        }
      }
    }

    // 3. Братья и сестры (добавляем как детей родителей)
    for (final family in childFamilies) {
      for (final childId in family.childrenIds) {
        if (childId != centerPerson.id) {
          final sibling = allRelatedPersons.firstWhere(
            (p) => p.id == childId,
            orElse: () => Person.empty(),
          );
          if (sibling.id.isNotEmpty && !visited.contains(sibling.id)) {
            // Добавляем брата/сестру как отдельную связь
            final siblingNode = await _buildTreeFromCenterWithAllRelatives(
              sibling,
              allRelatedPersons,
              allFamilies,
              visited,
              centerPersonId,
            );
            // Добавляем в супруги (как отдельную категорию)
            spouseNodes.add(siblingNode);
          }
        }
      }
    }

    return TreeNode(
      person: centerPerson,
      children: childrenNodes,
      spouses: spouseNodes,
      isRoot: childFamilies.isEmpty && parentFamilies.isEmpty,
      isCenter: isCenter,
    );
  }
}
