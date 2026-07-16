// test/unit/services/gedcom_generator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nm_gen/core/enums/gender.dart';
import 'package:nm_gen/core/utils/gedcom_generator.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/entities/family.dart';

void main() {
  group('GedcomGenerator', () {
    late List<Person> testPersons;
    late List<Family> testFamilies;

    setUp(() {
      testPersons = [
        Person.create(
          firstName: 'Иван',
          lastName: 'Иванов',
          middleName: 'Петрович',
          gender: Gender.male,
          birthDate: DateTime(1980, 1, 15),
          birthPlace: 'Москва',
          occupation: 'Инженер',
        ),
        Person.create(
          firstName: 'Мария',
          lastName: 'Иванова',
          middleName: 'Сергеевна',
          gender: Gender.female,
          birthDate: DateTime(1982, 5, 20),
          birthPlace: 'Санкт-Петербург',
          occupation: 'Врач',
        ),
        Person.create(
          firstName: 'Петр',
          lastName: 'Иванов',
          middleName: 'Иванович',
          gender: Gender.male,
          birthDate: DateTime(2005, 8, 10),
          birthPlace: 'Москва',
        ),
      ];

      testFamilies = [
        Family(
          id: 'family_1',
          treeId: 'tree_1',
          husbandId: testPersons[0].id,
          wifeId: testPersons[1].id,
          childrenIds: [testPersons[2].id],
          marriageDate: DateTime(2004, 6, 1),
          divorceDate: null,
          marriagePlace: 'Москва',
          notes: 'Семья Ивановых',
        ),
      ];
    });

    test('генерирует GEDCOM с правильным заголовком', () {
      // Act
      final gedcom = GedcomGenerator.generate(testPersons, testFamilies);

      // Assert
      expect(gedcom, startsWith('0 HEAD'));
      expect(gedcom, contains('1 SOUR GEN'));
      expect(gedcom, contains('1 GEDC'));
      expect(gedcom, contains('2 VERS 5.5.1'));
      expect(gedcom, contains('1 CHAR UTF-8'));
      expect(gedcom, endsWith('0 TRLR\n'));
    });

    test('содержит всех людей в GEDCOM', () {
      // Act
      final gedcom = GedcomGenerator.generate(testPersons, testFamilies);

      // Assert
      for (final person in testPersons) {
        expect(gedcom, contains('@${person.id}@ INDI'));
        expect(
          gedcom,
          contains('1 NAME ${person.firstName} /${person.lastName}/'),
        );
        expect(
          gedcom,
          contains('1 SEX ${person.gender == Gender.male ? 'M' : 'F'}'),
        );
      }
    });

    test('содержит даты рождения и смерти в правильном формате', () {
      // Act
      final gedcom = GedcomGenerator.generate(testPersons, testFamilies);

      // Assert
      expect(gedcom, contains('1 BIRT'));
      expect(gedcom, contains('2 DATE 15 JAN 1980'));
      expect(gedcom, contains('1 _BIRT_PLACE Москва'));
      expect(gedcom, contains('1 OCCU Инженер'));
    });

    test('содержит все семьи в GEDCOM', () {
      // Act
      final gedcom = GedcomGenerator.generate(testPersons, testFamilies);

      // Assert
      for (final family in testFamilies) {
        expect(gedcom, contains('@${family.id}@ FAM'));
        if (family.husbandId != null) {
          expect(gedcom, contains('1 HUSB @${family.husbandId}@'));
        }
        if (family.wifeId != null) {
          expect(gedcom, contains('1 WIFE @${family.wifeId}@'));
        }
        for (final childId in family.childrenIds) {
          expect(gedcom, contains('1 CHIL @$childId@'));
        }
      }
    });

    test('содержит дату брака в правильном формате', () {
      // Act
      final gedcom = GedcomGenerator.generate(testPersons, testFamilies);

      // Assert
      expect(gedcom, contains('1 MARR'));
      expect(gedcom, contains('2 DATE 01 JUN 2004'));
    });

    test('пропускает опциональные поля, если они отсутствуют', () {
      // Arrange
      final personWithoutBirth = Person.create(
        firstName: 'Анна',
        lastName: 'Сидорова',
        gender: Gender.female,
        birthDate: null,
        birthPlace: null,
        occupation: null,
      );

      // Act
      final gedcom = GedcomGenerator.generate([personWithoutBirth], []);

      // Assert
      expect(gedcom, isNot(contains('1 BIRT')));
      expect(gedcom, isNot(contains('1 _BIRT_PLACE')));
      expect(gedcom, isNot(contains('1 OCCU')));
    });
  });
}
