// lib/domain/use_cases/person/get_person_relatives.dart
import 'package:dartz/dartz.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/entities/family.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/entities/person_relatives.dart';
import 'package:nm_gen/domain/repositories/family_repository.dart';
import 'package:nm_gen/domain/repositories/person_repository.dart';

/// Use Case: получить ближайшее родственное окружение человека -
/// родителей, супруга(ов), детей и братьев/сестёр, для HUD-компаса на
/// экране деталей человека.
///
/// Не переиспользует GetFamilyTreeUseCase/GetFullTreeUseCase намеренно:
/// те строят TreeNode для отрисовки всего дерева и складывают
/// родителей/супругов/братьев-сестёр/племянников в один общий список
/// spouses без разметки, кто есть кто - для компаса же нужны 4 отдельные,
/// заранее категоризированные группы.
class GetPersonRelativesUseCase {
  GetPersonRelativesUseCase({
    required this.personRepository,
    required this.familyRepository,
  });

  final PersonRepository personRepository;
  final FamilyRepository familyRepository;

  Future<Either<Failure, PersonRelatives>> execute(
    String personId, {
    String? treeId,
  }) async {
    try {
      final List<Family> allFamilies = await familyRepository.getAllFamilies(
        treeId: treeId,
      );

      final Set<String> parentIds = <String>{};
      final Set<String> siblingIds = <String>{};
      final Set<String> spouseIds = <String>{};
      final Set<String> childIds = <String>{};

      for (final Family family in allFamilies) {
        final bool isChildHere = family.childrenIds.contains(personId);
        final bool isParentHere =
            family.husbandId == personId || family.wifeId == personId;

        if (isChildHere) {
          // Семья, где наш человек - один из детей: родители этой семьи -
          // его родители, а остальные дети - его братья/сёстры.
          if (family.husbandId != null) parentIds.add(family.husbandId!);
          if (family.wifeId != null) parentIds.add(family.wifeId!);
          for (final String childId in family.childrenIds) {
            if (childId != personId) siblingIds.add(childId);
          }
        }

        if (isParentHere) {
          // Семья, где наш человек - муж/жена: второй родитель - супруг,
          // а дети этой семьи - его собственные дети.
          final String? spouseId = family.husbandId == personId
              ? family.wifeId
              : family.husbandId;
          if (spouseId != null) spouseIds.add(spouseId);
          childIds.addAll(family.childrenIds);
        }
      }

      // На всякий случай исключаем самого человека отовсюду (например,
      // если в данных где-то есть противоречивая/битая запись).
      parentIds.remove(personId);
      siblingIds.remove(personId);
      spouseIds.remove(personId);
      childIds.remove(personId);

      final List<String> neededIds = <String>{
        ...parentIds,
        ...siblingIds,
        ...spouseIds,
        ...childIds,
      }.toList();

      if (neededIds.isEmpty) {
        return const Right(PersonRelatives.empty);
      }

      final List<Person> relatedPersons = await personRepository
          .getPersonsByIds(neededIds, treeId: treeId);
      final Map<String, Person> personMap = <String, Person>{
        for (final Person p in relatedPersons) p.id: p,
      };

      List<Person> resolve(Set<String> ids) => ids
          .map((String id) => personMap[id])
          .whereType<Person>()
          .toList();

      return Right(
        PersonRelatives(
          parents: resolve(parentIds),
          spouses: resolve(spouseIds),
          children: resolve(childIds),
          siblings: resolve(siblingIds),
        ),
      );
    } catch (e) {
      return Left(
        ServerFailure('Ошибка получения родственного окружения: $e'),
      );
    }
  }
}