import 'package:dartz/dartz.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/entities/family.dart';
import 'package:nm_gen/domain/entities/family_tree.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/repositories/family_repository.dart';
import 'package:nm_gen/domain/repositories/person_repository.dart';

/// Use Case: Получение полного генеалогического древа
class GetFamilyTreeUseCase {
  final PersonRepository personRepository;
  final FamilyRepository familyRepository;

  GetFamilyTreeUseCase({
    required this.personRepository,
    required this.familyRepository,
  });

  Future<Either<Failure, FamilyTree>> execute(String rootPersonId) async {
    try {
      // 1. Получаем корневого человека
      final rootPerson = await personRepository.getPerson(rootPersonId);
      if (rootPerson == null) {
        return Left(
          NotFoundFailure('Корневой человек с ID $rootPersonId не найден'),
        );
      }

      // 2. Получаем все семьи, где участвует этот человек
      final families = await familyRepository.getFamiliesByPerson(rootPersonId);

      // 3. Собираем всех родственников (рекурсивно)
      final allPersonIds = await _getAllRelatedPersons(rootPersonId, families);
      final allPersons = await personRepository.getPersonsByIds(allPersonIds);

      return Right(
        FamilyTree(
          rootPerson: rootPerson,
          allPersons: allPersons,
          families: families,
        ),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Рекурсивно собираем всех связанных людей
  Future<List<String>> _getAllRelatedPersons(
    String personId,
    List<Family> families,
  ) async {
    final Set<String> relatedIds = {personId};

    for (final family in families) {
      // Добавляем родителей
      relatedIds.addAll(family.parentIds);

      // Добавляем детей
      relatedIds.addAll(family.childrenIds);

      // Рекурсивно обрабатываем детей (глубина ограничена 10 уровнями)
      for (final childId in family.childrenIds) {
        final childFamilies = await familyRepository.getFamiliesByPerson(
          childId,
        );
        final childRelated = await _getAllRelatedPersons(
          childId,
          childFamilies,
        );
        relatedIds.addAll(childRelated);
      }
    }

    return relatedIds.toList();
  }
}
