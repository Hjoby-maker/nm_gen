// test/unit/models/tree_node_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nm_gen/core/enums/gender.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/entities/tree_node.dart';

void main() {
  group('TreeNode сущность', () {
    late Person testPerson;
    late Person childPerson;
    late Person spousePerson;

    setUp(() {
      testPerson = Person(
        id: 'p1',
        treeId: 'tree_1',
        firstName: 'Иван',
        lastName: 'Иванов',
        gender: Gender.male,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      childPerson = Person(
        id: 'p2',
        treeId: 'tree_1',
        firstName: 'Петр',
        lastName: 'Иванов',
        gender: Gender.male,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      spousePerson = Person(
        id: 'p3',
        treeId: 'tree_1',
        firstName: 'Мария',
        lastName: 'Иванова',
        gender: Gender.female,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    // ============================================================
    // 1. ТЕСТЫ КОНСТРУКТОРА
    // ============================================================

    group('Создание TreeNode', () {
      test('создает TreeNode с минимальными данными', () {
        // Act
        final node = TreeNode(person: testPerson);

        // Assert
        expect(node.person, testPerson);
        expect(node.children, isEmpty);
        expect(node.spouses, isEmpty);
        expect(node.isRoot, false);
        expect(node.isCenter, false);
        expect(node.generation, 0);
        expect(node.isDuplicateReference, false);
        expect(node.isLeaf, true);
      });

      test('создает TreeNode со всеми параметрами', () {
        // Arrange
        final childNode = TreeNode(person: childPerson);
        final spouseNode = TreeNode(person: spousePerson);

        // Act
        final node = TreeNode(
          person: testPerson,
          children: [childNode],
          spouses: [spouseNode],
          isRoot: true,
          isCenter: true,
          generation: 1,
          isDuplicateReference: true,
        );

        // Assert
        expect(node.person, testPerson);
        expect(node.children, [childNode]);
        expect(node.spouses, [spouseNode]);
        expect(node.isRoot, true);
        expect(node.isCenter, true);
        expect(node.generation, 1);
        expect(node.isDuplicateReference, true);
        expect(node.isLeaf, false);
      });
    });

    // ============================================================
    // 2. ТЕСТЫ ГЕТТЕРОВ
    // ============================================================

    group('Геттеры TreeNode', () {
      test('isLeaf возвращает true если нет детей', () {
        // Arrange
        final node = TreeNode(person: testPerson);

        // Assert
        expect(node.isLeaf, true);
      });

      test('isLeaf возвращает false если есть дети', () {
        // Arrange
        final node = TreeNode(
          person: testPerson,
          children: [TreeNode(person: childPerson)],
        );

        // Assert
        expect(node.isLeaf, false);
      });

      test('descendantsCount возвращает количество потомков', () {
        // Arrange
        final grandChild = TreeNode(person: childPerson);
        final child = TreeNode(person: childPerson, children: [grandChild]);
        final node = TreeNode(person: testPerson, children: [child]);

        // Assert
        expect(node.descendantsCount, 2); // child + grandchild
      });

      test('descendantsCount возвращает 0 если нет детей', () {
        // Arrange
        final node = TreeNode(person: testPerson);

        // Assert
        expect(node.descendantsCount, 0);
      });

      test('treeId возвращает treeId из Person', () {
        // Arrange
        final node = TreeNode(person: testPerson);

        // Assert
        expect(node.treeId, 'tree_1');
      });
    });

    // ============================================================
    // 3. ТЕСТЫ COPYWITH
    // ============================================================

    group('copyWith', () {
      test('копирует TreeNode с изменением полей', () {
        // Arrange
        final node = TreeNode(person: testPerson);
        final newPerson = Person(
          id: 'p4',
          treeId: 'tree_1',
          firstName: 'Алексей',
          lastName: 'Петров',
          gender: Gender.male,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final childNode = TreeNode(person: childPerson);
        final spouseNode = TreeNode(person: spousePerson);

        // Act
        final updated = node.copyWith(
          person: newPerson,
          children: [childNode],
          spouses: [spouseNode],
          isRoot: true,
          isCenter: true,
          generation: 2,
          isDuplicateReference: true,
        );

        // Assert
        expect(updated.person, newPerson);
        expect(updated.children, [childNode]);
        expect(updated.spouses, [spouseNode]);
        expect(updated.isRoot, true);
        expect(updated.isCenter, true);
        expect(updated.generation, 2);
        expect(updated.isDuplicateReference, true);
      });

      test('copyWith сохраняет неизмененные поля', () {
        // Arrange
        final node = TreeNode(
          person: testPerson,
          children: [TreeNode(person: childPerson)],
          spouses: [TreeNode(person: spousePerson)],
          isRoot: true,
          isCenter: true,
          generation: 1,
        );

        // Act
        final updated = node.copyWith(person: childPerson);

        // Assert
        expect(updated.children, node.children);
        expect(updated.spouses, node.spouses);
        expect(updated.isRoot, node.isRoot);
        expect(updated.isCenter, node.isCenter);
        expect(updated.generation, node.generation);
      });
    });

    // ============================================================
    // 4. ТЕСТЫ EQUATABLE
    // ============================================================

    group('Equatable', () {
      test('два одинаковых TreeNode равны', () {
        // Arrange
        final node1 = TreeNode(
          person: testPerson,
          children: [TreeNode(person: childPerson)],
          isRoot: true,
        );
        final node2 = TreeNode(
          person: testPerson,
          children: [TreeNode(person: childPerson)],
          isRoot: true,
        );

        // Assert
        expect(node1 == node2, true);
        expect(node1.hashCode, node2.hashCode);
      });

      test('два разных TreeNode не равны', () {
        // Arrange
        final node1 = TreeNode(
          person: testPerson,
          children: [TreeNode(person: childPerson)],
        );
        final node2 = TreeNode(
          person: testPerson,
          children: [TreeNode(person: spousePerson)],
        );

        // Assert
        expect(node1 == node2, false);
        expect(node1.hashCode, isNot(node2.hashCode));
      });

      test('TreeNode сравнивается по всем полям из props', () {
        // Arrange
        final node = TreeNode(person: testPerson);

        // Assert
        expect(node.props.length, 7);
      });
    });
  });
}
