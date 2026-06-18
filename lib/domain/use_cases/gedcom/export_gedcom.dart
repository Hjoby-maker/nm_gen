import 'package:dartz/dartz.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/core/utils/gedcom_generator.dart';
import 'package:nm_gen/domain/repositories/family_repository.dart';
import 'package:nm_gen/domain/repositories/person_repository.dart';

/// Use Case: Экспорт данных в GEDCOM файл
class ExportGedcomUseCase {
  final PersonRepository personRepository;
  final FamilyRepository familyRepository;

  ExportGedcomUseCase({
    required this.personRepository,
    required this.familyRepository,
  });

  Future<Either<Failure, String>> execute() async {
    try {
      // Получаем всех людей и семьи
      final persons = await personRepository.getAllPersons();
      final families = await familyRepository.getAllFamilies();

      if (persons.isEmpty) {
        return Left(ValidationFailure('Нет данных для экспорта'));
      }

      // Генерируем GEDCOM
      final gedcom = GedcomGenerator.generate(persons, families);
      return Right(gedcom);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
