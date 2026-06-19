import 'package:dartz/dartz.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/entities/family.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/repositories/family_repository.dart';
import 'package:nm_gen/domain/repositories/person_repository.dart';

/// Детальная информация о семье
class FamilyDetails {
  const FamilyDetails({
    required this.family,
    this.husband,
    this.wife,
    this.children = const [],
  });
  final Family family;
  final Person? husband;
  final Person? wife;
  final List<Person> children;

  int get memberCount {
    int count = 0;
    if (husband != null) count++;
    if (wife != null) count++;
    count += children.length;
    return count;
  }

  bool get isComplete => husband != null && wife != null;
}

/// Use Case: Получение семьи с деталями
class GetFamilyWithDetailsUseCase {
  GetFamilyWithDetailsUseCase({
    required this.familyRepository,
    required this.personRepository,
  });
  final FamilyRepository familyRepository;
  final PersonRepository personRepository;

  Future<Either<Failure, FamilyDetails>> execute(String familyId) async {
    try {
      if (familyId.isEmpty) {
        return const Left(ValidationFailure('ID семьи не может быть пустым'));
      }

      final Family? family = await familyRepository.getFamily(familyId);
      if (family == null) {
        return Left(NotFoundFailure('Семья с ID $familyId не найдена'));
      }

      // Загружаем супругов
      Person? husband;
      if (family.husbandId != null) {
        husband = await personRepository.getPerson(family.husbandId!);
      }

      Person? wife;
      if (family.wifeId != null) {
        wife = await personRepository.getPerson(family.wifeId!);
      }

      // Загружаем детей
      final List<Person> children = <Person>[];
      for (final String childId in family.childrenIds) {
        final Person? child = await personRepository.getPerson(childId);
        if (child != null) {
          children.add(child);
        }
      }

      return Right(
        FamilyDetails(
          family: family,
          husband: husband,
          wife: wife,
          children: children,
        ),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
