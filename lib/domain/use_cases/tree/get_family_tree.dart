import 'package:dartz/dartz.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/entities/tree_node.dart';
import 'package:nm_gen/domain/repositories/family_repository.dart';
import 'package:nm_gen/domain/repositories/person_repository.dart';

/// Use Case: Получение генеалогического древа в виде дерева узлов
class GetFamilyTreeUseCase {
  final PersonRepository personRepository;
  final FamilyRepository familyRepository;

  GetFamilyTreeUseCase({
    required this.personRepository,
    required this.familyRepository,
  });

  /// Получить дерево начиная с корневого человека
  Future<Either<Failure, TreeNode>> execute(String rootPersonId) async {
    try {
      // 1. Получаем корневого человека
      final rootPerson = await personRepository.getPerson(rootPersonId);
      if (rootPerson == null) {
        return Left(
          NotFoundFailure('Корневой человек с ID $rootPersonId не найден'),
        );
      }

      // 2. Строим дерево рекурсивно
      final visited = <String>{};
      final treeNode = await _buildTree(rootPerson, visited);

      return Right(treeNode);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Рекурсивное построение дерева
  Future<TreeNode> _buildTree(Person person, Set<String> visited) async {
    // Защита от бесконечной рекурсии
    if (visited.contains(person.id)) {
      return TreeNode(person: person);
    }
    visited.add(person.id);

    // Получаем семьи, где человек является родителем
    final parentFamilies = await familyRepository.getFamiliesAsParent(
      person.id,
    );

    // Собираем всех детей
    final childrenNodes = <TreeNode>[];
    for (final family in parentFamilies) {
      for (final childId in family.childrenIds) {
        final child = await personRepository.getPerson(childId);
        if (child != null) {
          final childNode = await _buildTree(child, visited);
          childrenNodes.add(childNode);
        }
      }
    }

    // Получаем супругов
    final spouseNodes = <TreeNode>[];
    final allFamilies = await familyRepository.getFamiliesByPerson(person.id);
    for (final family in allFamilies) {
      if (family.husbandId == person.id && family.wifeId != null) {
        final spouse = await personRepository.getPerson(family.wifeId!);
        if (spouse != null && !visited.contains(spouse.id)) {
          spouseNodes.add(TreeNode(person: spouse));
        }
      } else if (family.wifeId == person.id && family.husbandId != null) {
        final spouse = await personRepository.getPerson(family.husbandId!);
        if (spouse != null && !visited.contains(spouse.id)) {
          spouseNodes.add(TreeNode(person: spouse));
        }
      }
    }

    return TreeNode(
      person: person,
      children: childrenNodes,
      spouses: spouseNodes,
      isRoot: visited.length == 1,
    );
  }
}
