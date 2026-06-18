import 'package:dartz/dartz.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/core/utils/gedcom_parser.dart';
import 'package:nm_gen/domain/entities/family.dart';
import 'package:nm_gen/domain/repositories/family_repository.dart';
import 'package:nm_gen/domain/repositories/person_repository.dart';

/// Use Case: Импорт данных из GEDCOM файла
class ImportGedcomUseCase {
  final PersonRepository personRepository;
  final FamilyRepository familyRepository;

  ImportGedcomUseCase({
    required this.personRepository,
    required this.familyRepository,
  });

  Future<Either<Failure, int>> execute(String content) async {
    try {
      if (content.isEmpty) {
        return Left(ValidationFailure('GEDCOM файл пуст'));
      }

      // Парсим GEDCOM
      final data = GedcomParser.parse(content);

      if (data.individuals.isEmpty) {
        return Left(ValidationFailure('В GEDCOM файле нет людей'));
      }

      // Создаем маппинг старых ID на новые
      final idMap = <String, String>{};
      var importedCount = 0;

      // Импортируем людей
      for (final individual in data.individuals) {
        if (individual.name.isEmpty) continue;

        final person = GedcomParser.toPerson(individual);
        final savedPerson = await personRepository.addPerson(person);
        idMap[individual.id] = savedPerson.id;
        importedCount++;
      }

      // Импортируем семьи
      for (final gedcomFamily in data.families) {
        final family = Family(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          husbandId: idMap[gedcomFamily.husbandId],
          wifeId: idMap[gedcomFamily.wifeId],
          childrenIds: gedcomFamily.childrenIds
              .map((id) => idMap[id])
              .whereType<String>()
              .toList(),
          marriageDate: gedcomFamily.marriageDate != null
              ? _parseDate(gedcomFamily.marriageDate!)
              : null,
          divorceDate: gedcomFamily.divorceDate != null
              ? _parseDate(gedcomFamily.divorceDate!)
              : null,
        );

        // Проверяем, что в семье есть хотя бы один родитель
        if (family.husbandId != null || family.wifeId != null) {
          await familyRepository.addFamily(family);
        }
      }

      return Right(importedCount);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  DateTime? _parseDate(String date) {
    if (date.isEmpty) return null;
    final months = {
      'JAN': 1,
      'FEB': 2,
      'MAR': 3,
      'APR': 4,
      'MAY': 5,
      'JUN': 6,
      'JUL': 7,
      'AUG': 8,
      'SEP': 9,
      'OCT': 10,
      'NOV': 11,
      'DEC': 12,
    };

    final parts = date.split(' ');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = months[parts[1].toUpperCase()];
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }
    return null;
  }
}
