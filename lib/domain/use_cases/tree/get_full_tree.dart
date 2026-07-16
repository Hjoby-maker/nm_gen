import 'package:dartz/dartz.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/entities/family.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/entities/tree_node.dart';
import 'package:nm_gen/domain/repositories/family_repository.dart';
import 'package:nm_gen/domain/repositories/person_repository.dart';
import 'package:nm_gen/core/enums/gender.dart';

/// Use Case: Получение полного генеалогического древа для проекта
class GetFullTreeUseCase {
  GetFullTreeUseCase({
    required this.personRepository,
    required this.familyRepository,
  });
  final PersonRepository personRepository;
  final FamilyRepository familyRepository;

  /// Получить полное дерево со всеми людьми проекта.
  ///
  /// В отличие от предыдущей версии, здесь строится НАСТОЯЩЕЕ дерево:
  /// - каждый человек встречается в структуре ровно один раз;
  /// - дети раскрываются рекурсивно на любую глубину (внуки, правнуки и т.д.);
  /// - "корнями" леса становятся только люди без известных родителей,
  ///   остальные попадают в дерево через своих родителей/супругов.
  Future<Either<Failure, TreeNode>> execute({
    required String treeId,
    String? selectedPersonId,
  }) async {
    try {
      // 1. Получаем все данные
      final allPersons = await personRepository.getAllPersons(treeId: treeId);
      final allFamilies = await familyRepository.getAllFamilies(treeId: treeId);

      // 👇👇👇 ВСТАВЬТЕ СЮДА ВЕСЬ КОД ИЗ _diagnostic_snippet.dart 👇👇👇
      print('--- ДИАГНОСТИКА: allPersons.length = ${allPersons.length} ---');
      final Map<String, int> idCounts = <String, int>{};
      for (final p in allPersons) {
        idCounts[p.id] = (idCounts[p.id] ?? 0) + 1;
      }
      idCounts.forEach((String id, int count) {
        if (count > 1) {
          print('⚠️ ДУБЛЬ PERSON.ID: $id встречается $count раз(а)');
        }
      });

      print('--- ДИАГНОСТИКА: allFamilies (${allFamilies.length}) ---');
      final personIds = allPersons.map((p) => p.id).toSet();
      for (final f in allFamilies) {
        print(
          'family husband=${f.husbandId} wife=${f.wifeId} children=${f.childrenIds}',
        );
        for (final childId in f.childrenIds) {
          if (!personIds.contains(childId)) {
            print(
              '⚠️ childId "$childId" из family НЕ совпадает ни с одним Person.id! '
              'Похоже на несовпадение GEDCOM-xref и сгенерированного id.',
            );
          }
        }
      }
      // 👆👆👆 КОНЕЦ ВСТАВЛЯЕМОГО БЛОКА 👆👆👆

      if (allPersons.isEmpty) {
        return Left(NotFoundFailure('В проекте нет людей для отображения'));
      }

      // 2. Карта для быстрого доступа к человеку по id
      final personMap = {for (final p in allPersons) p.id: p};

      // 3. Индексы: в каких семьях человек - родитель / ребёнок.
      //    Строим один раз за O(families), а не пере-фильтровываем
      //    allFamilies для каждого человека (это было узким местом
      //    и косвенно провоцировало плоскую структуру).
      final Map<String, List<Family>> familiesAsParentMap = {};
      final Map<String, List<Family>> familiesAsChildMap = {};

      for (final family in allFamilies) {
        if (family.husbandId != null) {
          familiesAsParentMap
              .putIfAbsent(family.husbandId!, () => [])
              .add(family);
        }
        if (family.wifeId != null) {
          familiesAsParentMap.putIfAbsent(family.wifeId!, () => []).add(family);
        }
        for (final childId in family.childrenIds) {
          familiesAsChildMap.putIfAbsent(childId, () => []).add(family);
        }
      }

      // 4. Множество людей, уже включённых в дерево хоть где-то
      //    (как родитель, супруг или ребёнок) - чтобы никого не задваивать.
      final Set<String> renderedIds = <String>{};

      /// Рекурсивно строит узел человека вместе со всеми его супругами
      /// и рекурсивно раскрытыми детьми от всех браков.
      /// [visiting] - защита от зацикливания, если в данных случайно
      /// образовалась циклическая ссылка (человек - сам себе предок).
      TreeNode buildPersonNode(Person person, Set<String> visiting) {
        if (visiting.contains(person.id)) {
          // Обнаружен цикл в данных - обрываем рекурсию,
          // чтобы не получить StackOverflow / бесконечный виджет-дерево.
          return TreeNode(
            person: person,
            children: const [],
            spouses: const [],
            isRoot: false,
            isCenter: person.id == selectedPersonId,
            isDuplicateReference: true,
          );
        }

        // ✅ КЛЮЧЕВОЙ ФИКС ДУБЛЕЙ: генеалогическое дерево - это граф, а не
        // строгое дерево (у ребёнка два родителя, и обе родительские линии
        // могут вести к одному и тому же человеку). Раньше renderedIds
        // проверялся только на уровне корней леса, поэтому один и тот же
        // человек мог быть полностью развёрнут (со всеми своими детьми и
        // внуками) дважды: один раз как чей-то ребёнок, второй раз - как
        // супруг в семье, до которой добрались из другой родительской линии.
        // Если человек уже где-то полностью отрисован - не строим его
        // поддерево ещё раз, а возвращаем "ссылочную" карточку без детей.
        if (renderedIds.contains(person.id)) {
          return TreeNode(
            person: person,
            children: const [],
            spouses: const [],
            isRoot: false,
            isCenter: person.id == selectedPersonId,
            isDuplicateReference: true,
          );
        }

        final nextVisiting = {...visiting, person.id};
        renderedIds.add(person.id);

        final parentFamilies = familiesAsParentMap[person.id] ?? const [];

        // --- Супруги (без рекурсии вглубь их предков - они показываются
        // рядом с человеком, а не как отдельная ветка) ---
        final List<TreeNode> spouses = [];
        final Set<String> spouseIds = {};
        for (final family in parentFamilies) {
          final spouseId = family.husbandId == person.id
              ? family.wifeId
              : family.husbandId;
          if (spouseId != null &&
              spouseId != person.id &&
              spouseIds.add(spouseId)) {
            final spousePerson = personMap[spouseId];
            if (spousePerson != null) {
              renderedIds.add(spouseId);
              spouses.add(
                TreeNode(
                  person: spousePerson,
                  children: const [],
                  spouses: const [],
                  isRoot: false,
                  isCenter: spouseId == selectedPersonId,
                ),
              );
            }
          }
        }

        // --- Дети от ВСЕХ браков этого человека, рекурсивно ---
        final List<TreeNode> children = [];
        final Set<String> childIds = <String>{};
        for (final family in parentFamilies) {
          for (final childId in family.childrenIds) {
            if (childIds.add(childId)) {
              final childPerson = personMap[childId];
              if (childPerson != null) {
                children.add(buildPersonNode(childPerson, nextVisiting));
              }
            }
          }
        }

        return TreeNode(
          person: person,
          children: children,
          spouses: spouses,
          isRoot: false,
          isCenter: person.id == selectedPersonId,
        );
      }

      // 5. "Корни" леса - люди, у которых нет известных родителей.
      final rootPersons = allPersons
          .where((p) => (familiesAsChildMap[p.id] ?? const []).isEmpty)
          .toList();

      final List<TreeNode> rootNodes = [];
      for (final person in rootPersons) {
        if (renderedIds.contains(person.id)) {
          // Уже отрисован как супруг другого корня - не дублируем карточку.
          continue;
        }
        final node = buildPersonNode(person, <String>{});
        rootNodes.add(
          TreeNode(
            person: node.person,
            children: node.children,
            spouses: node.spouses,
            isRoot: true,
            isCenter: node.isCenter,
          ),
        );
      }

      // 6. Подстраховка: если из-за неполных данных о семье кто-то
      //    так и не попал в дерево (например, семья ссылается на
      //    несуществующего родителя) - показываем его отдельным корнем,
      //    а не теряем молча.
      for (final person in allPersons) {
        if (!renderedIds.contains(person.id)) {
          final node = buildPersonNode(person, <String>{});
          rootNodes.add(
            TreeNode(
              person: node.person,
              children: node.children,
              spouses: node.spouses,
              isRoot: true,
              isCenter: node.isCenter,
            ),
          );
        }
      }

      // 7. Виртуальный корень "Все люди" - контейнер для леса генеалогических
      //    линий. Сам по себе он не является реальным человеком и не должен
      //    отображаться как карточка (см. правку в TreeVisualizer).
      final virtualRoot = TreeNode(
        person: Person(
          id: 'virtual_root',
          treeId: treeId,
          firstName: 'Все люди',
          lastName: '',
          gender: Gender.unknown,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        children: rootNodes,
        spouses: const [],
        isRoot: true,
        isCenter: false,
      );

      return Right(virtualRoot);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
