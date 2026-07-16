// test/unit/models/family_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nm_gen/data/datasources/local/database/family_model.dart';
import 'package:nm_gen/domain/entities/family.dart';

void main() {
  group('FamilyModel', () {
    final now = DateTime.now();
    final roundedNow = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
      now.second,
      now.millisecond,
    );
    const familyId = 'family_1';
    const treeId = 'tree_1';
    const husbandId = 'person_1';
    const wifeId = 'person_2';
    const childrenIds = 'child_1,child_2';
    const marriagePlace = 'Москва';
    const notes = 'Тестовая семья';

    test('fromDomain конвертирует Family в FamilyModel', () {
      // Arrange
      final family = Family(
        id: familyId,
        treeId: treeId,
        husbandId: husbandId,
        wifeId: wifeId,
        childrenIds: ['child_1', 'child_2'],
        marriageDate: roundedNow,
        divorceDate: null,
        marriagePlace: marriagePlace,
        notes: notes,
      );

      // Act
      final model = FamilyModel.fromDomain(family);

      // Assert
      expect(model.id, familyId);
      expect(model.treeId, treeId);
      expect(model.husbandId, husbandId);
      expect(model.wifeId, wifeId);
      expect(model.childrenIds, childrenIds);
      expect(model.marriageDate, roundedNow.millisecondsSinceEpoch);
      expect(model.divorceDate, null);
      expect(model.marriagePlace, marriagePlace);
      expect(model.notes, notes);
    });

    test('fromMap создает FamilyModel из Map (SQLite)', () {
      // Arrange
      final map = {
        'id': familyId,
        'tree_id': treeId,
        'husband_id': husbandId,
        'wife_id': wifeId,
        'children_ids': childrenIds,
        'marriage_date': roundedNow.millisecondsSinceEpoch,
        'divorce_date': null,
        'marriage_place': marriagePlace,
        'notes': notes,
      };

      // Act
      final model = FamilyModel.fromMap(map);

      // Assert
      expect(model.id, familyId);
      expect(model.treeId, treeId);
      expect(model.husbandId, husbandId);
      expect(model.wifeId, wifeId);
      expect(model.childrenIds, childrenIds);
      expect(model.marriageDate, roundedNow.millisecondsSinceEpoch);
      expect(model.divorceDate, null);
      expect(model.marriagePlace, marriagePlace);
      expect(model.notes, notes);
    });

    test('fromMap обрабатывает children_ids как пустую строку', () {
      // Arrange
      final map = {
        'id': familyId,
        'tree_id': treeId,
        'husband_id': husbandId,
        'wife_id': wifeId,
        'children_ids': '',
        'marriage_date': null,
        'divorce_date': null,
        'marriage_place': null,
        'notes': null,
      };

      // Act
      final model = FamilyModel.fromMap(map);

      // Assert
      expect(model.childrenIds, '');
    });

    test('toMap конвертирует FamilyModel в Map для SQLite', () {
      // Arrange
      final model = FamilyModel(
        id: familyId,
        treeId: treeId,
        husbandId: husbandId,
        wifeId: wifeId,
        childrenIds: childrenIds,
        marriageDate: roundedNow.millisecondsSinceEpoch,
        divorceDate: null,
        marriagePlace: marriagePlace,
        notes: notes,
      );

      // Act
      final map = model.toMap();

      // Assert
      expect(map['id'], familyId);
      expect(map['tree_id'], treeId);
      expect(map['husband_id'], husbandId);
      expect(map['wife_id'], wifeId);
      expect(map['children_ids'], childrenIds);
      expect(map['marriage_date'], roundedNow.millisecondsSinceEpoch);
      expect(map['divorce_date'], null);
      expect(map['marriage_place'], marriagePlace);
      expect(map['notes'], notes);
    });

    test('toDomain конвертирует FamilyModel в Family', () {
      // Arrange
      final model = FamilyModel(
        id: familyId,
        treeId: treeId,
        husbandId: husbandId,
        wifeId: wifeId,
        childrenIds: childrenIds,
        marriageDate: roundedNow.millisecondsSinceEpoch,
        divorceDate: null,
        marriagePlace: marriagePlace,
        notes: notes,
      );

      // Act
      final family = model.toDomain();

      // Assert
      expect(family.id, familyId);
      expect(family.treeId, treeId);
      expect(family.husbandId, husbandId);
      expect(family.wifeId, wifeId);
      expect(family.childrenIds, ['child_1', 'child_2']);
      expect(family.marriageDate?.year, roundedNow.year);
      expect(family.marriageDate?.month, roundedNow.month);
      expect(family.marriageDate?.day, roundedNow.day);
      expect(family.divorceDate, null);
      expect(family.marriagePlace, marriagePlace);
      expect(family.notes, notes);
    });

    test('toDomain обрабатывает null даты', () {
      // Arrange
      final model = FamilyModel(
        id: familyId,
        treeId: treeId,
        husbandId: husbandId,
        wifeId: wifeId,
        childrenIds: childrenIds,
        marriageDate: null,
        divorceDate: null,
        marriagePlace: null,
        notes: null,
      );

      // Act
      final family = model.toDomain();

      // Assert
      expect(family.marriageDate, null);
      expect(family.divorceDate, null);
    });

    test('toDomain обрабатывает пустые childrenIds', () {
      // Arrange
      final model = FamilyModel(
        id: familyId,
        treeId: treeId,
        husbandId: husbandId,
        wifeId: wifeId,
        childrenIds: '',
        marriageDate: null,
        divorceDate: null,
        marriagePlace: null,
        notes: null,
      );

      // Act
      final family = model.toDomain();

      // Assert
      expect(family.childrenIds, isEmpty);
    });
  });
}
