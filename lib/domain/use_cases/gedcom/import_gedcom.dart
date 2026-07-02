import 'package:dartz/dartz.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/core/utils/gedcom_parser.dart';
import 'package:nm_gen/domain/entities/family.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/repositories/family_repository.dart';
import 'package:nm_gen/domain/repositories/person_repository.dart';

/// Use Case: Импорт данных из GEDCOM файла
class ImportGedcomUseCase {
  ImportGedcomUseCase({
    required this.personRepository,
    required this.familyRepository,
  });
  final PersonRepository personRepository;
  final FamilyRepository familyRepository;

  Future<Either<Failure, int>> execute(String content, {String? treeId}) async {
    try {
      if (content.isEmpty) {
        return const Left(ValidationFailure('GEDCOM файл пуст'));
      }

      // Парсим GEDCOM
      final GedcomData data = GedcomParser.parse(content);

      if (data.individuals.isEmpty) {
        return const Left(ValidationFailure('В GEDCOM файле нет людей'));
      }

      // Создаем маппинг старых ID на новые
      final Map<String, String> idMap = <String, String>{};
      int importedCount = 0;

      // Импортируем людей
      for (final GedcomIndividual individual in data.individuals) {
        if (individual.name.isEmpty) continue;

        final Person person = GedcomParser.toPerson(individual);

        // Добавляем treeId к человеку
        final Person personWithTree = person.copyWith(
          treeId: treeId ?? 'default',
        );

        final Person savedPerson = await personRepository.addPerson(
          personWithTree,
        );
        idMap[individual.id] = savedPerson.id;
        importedCount++;
      }

      // Импортируем семьи
      for (final GedcomFamily gedcomFamily in data.families) {
        final Family family = Family(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          treeId: treeId ?? 'default', // <-- ДОБАВЛЯЕМ treeId
          husbandId: idMap[gedcomFamily.husbandId],
          wifeId: idMap[gedcomFamily.wifeId],
          childrenIds: gedcomFamily.childrenIds
              .map((String id) => idMap[id])
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
    final Map<String, int> months = <String, int>{
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

    final List<String> parts = date.split(' ');
    if (parts.length == 3) {
      final int? day = int.tryParse(parts[0]);
      final int? month = months[parts[1].toUpperCase()];
      final int? year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }
    return null;
  }
}
