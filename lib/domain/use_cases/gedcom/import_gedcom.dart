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
          treeId: treeId ?? 'default',
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

      // ============================================================
      // ДОБАВЛЯЕМ НЕДОСТАЮЩИЕ РОДИТЕЛЬСКИЕ СВЯЗИ
      // ============================================================
      await _createMissingParentLinks(data, idMap, treeId);

      return Right(importedCount);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Создает недостающие родительские связи для братьев и сестер
  Future<void> _createMissingParentLinks(
    GedcomData data,
    Map<String, String> idMap,
    String? treeId,
  ) async {
    // Находим семьи, где есть дети
    final familiesWithChildren = data.families
        .where((f) => f.childrenIds.isNotEmpty)
        .toList();

    // Собираем всех детей из семей
    final allChildrenIds = <String>{};
    for (final family in familiesWithChildren) {
      allChildrenIds.addAll(family.childrenIds);
    }

    // Находим людей, у которых есть братья/сестры, но нет семьи родителей
    final peopleWithoutParents = <String>[];
    for (final individual in data.individuals) {
      // Проверяем, есть ли у этого человека семья, где он ребенок
      final hasParentFamily = data.families.any(
        (f) => f.childrenIds.contains(individual.id),
      );

      // Если человек не является ребенком ни в одной семье
      // и у него есть братья/сестры (определяем по фамилии)
      if (!hasParentFamily) {
        // Ищем людей с такой же фамилией (предполагаем, что это братья/сестры)
        final surname = _extractSurname(individual.name);
        if (surname.isNotEmpty) {
          final siblings = data.individuals
              .where(
                (i) =>
                    i.id != individual.id &&
                    _extractSurname(i.name) == surname &&
                    !data.families.any((f) => f.childrenIds.contains(i.id)),
              )
              .map((i) => i.id)
              .toList();

          if (siblings.isNotEmpty) {
            // Создаем виртуальную родительскую семью
            final parentFamily = Family(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              treeId: treeId ?? 'default',
              husbandId: null,
              wifeId: null,
              childrenIds: [
                individual.id,
                ...siblings,
              ].map((id) => idMap[id]).whereType<String>().toList(),
              marriageDate: null,
              divorceDate: null,
              marriagePlace: null,
              notes:
                  'Виртуальная семья для братьев/сестер (создана автоматически)',
            );

            if (parentFamily.childrenIds.isNotEmpty) {
              await familyRepository.addFamily(parentFamily);
            }
          }
        }
      }
    }
  }

  String _extractSurname(String fullName) {
    // Извлекаем фамилию из формата "Имя /Фамилия/"
    final match = RegExp(r'/([^/]+)/').firstMatch(fullName);
    if (match != null && match.groupCount >= 1) {
      return match.group(1)?.trim() ?? '';
    }
    return '';
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
