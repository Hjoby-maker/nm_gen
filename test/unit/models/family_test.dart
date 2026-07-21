// test/unit/models/family_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nm_gen/domain/entities/family.dart';

void main() {
  group('Family сущность', () {
    // ============================================================
    // 1. ТЕСТЫ КОНСТРУКТОРА
    // ============================================================

    group('Создание Family', () {
      test('создает Family с корректными данными через конструктор', () {
        // Arrange
        const id = 'family_1';
        const treeId = 'tree_1';
        const husbandId = 'person_1';
        const wifeId = 'person_2';
        const childrenIds = ['child_1', 'child_2'];
        final marriageDate = DateTime(2000, 6, 15);
        final divorceDate = DateTime(2010, 6, 15);
        const marriagePlace = 'Москва';
        const notes = 'Тестовая семья';

        // Act
        final family = Family(
          id: id,
          treeId: treeId,
          husbandId: husbandId,
          wifeId: wifeId,
          childrenIds: childrenIds,
          marriageDate: marriageDate,
          divorceDate: divorceDate,
          marriagePlace: marriagePlace,
          notes: notes,
        );

        // Assert
        expect(family.id, id);
        expect(family.treeId, treeId);
        expect(family.husbandId, husbandId);
        expect(family.wifeId, wifeId);
        expect(family.childrenIds, childrenIds);
        expect(family.marriageDate, marriageDate);
        expect(family.divorceDate, divorceDate);
        expect(family.marriagePlace, marriagePlace);
        expect(family.notes, notes);
      });

      test('создает семью с опциональными полями', () {
        // Act
        final family = Family(
          id: 'family_1',
          treeId: 'tree_1',
          husbandId: 'person_1',
          wifeId: null,
          childrenIds: [],
          marriageDate: null,
          divorceDate: null,
          marriagePlace: null,
          notes: null,
        );

        // Assert
        expect(family.id, 'family_1');
        expect(family.treeId, 'tree_1');
        expect(family.husbandId, 'person_1');
        expect(family.wifeId, null);
        expect(family.childrenIds, isEmpty);
        expect(family.marriageDate, null);
        expect(family.divorceDate, null);
        expect(family.marriagePlace, null);
        expect(family.notes, null);
      });

      test('Family.empty создает пустую семью', () {
        // Act
        final family = Family.empty();

        // Assert
        expect(family.id, '');
        expect(family.treeId, '');
        expect(family.husbandId, null);
        expect(family.wifeId, null);
        expect(family.childrenIds, isEmpty);
        expect(family.marriageDate, null);
        expect(family.divorceDate, null);
        expect(family.marriagePlace, null);
        expect(family.notes, null);
      });
    });

    // ============================================================
    // 2. ТЕСТЫ ГЕТТЕРОВ
    // ============================================================

    group('Геттеры Family', () {
      group('isActive', () {
        test('возвращает true если есть дата брака и нет даты развода', () {
          // Arrange
          final family = Family(
            id: 'f1',
            treeId: 't1',
            husbandId: 'p1',
            wifeId: 'p2',
            marriageDate: DateTime(2000, 1, 1),
            divorceDate: null,
          );

          // Assert
          expect(family.isActive, true);
        });

        test('возвращает false если нет даты брака', () {
          // Arrange
          final family = Family(
            id: 'f1',
            treeId: 't1',
            husbandId: 'p1',
            wifeId: 'p2',
            marriageDate: null,
            divorceDate: null,
          );

          // Assert
          expect(family.isActive, false);
        });

        test('возвращает false если есть дата развода', () {
          // Arrange
          final family = Family(
            id: 'f1',
            treeId: 't1',
            husbandId: 'p1',
            wifeId: 'p2',
            marriageDate: DateTime(2000, 1, 1),
            divorceDate: DateTime(2010, 1, 1),
          );

          // Assert
          expect(family.isActive, false);
        });
      });

      group('hasChildren', () {
        test('возвращает true если есть дети', () {
          // Arrange
          final family = Family(
            id: 'f1',
            treeId: 't1',
            childrenIds: ['child1', 'child2'],
          );

          // Assert
          expect(family.hasChildren, true);
        });

        test('возвращает false если нет детей', () {
          // Arrange
          final family = Family(id: 'f1', treeId: 't1', childrenIds: []);

          // Assert
          expect(family.hasChildren, false);
        });
      });

      group('childrenCount', () {
        test('возвращает количество детей', () {
          // Arrange
          final family = Family(
            id: 'f1',
            treeId: 't1',
            childrenIds: ['child1', 'child2', 'child3'],
          );

          // Assert
          expect(family.childrenCount, 3);
        });

        test('возвращает 0 если нет детей', () {
          // Arrange
          final family = Family(id: 'f1', treeId: 't1', childrenIds: []);

          // Assert
          expect(family.childrenCount, 0);
        });
      });

      group('parentIds', () {
        test('возвращает список ID родителей (только не-null значения)', () {
          // Arrange
          final family = Family(
            id: 'f1',
            treeId: 't1',
            husbandId: 'husband1',
            wifeId: 'wife1',
          );

          // Assert
          expect(family.parentIds, ['husband1', 'wife1']);
        });

        test(
          'возвращает список только с husbandId, если wifeId отсутствует',
          () {
            // Arrange
            final family = Family(
              id: 'f1',
              treeId: 't1',
              husbandId: 'husband1',
              wifeId: null,
            );

            // Assert
            expect(family.parentIds, ['husband1']);
          },
        );

        test(
          'возвращает список только с wifeId, если husbandId отсутствует',
          () {
            // Arrange
            final family = Family(
              id: 'f1',
              treeId: 't1',
              husbandId: null,
              wifeId: 'wife1',
            );

            // Assert
            expect(family.parentIds, ['wife1']);
          },
        );

        test('возвращает пустой список, если нет родителей', () {
          // Arrange
          final family = Family(
            id: 'f1',
            treeId: 't1',
            husbandId: null,
            wifeId: null,
          );

          // Assert
          expect(family.parentIds, []);
        });
      });
    });

    // ============================================================
    // 3. ТЕСТЫ COPYWITH
    // ============================================================

    group('copyWith', () {
      test('копирует Family с изменением полей', () {
        // Arrange
        final original = Family(
          id: 'f1',
          treeId: 't1',
          husbandId: 'h1',
          wifeId: 'w1',
          childrenIds: ['c1'],
          marriageDate: DateTime(2000, 1, 1),
          divorceDate: null,
          marriagePlace: 'Москва',
          notes: 'Тест',
        );

        // Act
        final updated = original.copyWith(
          husbandId: 'h2',
          wifeId: 'w2',
          childrenIds: ['c1', 'c2'],
          divorceDate: DateTime(2010, 1, 1),
          marriagePlace: 'СПб',
        );

        // Assert
        expect(updated.id, original.id);
        expect(updated.treeId, original.treeId);
        expect(updated.husbandId, 'h2');
        expect(updated.wifeId, 'w2');
        expect(updated.childrenIds, ['c1', 'c2']);
        expect(updated.marriageDate, original.marriageDate);
        expect(updated.divorceDate, DateTime(2010, 1, 1));
        expect(updated.marriagePlace, 'СПб');
        expect(updated.notes, original.notes);
      });

      test('copyWith сохраняет неизмененные поля', () {
        // Arrange
        final original = Family(
          id: 'f1',
          treeId: 't1',
          husbandId: 'h1',
          wifeId: 'w1',
          childrenIds: ['c1'],
        );

        // Act
        final updated = original.copyWith(husbandId: 'h2');

        // Assert
        expect(updated.wifeId, original.wifeId);
        expect(updated.childrenIds, original.childrenIds);
        expect(updated.marriageDate, original.marriageDate);
        expect(updated.divorceDate, original.divorceDate);
        expect(updated.marriagePlace, original.marriagePlace);
        expect(updated.notes, original.notes);
      });
    });

    // ============================================================
    // 4. ТЕСТЫ EQUATABLE
    // ============================================================

    group('Equatable', () {
      test('две одинаковые Family равны', () {
        // Arrange
        final family1 = Family(
          id: 'f1',
          treeId: 't1',
          husbandId: 'h1',
          wifeId: 'w1',
          childrenIds: ['c1'],
        );
        final family2 = Family(
          id: 'f1',
          treeId: 't1',
          husbandId: 'h1',
          wifeId: 'w1',
          childrenIds: ['c1'],
        );

        // Assert
        expect(family1 == family2, true);
        expect(family1.hashCode, family2.hashCode);
      });

      test('две разные Family не равны', () {
        // Arrange
        final family1 = Family(
          id: 'f1',
          treeId: 't1',
          husbandId: 'h1',
          wifeId: 'w1',
          childrenIds: ['c1'],
        );
        final family2 = Family(
          id: 'f2',
          treeId: 't1',
          husbandId: 'h2',
          wifeId: 'w2',
          childrenIds: ['c2'],
        );

        // Assert
        expect(family1 == family2, false);
        expect(family1.hashCode, isNot(family2.hashCode));
      });

      test('Family сравнивается по всем полям из props', () {
        // Arrange
        final family = Family(
          id: 'f1',
          treeId: 't1',
          husbandId: 'h1',
          wifeId: 'w1',
          childrenIds: ['c1'],
        );

        // Assert
        expect(family.props.length, 9); // Количество полей в props
      });
    });
  });
}
