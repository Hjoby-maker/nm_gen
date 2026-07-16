// test/unit/use_cases/person/search_persons_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/repositories/person_repository.dart';
import 'package:nm_gen/domain/use_cases/person/search_persons.dart';
import '../../../test_utils/test_helpers.dart';
import '../../../test_utils/mocks.dart';

void main() {
  late MockPersonRepository mockRepository;
  late SearchPersonsUseCase useCase;

  setUp(() {
    mockRepository = MockPersonRepository();
    useCase = SearchPersonsUseCase(mockRepository);
  });

  group('SearchPersonsUseCase', () {
    test(
      'возвращает список людей, соответствующих поисковому запросу',
      () async {
        // Arrange
        const query = 'Иван';
        final expectedPersons = [
          createTestPerson(id: 'p1', firstName: 'Иван'),
          createTestPerson(id: 'p2', firstName: 'Иван', lastName: 'Петров'),
        ];

        when(
          () =>
              mockRepository.searchPersons(query, treeId: any(named: 'treeId')),
        ).thenAnswer((_) async => expectedPersons);

        // Act
        final result = await useCase.execute(query);

        // Assert
        expect(result.isRight(), true);
        final persons = result.getOrElse(() => []);
        expect(persons.length, 2);
        expect(persons[0].firstName, 'Иван');
        verify(
          () => mockRepository.searchPersons(query, treeId: null),
        ).called(1);
      },
    );

    test('возвращает пустой список, если ничего не найдено', () async {
      // Arrange
      const query = 'Никто';
      when(
        () => mockRepository.searchPersons(query, treeId: any(named: 'treeId')),
      ).thenAnswer((_) async => []);

      // Act
      final result = await useCase.execute(query);

      // Assert
      expect(result.isRight(), true);
      final persons = result.getOrElse(() => []);
      expect(persons.isEmpty, true);
    });

    test('передает treeId в репозиторий, если он указан', () async {
      // Arrange
      const query = 'Иван';
      const treeId = 'tree_1';
      when(
        () => mockRepository.searchPersons(query, treeId: treeId),
      ).thenAnswer((_) async => []);

      // Act
      await useCase.execute(query, treeId: treeId);

      // Assert
      verify(
        () => mockRepository.searchPersons(query, treeId: treeId),
      ).called(1);
    });

    test('возвращает Left с ServerFailure при ошибке репозитория', () async {
      // Arrange
      const query = 'Иван';
      when(
        () => mockRepository.searchPersons(query, treeId: any(named: 'treeId')),
      ).thenThrow(Exception('Database error'));

      // Act
      final result = await useCase.execute(query);

      // Assert
      expect(result.isLeft(), true);
      expect(
        result.fold((failure) => failure is ServerFailure, (_) => false),
        true,
      );
    });
  });
}
