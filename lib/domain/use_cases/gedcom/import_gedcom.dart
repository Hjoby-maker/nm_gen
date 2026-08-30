import 'package:dartz/dartz.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/core/utils/gedcom_parser.dart';
import 'package:nm_gen/domain/entities/family.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/repositories/family_repository.dart';
import 'package:nm_gen/domain/repositories/person_repository.dart';
import 'package:nm_gen/domain/use_cases/person/sync_person_events.dart';

/// Use Case: Импорт данных из GEDCOM файла
class ImportGedcomUseCase {
  ImportGedcomUseCase({
    required this.personRepository,
    required this.familyRepository,
    required this.syncPersonEventsUseCase,
  });
  final PersonRepository personRepository;
  final FamilyRepository familyRepository;

  /// Та же синхронизация "человек -> событие", что уже используется в
  /// AddPersonUseCase/UpdatePersonUseCase: если у человека указана дата
  /// рождения/смерти, автоматически создаётся соответствующее событие.
  /// Импорт раньше писал людей напрямую через personRepository.addPerson,
  /// минуя AddPersonUseCase - поэтому при импорте эта синхронизация не
  /// срабатывала вообще, в отличие от ручного добавления человека.
  final SyncPersonEventsUseCase syncPersonEventsUseCase;

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
        // Пропускаем людей без имени
        if (individual.name.isEmpty) continue;

        final Person person = GedcomParser.toPerson(individual);

        // Добавляем treeId к человеку
        final Person personWithTree = person.copyWith(
          treeId: treeId ?? 'default',
        );

        try {
          final Person savedPerson = await personRepository.addPerson(
            personWithTree,
          );
          idMap[individual.id] = savedPerson.id;
          importedCount++;

          // Автосоздание событий "Рождение"/"Смерть" из birthDate/deathDate
          // - то же самое, что происходит при ручном добавлении человека
          // через AddPersonUseCase. execute() возвращает Either и сама
          // ловит исключения внутри (не бросает) - обрабатываем через
          // fold, а не try/catch. Ошибка синхронизации не должна ронять
          // весь импорт - человек уже сохранён, событие можно досоздать
          // позже вручную.
          final syncResult = await syncPersonEventsUseCase.execute(
            savedPerson,
          );
          syncResult.fold(
            (failure) => print(
              '⚠️ Не удалось создать авто-события для ${individual.id}: '
              '${failure.message}',
            ),
            (_) {},
          );

          // Логируем для отладки
          print(
            '✅ Импортирован: ${person.firstName} ${person.lastName}, '
            'дата рождения: ${person.birthDate?.toIso8601String() ?? "нет"}',
          );
        } catch (e) {
          print('⚠️ Ошибка импорта человека ${individual.id}: $e');
        }
      }

      print('📊 Импортировано людей: $importedCount');

      // Импортируем семьи
      int familyCount = 0;
      for (final GedcomFamily gedcomFamily in data.families) {
        final String husbandNewId = idMap[gedcomFamily.husbandId] ?? '';
        final String wifeNewId = idMap[gedcomFamily.wifeId] ?? '';

        final List<String> childrenNewIds = gedcomFamily.childrenIds
            .map((String id) => idMap[id] ?? '')
            .where((String id) => id.isNotEmpty)
            .toList();

        // Пропускаем семью только если в ней действительно некого
        // связывать: нет ни родителей, ни детей.
        //
        // ⚠️ РАНЬШЕ здесь проверялось только "есть хотя бы один родитель",
        // и это отбрасывало псевдо-семьи (husbandId == null && wifeId ==
        // null, childrenIds - участники группы братьев/сестёр без
        // известных родителей). Именно такие семьи GetFullTreeUseCase
        // использует, чтобы связать несколько независимых деревьев в один
        // кластер (TreeNode.isSiblingGroup) - но раньше они целиком
        // отсеивались уже на этапе импорта, до того как до этой логики
        // вообще доходило дело, поэтому дерево из отдельных родов
        // распадалось на несколько несвязанных.
        if (husbandNewId.isEmpty && wifeNewId.isEmpty && childrenNewIds.isEmpty) {
          print(
            '⚠️ Пропускаем семью ${gedcomFamily.id}: нет ни родителей, ни детей',
          );
          continue;
        }

        final Family family = Family(
          id:
              DateTime.now().millisecondsSinceEpoch.toString() +
              '_${familyCount++}',
          treeId: treeId ?? 'default',
          husbandId: husbandNewId.isNotEmpty ? husbandNewId : null,
          wifeId: wifeNewId.isNotEmpty ? wifeNewId : null,
          childrenIds: childrenNewIds,
          marriageDate: gedcomFamily.marriageDate != null
              ? _parseDate(gedcomFamily.marriageDate!)
              : null,
          divorceDate: gedcomFamily.divorceDate != null
              ? _parseDate(gedcomFamily.divorceDate!)
              : null,
        );

        try {
          await familyRepository.addFamily(family);
          print(
            '✅ Импортирована семья: муж=${family.husbandId}, жена=${family.wifeId}, детей=${family.childrenIds.length}',
          );
        } catch (e) {
          print('⚠️ Ошибка импорта семьи ${gedcomFamily.id}: $e');
        }
      }

      return Right(importedCount);
    } catch (e, stackTrace) {
      print('❌ Критическая ошибка импорта: $e');
      print('❌ StackTrace: $stackTrace');
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

    // Убираем префиксы
    String cleanDate = date;
    final List<String> prefixes = ['ABT ', 'BEF ', 'AFT ', 'CAL ', 'EST '];
    for (final prefix in prefixes) {
      if (date.startsWith(prefix)) {
        cleanDate = date.substring(prefix.length);
        break;
      }
    }

    final List<String> parts = cleanDate.split(' ');
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