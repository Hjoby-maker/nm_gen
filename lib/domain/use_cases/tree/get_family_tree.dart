import 'dart:collection';
import 'package:dartz/dartz.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/entities/family.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/entities/tree_node.dart';
import 'package:nm_gen/domain/repositories/family_repository.dart';
import 'package:nm_gen/domain/repositories/person_repository.dart';
import 'package:nm_gen/core/enums/gender.dart';

/// Use Case: Получение генеалогического древа с полным обходом всех связей
class GetFamilyTreeUseCase {
  final PersonRepository personRepository;
  final FamilyRepository familyRepository;

  GetFamilyTreeUseCase({
    required this.personRepository,
    required this.familyRepository,
  });

  /// Получить полное дерево, начиная с выбранного человека
  Future<Either<Failure, TreeNode>> execute(
    String centerPersonId, {
    String? treeId,
  }) async {
    try {
      // 1. Получаем центрального человека
      final centerPerson = await personRepository.getPerson(centerPersonId);
      if (centerPerson == null) {
        return Left(NotFoundFailure('Человек с ID $centerPersonId не найден'));
      }

      // 2. Получаем ВСЕ данные (с фильтром по treeId)
      final allPersons = await personRepository.getAllPersons(treeId: treeId);
      final allFamilies = await familyRepository.getAllFamilies(treeId: treeId);

      // 3. Создаем карты для быстрого доступа
      final personMap = <String, Person>{};
      for (final person in allPersons) {
        personMap[person.id] = person;
      }

      // 4. Собираем ВСЕХ связанных людей (полный обход)
      final allRelatedIds = <String>{};
      _collectAllRelativesFull(centerPersonId, allRelatedIds, allFamilies);

      // Добавляем центрального человека
      allRelatedIds.add(centerPersonId);

      // 5. Получаем всех связанных людей
      final relatedPersons = allPersons
          .where((p) => allRelatedIds.contains(p.id))
          .toList();

      // 6. Строим граф от корневого человека
      final visited = <String>{};

      // Находим "корневого" человека
      String rootId = _findRootPerson(allRelatedIds, allFamilies);

      final rootNode = _buildFullGraph(
        rootId,
        relatedPersons,
        allFamilies,
        centerPersonId,
        personMap,
        visited,
        treeId: treeId,
      );

      return Right(rootNode);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Полный сбор ВСЕХ связанных людей (BFS обход)
  void _collectAllRelativesFull(
    String personId,
    Set<String> collected,
    List<Family> allFamilies,
  ) {
    if (collected.contains(personId)) return;

    // BFS обход
    final queue = Queue<String>();
    queue.add(personId);
    collected.add(personId);

    while (queue.isNotEmpty) {
      final currentId = queue.removeFirst();

      final relatedFamilies = allFamilies
          .where(
            (family) =>
                family.husbandId == currentId ||
                family.wifeId == currentId ||
                family.childrenIds.contains(currentId),
          )
          .toList();

      for (final family in relatedFamilies) {
        if (family.husbandId != null && !collected.contains(family.husbandId)) {
          collected.add(family.husbandId!);
          queue.add(family.husbandId!);
        }
        if (family.wifeId != null && !collected.contains(family.wifeId)) {
          collected.add(family.wifeId!);
          queue.add(family.wifeId!);
        }
        for (final childId in family.childrenIds) {
          if (!collected.contains(childId)) {
            collected.add(childId);
            queue.add(childId);
          }
        }
      }
    }
  }

  /// Найти корневого человека (первого в семейной иерархии)
  String _findRootPerson(Set<String> allIds, List<Family> allFamilies) {
    // Ищем человека, у которого нет родителей в нашем наборе
    for (final id in allIds) {
      bool hasParents = false;
      for (final family in allFamilies) {
        if (family.childrenIds.contains(id)) {
          hasParents = true;
          break;
        }
      }
      if (!hasParents) {
        return id;
      }
    }
    // Если все имеют родителей, возвращаем первого
    return allIds.first;
  }

  /// Создать пустого человека для неизвестных записей
  Person _createUnknownPerson(String id, {String? treeId}) {
    return Person(
      id: id,
      treeId: treeId ?? 'default', // <-- ДОБАВЛЯЕМ treeId
      firstName: 'Неизвестный',
      lastName: '',
      gender: Gender.unknown,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Построение полного графа (не дерева)
  TreeNode _buildFullGraph(
    String currentId,
    List<Person> allPersons,
    List<Family> allFamilies,
    String centerPersonId,
    Map<String, Person> personMap,
    Set<String> visited, {
    String? treeId,
  }) {
    final currentPerson = personMap[currentId];
    if (currentPerson == null || visited.contains(currentId)) {
      // Возвращаем пустой узел для уже посещенных
      return TreeNode(
        person:
            currentPerson ?? _createUnknownPerson(currentId, treeId: treeId),
        children: const [],
        spouses: const [],
        isRoot: false,
        isCenter: false,
      );
    }
    visited.add(currentId);

    final isCenter = currentId == centerPersonId;

    // ============================================================
    // 1. Собираем всех связанных людей
    // ============================================================

    // Семьи, где текущий человек - родитель
    final parentFamilies = allFamilies
        .where(
          (family) =>
              family.husbandId == currentId || family.wifeId == currentId,
        )
        .toList();

    // Семьи, где текущий человек - ребенок
    final childFamilies = allFamilies
        .where((family) => family.childrenIds.contains(currentId))
        .toList();

    final List<TreeNode> children = [];
    final List<TreeNode> spouses = [];

    // ============================================================
    // ДЕТИ (потомки)
    // ============================================================
    for (final family in parentFamilies) {
      for (final childId in family.childrenIds) {
        final childNode = _buildFullGraph(
          childId,
          allPersons,
          allFamilies,
          centerPersonId,
          personMap,
          visited,
          treeId: treeId,
        );
        if (childNode.person.id != '') {
          children.add(childNode);
        }
      }
    }

    // ============================================================
    // СУПРУГИ
    // ============================================================
    for (final family in parentFamilies) {
      final spouseId = family.husbandId == currentId
          ? family.wifeId
          : family.husbandId;
      if (spouseId != null) {
        final spouseNode = _buildFullGraph(
          spouseId,
          allPersons,
          allFamilies,
          centerPersonId,
          personMap,
          visited,
          treeId: treeId,
        );
        if (spouseNode.person.id != '') {
          spouses.add(spouseNode);
        }
      }
    }

    // ============================================================
    // РОДИТЕЛИ (добавляем как супругов для визуализации)
    // ============================================================
    for (final family in childFamilies) {
      if (family.husbandId != null && family.husbandId != currentId) {
        final parentNode = _buildFullGraph(
          family.husbandId!,
          allPersons,
          allFamilies,
          centerPersonId,
          personMap,
          visited,
          treeId: treeId,
        );
        if (parentNode.person.id != '') {
          spouses.add(parentNode);
        }
      }
      if (family.wifeId != null && family.wifeId != currentId) {
        final parentNode = _buildFullGraph(
          family.wifeId!,
          allPersons,
          allFamilies,
          centerPersonId,
          personMap,
          visited,
          treeId: treeId,
        );
        if (parentNode.person.id != '') {
          spouses.add(parentNode);
        }
      }
    }

    // ============================================================
    // БРАТЬЯ/СЕСТРЫ
    // ============================================================
    for (final family in childFamilies) {
      for (final childId in family.childrenIds) {
        if (childId != currentId) {
          final siblingNode = _buildFullGraph(
            childId,
            allPersons,
            allFamilies,
            centerPersonId,
            personMap,
            visited,
            treeId: treeId,
          );
          if (siblingNode.person.id != '') {
            spouses.add(siblingNode);
          }
        }
      }
    }

    // ============================================================
    // ПЛЕМЯННИКИ (дети братьев/сестер)
    // ============================================================
    // Получаем всех братьев/сестер из ранее добавленных
    final siblings = spouses.where((node) {
      // Проверяем, является ли этот человек братом/сестрой
      for (final family in childFamilies) {
        if (family.childrenIds.contains(node.person.id) &&
            node.person.id != currentId) {
          return true;
        }
      }
      return false;
    }).toList();

    for (final sibling in siblings) {
      final siblingParentFamilies = allFamilies
          .where(
            (family) =>
                family.husbandId == sibling.person.id ||
                family.wifeId == sibling.person.id,
          )
          .toList();

      for (final family in siblingParentFamilies) {
        for (final childId in family.childrenIds) {
          if (childId != currentId) {
            final nephewNode = _buildFullGraph(
              childId,
              allPersons,
              allFamilies,
              centerPersonId,
              personMap,
              visited,
              treeId: treeId,
            );
            if (nephewNode.person.id != '' &&
                !spouses.any((n) => n.person.id == nephewNode.person.id)) {
              spouses.add(nephewNode);
            }
          }
        }
      }
    }

    // ============================================================
    // ДЯДИ/ТЕТИ (родители родителей)
    // ============================================================
    // Для каждого родителя находим его родителей
    final parents = spouses.where((node) {
      for (final family in childFamilies) {
        if (family.husbandId == node.person.id ||
            family.wifeId == node.person.id) {
          return true;
        }
      }
      return false;
    }).toList();

    for (final parent in parents) {
      final grandparentFamilies = allFamilies
          .where((family) => family.childrenIds.contains(parent.person.id))
          .toList();

      for (final family in grandparentFamilies) {
        if (family.husbandId != null && family.husbandId != parent.person.id) {
          final grandparentNode = _buildFullGraph(
            family.husbandId!,
            allPersons,
            allFamilies,
            centerPersonId,
            personMap,
            visited,
            treeId: treeId,
          );
          if (grandparentNode.person.id != '' &&
              !spouses.any((n) => n.person.id == grandparentNode.person.id)) {
            spouses.add(grandparentNode);
          }
        }
        if (family.wifeId != null && family.wifeId != parent.person.id) {
          final grandparentNode = _buildFullGraph(
            family.wifeId!,
            allPersons,
            allFamilies,
            centerPersonId,
            personMap,
            visited,
            treeId: treeId,
          );
          if (grandparentNode.person.id != '' &&
              !spouses.any((n) => n.person.id == grandparentNode.person.id)) {
            spouses.add(grandparentNode);
          }
        }
      }
    }

    // ============================================================
    // ВОЗВРАЩАЕМ УЗЕЛ
    // ============================================================
    return TreeNode(
      person: currentPerson,
      children: children,
      spouses: spouses,
      isRoot: childFamilies.isEmpty && parentFamilies.isEmpty,
      isCenter: isCenter,
    );
  }
}
