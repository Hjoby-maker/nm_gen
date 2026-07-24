import 'package:dartz/dartz.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/entities/family.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/entities/tree_node.dart';
import 'package:nm_gen/domain/repositories/family_repository.dart';
import 'package:nm_gen/domain/repositories/person_repository.dart';
import 'package:nm_gen/core/enums/gender.dart';

/// Use Case: Получение полного генеалогического древа для проекта
class GetFullTreeUseCase {
  final PersonRepository personRepository;
  final FamilyRepository familyRepository;

  GetFullTreeUseCase({
    required this.personRepository,
    required this.familyRepository,
  });

  Future<Either<Failure, TreeNode>> execute({
    required String treeId,
    String? selectedPersonId,
  }) async {
    try {
      final allPersons = await personRepository.getAllPersons(treeId: treeId);
      final allFamilies = await familyRepository.getAllFamilies(treeId: treeId);

      if (allPersons.isEmpty) {
        //return Left(NotFoundFailure('В проекте нет людей для отображения'));

        final emptyRoot = TreeNode(
          person: Person(
            id: 'virtual_root',
            treeId: treeId,
            firstName: 'Все люди',
            lastName: '',
            gender: Gender.unknown,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          children: const [],
          spouses: const [],
          isRoot: true,
          isCenter: false,
        );
        return Right(emptyRoot);
      }

      final personMap = {for (final p in allPersons) p.id: p};

      final Map<String, List<Family>> familiesAsParentMap = {};
      final Map<String, List<Family>> familiesAsChildMap = {};

      for (final family in allFamilies) {
        if (family.husbandId != null) {
          familiesAsParentMap
              .putIfAbsent(family.husbandId!, () => [])
              .add(family);
        }
        if (family.wifeId != null) {
          familiesAsParentMap.putIfAbsent(family.wifeId!, () => []).add(family);
        }

        // ✅ ФИКС: в базе встречаются "семьи" без единого родителя
        // (husbandId == null И wifeId == null), которые на деле - не
        // отношение "родитель → ребёнок", а группировка братьев/сестёр
        // (childrenIds там - это НЕ дети общего родителя, а участники
        // группы). Такая псевдо-семья никогда не попадёт в
        // familiesAsParentMap (родителя нет), а значит по ней невозможно
        // никого построить рекурсивно как ребёнка. Если её не
        // отфильтровать здесь, familiesAsChildMap ошибочно решит, что у
        // человека ЕСТЬ родитель, он перестанет считаться корнем, но и
        // ребёнком ни под кем реальным не станет - "потеряется" и попадёт
        // в аварийный fallback (см. п.6 ниже) в непредсказуемом порядке.
        // Именно это вызывало появление "двух Викторов".
        final bool hasRealParent =
            family.husbandId != null || family.wifeId != null;
        if (!hasRealParent) continue;

        for (final childId in family.childrenIds) {
          familiesAsChildMap.putIfAbsent(childId, () => []).add(family);
        }
      }

      final Set<String> renderedIds = {};

      TreeNode buildPersonNode(Person person, Set<String> visiting) {
        if (visiting.contains(person.id)) {
          return TreeNode(
            person: person,
            children: const [],
            spouses: const [],
            isRoot: false,
            isCenter: person.id == selectedPersonId,
            isDuplicateReference: true,
          );
        }

        if (renderedIds.contains(person.id)) {
          return TreeNode(
            person: person,
            children: const [],
            spouses: const [],
            isRoot: false,
            isCenter: person.id == selectedPersonId,
            isDuplicateReference: true,
          );
        }

        final nextVisiting = {...visiting, person.id};
        renderedIds.add(person.id);

        final parentFamilies = familiesAsParentMap[person.id] ?? const [];

        final List<TreeNode> spouses = [];
        final Set<String> spouseIds = {};
        for (final family in parentFamilies) {
          final spouseId = family.husbandId == person.id
              ? family.wifeId
              : family.husbandId;
          if (spouseId != null &&
              spouseId != person.id &&
              spouseIds.add(spouseId)) {
            final spousePerson = personMap[spouseId];
            if (spousePerson != null) {
              renderedIds.add(spouseId);
              spouses.add(
                TreeNode(
                  person: spousePerson,
                  children: const [],
                  spouses: const [],
                  isRoot: false,
                  isCenter: spouseId == selectedPersonId,
                ),
              );
            }
          }
        }

        final List<TreeNode> children = [];
        final Set<String> childIds = {};
        for (final family in parentFamilies) {
          for (final childId in family.childrenIds) {
            if (childIds.add(childId)) {
              final childPerson = personMap[childId];
              if (childPerson != null) {
                children.add(buildPersonNode(childPerson, nextVisiting));
              }
            }
          }
        }

        return TreeNode(
          person: person,
          children: children,
          spouses: spouses,
          isRoot: false,
          isCenter: person.id == selectedPersonId,
        );
      }

      final rootPersons = allPersons
          .where((p) => (familiesAsChildMap[p.id] ?? const []).isEmpty)
          .toList();

      final List<TreeNode> rootNodes = [];
      for (final person in rootPersons) {
        if (renderedIds.contains(person.id)) continue;
        final node = buildPersonNode(person, <String>{});
        rootNodes.add(
          TreeNode(
            person: node.person,
            children: node.children,
            spouses: node.spouses,
            isRoot: true,
            isCenter: node.isCenter,
          ),
        );
      }

      for (final person in allPersons) {
        if (!renderedIds.contains(person.id)) {
          final node = buildPersonNode(person, <String>{});
          rootNodes.add(
            TreeNode(
              person: node.person,
              children: node.children,
              spouses: node.spouses,
              isRoot: true,
              isCenter: node.isCenter,
            ),
          );
        }
      }

      final virtualRoot = TreeNode(
        person: Person(
          id: 'virtual_root',
          treeId: treeId,
          firstName: 'Все люди',
          lastName: '',
          gender: Gender.unknown,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        children: rootNodes,
        spouses: const [],
        isRoot: true,
        isCenter: false,
      );

      return Right(virtualRoot);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
