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

  /// Получить полное дерево со всеми людьми проекта
  Future<Either<Failure, TreeNode>> execute({
    required String treeId,
    String? selectedPersonId,
  }) async {
    try {
      // 1. Получаем все данные
      final allPersons = await personRepository.getAllPersons(treeId: treeId);
      final allFamilies = await familyRepository.getAllFamilies(treeId: treeId);

      if (allPersons.isEmpty) {
        return Left(NotFoundFailure('В проекте нет людей для отображения'));
      }

      // 2. Создаем карты для быстрого доступа
      final personMap = {for (final p in allPersons) p.id: p};

      // 3. Строим простую структуру: каждый человек - отдельный узел
      final List<TreeNode> personNodes = [];

      for (final person in allPersons) {
        // Находим семьи, где человек - родитель
        final familiesAsParent = allFamilies
            .where((f) => f.husbandId == person.id || f.wifeId == person.id)
            .toList();

        // Находим семьи, где человек - ребенок
        final familiesAsChild = allFamilies
            .where((f) => f.childrenIds.contains(person.id))
            .toList();

        // Собираем детей
        final List<TreeNode> children = [];
        for (final family in familiesAsParent) {
          for (final childId in family.childrenIds) {
            final child = personMap[childId];
            if (child != null) {
              children.add(
                TreeNode(
                  person: child,
                  children: const [],
                  spouses: const [],
                  isRoot: false,
                  isCenter: child.id == selectedPersonId,
                ),
              );
            }
          }
        }

        // Собираем супругов
        final List<TreeNode> spouses = [];
        for (final family in familiesAsParent) {
          final spouseId = family.husbandId == person.id
              ? family.wifeId
              : family.husbandId;
          if (spouseId != null) {
            final spouse = personMap[spouseId];
            if (spouse != null) {
              spouses.add(
                TreeNode(
                  person: spouse,
                  children: const [],
                  spouses: const [],
                  isRoot: false,
                  isCenter: spouse.id == selectedPersonId,
                ),
              );
            }
          }
        }

        // Собираем родителей (как супругов для отображения)
        for (final family in familiesAsChild) {
          if (family.husbandId != null && family.husbandId != person.id) {
            final parent = personMap[family.husbandId!];
            if (parent != null &&
                !spouses.any((s) => s.person.id == parent.id)) {
              spouses.add(
                TreeNode(
                  person: parent,
                  children: const [],
                  spouses: const [],
                  isRoot: false,
                  isCenter: parent.id == selectedPersonId,
                ),
              );
            }
          }
          if (family.wifeId != null && family.wifeId != person.id) {
            final parent = personMap[family.wifeId!];
            if (parent != null &&
                !spouses.any((s) => s.person.id == parent.id)) {
              spouses.add(
                TreeNode(
                  person: parent,
                  children: const [],
                  spouses: const [],
                  isRoot: false,
                  isCenter: parent.id == selectedPersonId,
                ),
              );
            }
          }
        }

        final isSelected = person.id == selectedPersonId;
        final isRoot = familiesAsParent.isEmpty && familiesAsChild.isEmpty;

        personNodes.add(
          TreeNode(
            person: person,
            children: children,
            spouses: spouses,
            isRoot: isRoot,
            isCenter: isSelected,
          ),
        );
      }

      // 4. Создаем виртуальный корень "Все люди"
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
        children: personNodes,
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
