// test/unit/repositories/person_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nm_gen/core/enums/gender.dart';
import 'package:nm_gen/data/datasources/local/database/person_model.dart';
import 'package:nm_gen/data/datasources/local/person_local_datasource.dart';
import 'package:nm_gen/data/repositories/person_repository_impl.dart';
import 'package:nm_gen/domain/entities/person.dart';
import '../../test_utils/test_helpers.dart';
import '../../test_utils/mocks.dart';

void main() {
  late MockPersonLocalDataSource mockDataSource;
  late PersonRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockPersonLocalDataSource();
    repository = PersonRepositoryImpl(mockDataSource);

    // Регистрируем fallback значение для PersonModel
    registerFallbackValue(
      PersonModel(
        id: 'fallback',
        treeId: 'fallback',
        firstName: 'fallback',
        lastName: 'fallback',
        middleName: null,
        gender: 'male',
        birthDate: null,
        deathDate: null,
        birthPlace: null,
        deathPlace: null,
        occupation: null,
        biography: null,
        photoUrls: '',
        photoPath: null,
        createdAt: 0,
        updatedAt: 0,
      ),
    );
  });

  group('PersonRepository', () {
    const personId = 'p1';
    const treeId = 'tree_1';
    final now = DateTime.now();

    test('addPerson добавляет нового человека', () async {
      // Arrange
      final person = createTestPerson(
        id: personId,
        treeId: treeId,
        firstName: 'Иван',
        lastName: 'Иванов',
      );
      final model = PersonModel.fromDomain(person);

      when(
        () => mockDataSource.insertPerson(any()),
      ).thenAnswer((_) async => model);

      // Act
      final result = await repository.addPerson(person);

      // Assert
      expect(result.id, personId);
      expect(result.firstName, 'Иван');
      expect(result.lastName, 'Иванов');
      verify(() => mockDataSource.insertPerson(any())).called(1);
    });

    test('getPerson возвращает человека по ID', () async {
      // Arrange
      final person = createTestPerson(id: personId, firstName: 'Иван');
      final model = PersonModel.fromDomain(person);

      when(
        () => mockDataSource.getPerson(personId),
      ).thenAnswer((_) async => model);

      // Act
      final result = await repository.getPerson(personId);

      // Assert
      expect(result, isNotNull);
      expect(result!.id, personId);
      expect(result.firstName, 'Иван');
    });

    test('getPerson возвращает null если человек не найден', () async {
      // Arrange
      when(
        () => mockDataSource.getPerson('nonexistent'),
      ).thenAnswer((_) async => null);

      // Act
      final result = await repository.getPerson('nonexistent');

      // Assert
      expect(result, null);
    });

    test('getAllPersons возвращает список всех людей', () async {
      // Arrange
      final models = [
        PersonModel.fromDomain(createTestPerson(id: 'p1', firstName: 'Иван')),
        PersonModel.fromDomain(createTestPerson(id: 'p2', firstName: 'Мария')),
      ];

      when(
        () => mockDataSource.getAllPersons(treeId: treeId),
      ).thenAnswer((_) async => models);

      // Act
      final result = await repository.getAllPersons(treeId: treeId);

      // Assert
      expect(result.length, 2);
      expect(result[0].firstName, 'Иван');
      expect(result[1].firstName, 'Мария');
      verify(() => mockDataSource.getAllPersons(treeId: treeId)).called(1);
    });

    test('getAllPersons возвращает пустой список если людей нет', () async {
      // Arrange
      when(
        () => mockDataSource.getAllPersons(treeId: treeId),
      ).thenAnswer((_) async => []);

      // Act
      final result = await repository.getAllPersons(treeId: treeId);

      // Assert
      expect(result, isEmpty);
    });

    test('updatePerson обновляет данные человека', () async {
      // Arrange
      final person = createTestPerson(
        id: personId,
        firstName: 'Иван',
        lastName: 'Иванов',
      );
      final updatedPerson = person.copyWith(
        firstName: 'Петр',
        lastName: 'Петров',
      );
      final model = PersonModel.fromDomain(updatedPerson);

      when(
        () => mockDataSource.updatePerson(any()),
      ).thenAnswer((_) async => model);

      // Act
      final result = await repository.updatePerson(updatedPerson);

      // Assert
      expect(result.firstName, 'Петр');
      expect(result.lastName, 'Петров');
      verify(() => mockDataSource.updatePerson(any())).called(1);
    });

    test('deletePerson удаляет человека по ID', () async {
      // Arrange
      when(
        () => mockDataSource.deletePerson(personId),
      ).thenAnswer((_) async => {});

      // Act
      await repository.deletePerson(personId);

      // Assert
      verify(() => mockDataSource.deletePerson(personId)).called(1);
    });

    test('deleteAllPersons удаляет всех людей', () async {
      // Arrange
      when(
        () => mockDataSource.deleteAllPersons(treeId: treeId),
      ).thenAnswer((_) async => {});

      // Act
      await repository.deleteAllPersons(treeId: treeId);

      // Assert
      verify(() => mockDataSource.deleteAllPersons(treeId: treeId)).called(1);
    });

    test('searchPersons возвращает результаты поиска', () async {
      // Arrange
      const query = 'Иван';
      final models = [
        PersonModel.fromDomain(createTestPerson(id: 'p1', firstName: 'Иван')),
      ];

      when(
        () => mockDataSource.searchPersons(query, treeId: treeId),
      ).thenAnswer((_) async => models);

      // Act
      final result = await repository.searchPersons(query, treeId: treeId);

      // Assert
      expect(result.length, 1);
      expect(result[0].firstName, 'Иван');
      verify(
        () => mockDataSource.searchPersons(query, treeId: treeId),
      ).called(1);
    });

    test('searchPersons возвращает всех людей при пустом запросе', () async {
      // Arrange
      const query = '';
      final models = [
        PersonModel.fromDomain(createTestPerson(id: 'p1', firstName: 'Иван')),
        PersonModel.fromDomain(createTestPerson(id: 'p2', firstName: 'Мария')),
      ];

      when(
        () => mockDataSource.getAllPersons(treeId: treeId),
      ).thenAnswer((_) async => models);

      // Act
      final result = await repository.searchPersons(query, treeId: treeId);

      // Assert
      expect(result.length, 2);
      verify(() => mockDataSource.getAllPersons(treeId: treeId)).called(1);
    });

    test('getPersonsByIds возвращает людей по списку ID', () async {
      // Arrange
      final ids = ['p1', 'p2'];
      final models = [
        PersonModel.fromDomain(createTestPerson(id: 'p1', firstName: 'Иван')),
        PersonModel.fromDomain(createTestPerson(id: 'p2', firstName: 'Мария')),
      ];

      when(
        () => mockDataSource.getPersonsByIds(ids, treeId: treeId),
      ).thenAnswer((_) async => models);

      // Act
      final result = await repository.getPersonsByIds(ids, treeId: treeId);

      // Assert
      expect(result.length, 2);
      verify(
        () => mockDataSource.getPersonsByIds(ids, treeId: treeId),
      ).called(1);
    });

    test(
      'getPersonsByIds возвращает пустой список при пустом списке ID',
      () async {
        // Act
        final result = await repository.getPersonsByIds([], treeId: treeId);

        // Assert
        expect(result, isEmpty);
        verifyNever(
          () => mockDataSource.getPersonsByIds(
            any(),
            treeId: any(named: 'treeId'),
          ),
        );
      },
    );

    test('getPersonsCount возвращает количество людей', () async {
      // Arrange
      when(
        () => mockDataSource.getPersonsCount(treeId: treeId),
      ).thenAnswer((_) async => 5);

      // Act
      final result = await repository.getPersonsCount(treeId: treeId);

      // Assert
      expect(result, 5);
      verify(() => mockDataSource.getPersonsCount(treeId: treeId)).called(1);
    });
  });
}
