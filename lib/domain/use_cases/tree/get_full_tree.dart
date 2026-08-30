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
  final PersonRepository personRepository;
  final FamilyRepository familyRepository;

  GetFullTreeUseCase({
    required this.personRepository,
    required this.familyRepository,
  });

  Future<Either<Failure, TreeNode>> execute({
    required String treeId,
    String? selectedPersonId,
  }) async {
    try {
      final allPersons = await personRepository.getAllPersons(treeId: treeId);
      final allFamilies = await familyRepository.getAllFamilies(treeId: treeId);

      if (allPersons.isEmpty) {
        //return Left(NotFoundFailure('В проекте нет людей для отображения'));

        final emptyRoot = TreeNode(
          person: Person(
            id: 'virtual_root',
            treeId: treeId,
            firstName: 'Все люди',
            lastName: '',
            gender: Gender.unknown,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          children: const [],
          spouses: const [],
          isRoot: true,
          isCenter: false,
        );
        return Right(emptyRoot);
      }

      final personMap = {for (final p in allPersons) p.id: p};

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

        // ✅ ФИКС: в базе встречаются "семьи" без единого родителя
        // (husbandId == null И wifeId == null), которые на деле - не
        // отношение "родитель → ребёнок", а группировка братьев/сестёр
        // (childrenIds там - это НЕ дети общего родителя, а участники
        // группы). Такая псевдо-семья никогда не попадёт в
        // familiesAsParentMap (родителя нет), а значит по ней невозможно
        // никого построить рекурсивно как ребёнка. Если её не
        // отфильтровать здесь, familiesAsChildMap ошибочно решит, что у
        // человека ЕСТЬ родитель, он перестанет считаться корнем, но и
        // ребёнком ни под кем реальным не станет - "потеряется" и попадёт
        // в аварийный fallback (см. п.6 ниже) в непредсказуемом порядке.
        // Именно это вызывало появление "двух Викторов".
        final bool hasRealParent =
            family.husbandId != null || family.wifeId != null;
        if (!hasRealParent) continue;

        for (final childId in family.childrenIds) {
          familiesAsChildMap.putIfAbsent(childId, () => []).add(family);
        }
      }

      final Set<String> renderedIds = {};

      TreeNode buildPersonNode(Person person, Set<String> visiting) {
        if (visiting.contains(person.id)) {
          return TreeNode(
            person: person,
            children: const [],
            spouses: const [],
            isRoot: false,
            isCenter: person.id == selectedPersonId,
            isDuplicateReference: true,
          );
        }

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
                  // Дата развода хранится на конкретной Family, а не на
                  // человеке - `family` здесь как раз та семья, из которой
                  // взят этот супруг, поэтому её divorceDate и определяет
                  // статус именно этого брака.
                  isDivorced: family.divorceDate != null,
                ),
              );
            }
          }
        }

        final List<TreeNode> children = [];
        final Set<String> childIds = {};
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

      final rootPersons = allPersons
          .where((p) => (familiesAsChildMap[p.id] ?? const []).isEmpty)
          .toList();

      final List<TreeNode> rootNodes = [];
      for (final person in rootPersons) {
        if (renderedIds.contains(person.id)) continue;
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

      // ============================================================
      // ГРУППИРОВКА БРАТЬЕВ/СЁСТЕР БЕЗ ИЗВЕСТНЫХ РОДИТЕЛЕЙ
      // ============================================================
      // До этого момента rootNodes - это независимые корневые деревья, и
      // если два "корня" на самом деле родные братья/сёстры, но их общий
      // родитель неизвестен, они попадали в rootNodes как два никак не
      // связанных дерева. Такая связь в данных кодируется отдельно -
      // Family с husbandId == null && wifeId == null, где childrenIds - не
      // дети общего родителя, а сами участники группы братьев/сестёр (это
      // та самая "псевдо-семья" из фикса "двух Викторов" выше: она НЕ
      // используется для familiesAsChildMap/поиска родителя, чтобы не
      // повторить тот баг, а обрабатывается отдельно здесь).
      //
      // Здесь мы НЕ трогаем уже построенные rootNodes (buildPersonNode
      // выше отработал ровно как раньше - корректность и защита от "двух
      // Викторов" сохранены), а только группируем ГОТОВЫЕ корни в кластеры
      // через Union-Find по этим псевдо-семьям, и оборачиваем каждую
      // группу из 2+ корней в синтетический узел isSiblingGroup - у него
      // нет своего Person для отображения, TreeVisualizer рисует его
      // children рядом друг с другом с горизонтальной линией родства
      // вместо визуального разрыва на несколько деревьев.
      final Map<String, int> rootIndexByPersonId = {};
      for (int i = 0; i < rootNodes.length; i++) {
        rootIndexByPersonId[rootNodes[i].person.id] = i;
        for (final spouse in rootNodes[i].spouses) {
          rootIndexByPersonId.putIfAbsent(spouse.person.id, () => i);
        }
      }

      final List<int> clusterParent = List<int>.generate(
        rootNodes.length,
        (i) => i,
      );
      int findCluster(int i) {
        while (clusterParent[i] != i) {
          clusterParent[i] = clusterParent[clusterParent[i]];
          i = clusterParent[i];
        }
        return i;
      }

      void unionClusters(int a, int b) {
        final int rootA = findCluster(a);
        final int rootB = findCluster(b);
        if (rootA != rootB) clusterParent[rootA] = rootB;
      }

      for (final family in allFamilies) {
        final bool isSiblingPseudoFamily =
            family.husbandId == null && family.wifeId == null;
        if (!isSiblingPseudoFamily) continue;

        final List<int> memberRootIndices = family.childrenIds
            .map((id) => rootIndexByPersonId[id])
            .whereType<int>()
            .toSet()
            .toList();

        for (int k = 1; k < memberRootIndices.length; k++) {
          unionClusters(memberRootIndices[0], memberRootIndices[k]);
        }
      }

      final Map<int, List<TreeNode>> clusters = {};
      for (int i = 0; i < rootNodes.length; i++) {
        clusters.putIfAbsent(findCluster(i), () => []).add(rootNodes[i]);
      }

      final List<TreeNode> groupedRootNodes = [];
      for (final cluster in clusters.values) {
        if (cluster.length == 1) {
          groupedRootNodes.add(cluster.first);
          continue;
        }
        groupedRootNodes.add(
          TreeNode(
            person: Person(
              id:
                  'sibling_group_${cluster.map((n) => n.person.id).join('_')}',
              treeId: treeId,
              firstName: 'Братья и сёстры',
              lastName: '',
              gender: Gender.unknown,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            children: cluster,
            spouses: const [],
            isRoot: true,
            isCenter: false,
            isSiblingGroup: true,
          ),
        );
      }

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
        children: groupedRootNodes,
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