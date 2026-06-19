import 'package:dartz/dartz.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/core/utils/gedcom_generator.dart';
import 'package:nm_gen/domain/entities/family.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/repositories/family_repository.dart';
import 'package:nm_gen/domain/repositories/person_repository.dart';

/// Use Case: Экспорт данных в GEDCOM файл
class ExportGedcomUseCase {
  ExportGedcomUseCase({
    required this.personRepository,
    required this.familyRepository,
  });
  final PersonRepository personRepository;
  final FamilyRepository familyRepository;

  Future<Either<Failure, String>> execute() async {
    try {
      // Получаем всех людей и семьи
      final List<Person> persons = await personRepository.getAllPersons();
      final List<Family> families = await familyRepository.getAllFamilies();

      if (persons.isEmpty) {
        return const Left(ValidationFailure('Нет данных для экспорта'));
      }

      // Генерируем GEDCOM
      final String gedcom = GedcomGenerator.generate(persons, families);
      return Right(gedcom);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
