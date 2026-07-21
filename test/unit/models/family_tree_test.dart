// test/unit/models/family_tree_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nm_gen/core/enums/gender.dart';
import 'package:nm_gen/domain/entities/family.dart';
import 'package:nm_gen/domain/entities/family_tree.dart';
import 'package:nm_gen/domain/entities/person.dart';

void main() {
  group('FamilyTree сущность', () {
    late Person parent1;
    late Person parent2;
    late Person child1;
    late Person child2;
    late Family family;
    late FamilyTree familyTree;

    setUp(() {
      final now = DateTime.now();

      parent1 = Person(
        id: 'p1',
        treeId: 'tree_1',
        firstName: 'Иван',
        lastName: 'Иванов',
        gender: Gender.male,
        createdAt: now,
        updatedAt: now,
      );

      parent2 = Person(
        id: 'p2',
        treeId: 'tree_1',
        firstName: 'Мария',
        lastName: 'Иванова',
        gender: Gender.female,
        createdAt: now,
        updatedAt: now,
      );

      child1 = Person(
        id: 'p3',
        treeId: 'tree_1',
        firstName: 'Петр',
        lastName: 'Иванов',
        gender: Gender.male,
        createdAt: now,
        updatedAt: now,
      );

      child2 = Person(
        id: 'p4',
        treeId: 'tree_1',
        firstName: 'Анна',
        lastName: 'Иванова',
        gender: Gender.female,
        createdAt: now,
        updatedAt: now,
      );

      family = Family(
        id: 'f1',
        treeId: 'tree_1',
        husbandId: parent1.id,
        wifeId: parent2.id,
        childrenIds: [child1.id, child2.id],
        marriageDate: DateTime(2000, 1, 1),
        marriagePlace: 'Москва',
      );

      familyTree = FamilyTree(
        treeId: 'tree_1',
        name: 'Древо Ивановых',
        rootPerson: parent1,
        allPersons: [parent1, parent2, child1, child2],
        families: [family],
      );
    });

    // ============================================================
    // 1. ТЕСТЫ КОНСТРУКТОРА
    // ============================================================

    test('создает FamilyTree с корректными данными', () {
      // Assert
      expect(familyTree.treeId, 'tree_1');
      expect(familyTree.name, 'Древо Ивановых');
      expect(familyTree.rootPerson, parent1);
      expect(familyTree.allPersons.length, 4);
      expect(familyTree.families.length, 1);
    });

    // ============================================================
    // 2. ТЕСТЫ МЕТОДОВ
    // ============================================================

    group('Методы FamilyTree', () {
      test('findPerson возвращает человека по ID', () {
        // Act
        final found = familyTree.findPerson(parent1.id);

        // Assert
        expect(found, isNotNull);
        expect(found!.id, parent1.id);
        expect(found.firstName, parent1.firstName);
      });

      test('findPerson возвращает null если человек не найден', () {
        // Act
        final found = familyTree.findPerson('nonexistent');

        // Assert
        expect(found, null);
      });

      test('findFamily возвращает семью по ID', () {
        // Act
        final found = familyTree.findFamily(family.id);

        // Assert
        expect(found, isNotNull);
        expect(found!.id, family.id);
        expect(found.husbandId, family.husbandId);
      });

      test('findFamily возвращает null если семья не найдена', () {
        // Act
        final found = familyTree.findFamily('nonexistent');

        // Assert
        expect(found, null);
      });

      test('getChildren возвращает детей человека', () {
        // Act
        final children = familyTree.getChildren(parent1.id);

        // Assert
        expect(children.length, 2);
        expect(children[0].id, child1.id);
        expect(children[1].id, child2.id);
      });

      test(
        'getChildren возвращает пустой список если у человека нет детей',
        () {
          // Act
          final children = familyTree.getChildren(child1.id);

          // Assert
          expect(children, isEmpty);
        },
      );

      test('getParents возвращает родителей человека', () {
        // Act
        final parents = familyTree.getParents(child1.id);

        // Assert
        expect(parents.length, 2);
        expect(parents[0].id, parent1.id);
        expect(parents[1].id, parent2.id);
      });

      test(
        'getParents возвращает пустой список если у человека нет родителей',
        () {
          // Act
          final parents = familyTree.getParents(parent1.id);

          // Assert
          expect(parents, isEmpty);
        },
      );

      test('getSpouses возвращает супругов человека', () {
        // Act
        final spouses = familyTree.getSpouses(parent1.id);

        // Assert
        expect(spouses.length, 1);
        expect(spouses[0].id, parent2.id);
      });

      test(
        'getSpouses возвращает пустой список если у человека нет супругов',
        () {
          // Act
          final spouses = familyTree.getSpouses(child1.id);

          // Assert
          expect(spouses, isEmpty);
        },
      );

      test('getFamiliesForPerson возвращает все семьи с участием человека', () {
        // Act
        final families = familyTree.getFamiliesForPerson(parent1.id);

        // Assert
        expect(families.length, 1);
        expect(families[0].id, family.id);
      });

      test(
        'getFamiliesForPerson возвращает пустой список если человек не участвует в семьях',
        () {
          // Act
          final families = familyTree.getFamiliesForPerson('nonexistent');

          // Assert
          expect(families, isEmpty);
        },
      );

      test('personCount возвращает количество людей', () {
        // Assert
        expect(familyTree.personCount, 4);
      });

      test('familyCount возвращает количество семей', () {
        // Assert
        expect(familyTree.familyCount, 1);
      });
    });

    // ============================================================
    // 3. ТЕСТЫ EQUATABLE
    // ============================================================

    group('Equatable', () {
      test('два одинаковых FamilyTree равны', () {
        // Arrange
        final tree1 = FamilyTree(
          treeId: 'tree_1',
          name: 'Древо',
          rootPerson: parent1,
          allPersons: [parent1, parent2, child1, child2],
          families: [family],
        );
        final tree2 = FamilyTree(
          treeId: 'tree_1',
          name: 'Древо',
          rootPerson: parent1,
          allPersons: [parent1, parent2, child1, child2],
          families: [family],
        );

        // Assert
        expect(tree1 == tree2, true);
        expect(tree1.hashCode, tree2.hashCode);
      });

      test('два разных FamilyTree не равны', () {
        // Arrange
        final tree1 = FamilyTree(
          treeId: 'tree_1',
          name: 'Древо 1',
          rootPerson: parent1,
          allPersons: [parent1, parent2, child1, child2],
          families: [family],
        );
        final tree2 = FamilyTree(
          treeId: 'tree_2',
          name: 'Древо 2',
          rootPerson: parent1,
          allPersons: [parent1, parent2, child1, child2],
          families: [family],
        );

        // Assert
        expect(tree1 == tree2, false);
        expect(tree1.hashCode, isNot(tree2.hashCode));
      });
    });
  });
}
