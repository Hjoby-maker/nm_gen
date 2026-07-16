// test/unit/use_cases/person/get_all_persons_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/repositories/person_repository.dart';
import 'package:nm_gen/domain/use_cases/person/get_all_persons.dart';
import '../../../test_utils/test_helpers.dart';
import '../../../test_utils/mocks.dart';

void main() {
  late MockPersonRepository mockRepository;
  late GetAllPersonsUseCase useCase;

  setUp(() {
    mockRepository = MockPersonRepository();
    useCase = GetAllPersonsUseCase(mockRepository);
  });

  group('GetAllPersonsUseCase', () {
    test('возвращает список всех людей при успешном запросе', () async {
      // Arrange
      final expectedPersons = [
        createTestPerson(id: 'p1', firstName: 'Иван'),
        createTestPerson(id: 'p2', firstName: 'Мария'),
        createTestPerson(id: 'p3', firstName: 'Петр'),
      ];

      when(
        () => mockRepository.getAllPersons(treeId: any(named: 'treeId')),
      ).thenAnswer((_) async => expectedPersons);

      // Act
      final result = await useCase.execute(treeId: 'tree_1');

      // Assert
      expect(result.isRight(), true);
      final persons = result.getOrElse(() => []);
      expect(persons.length, 3);
      expect(persons[0].firstName, 'Иван');
      expect(persons[1].firstName, 'Мария');
      expect(persons[2].firstName, 'Петр');
      verify(() => mockRepository.getAllPersons(treeId: 'tree_1')).called(1);
    });

    test('возвращает пустой список, если людей нет', () async {
      // Arrange
      when(
        () => mockRepository.getAllPersons(treeId: any(named: 'treeId')),
      ).thenAnswer((_) async => []);

      // Act
      final result = await useCase.execute(treeId: 'tree_1');

      // Assert
      expect(result.isRight(), true);
      final persons = result.getOrElse(() => []);
      expect(persons.isEmpty, true);
    });

    test('возвращает Left с ServerFailure при ошибке репозитория', () async {
      // Arrange
      when(
        () => mockRepository.getAllPersons(treeId: any(named: 'treeId')),
      ).thenThrow(Exception('Database error'));

      // Act
      final result = await useCase.execute(treeId: 'tree_1');

      // Assert
      expect(result.isLeft(), true);
      expect(
        result.fold((failure) => failure is ServerFailure, (_) => false),
        true,
      );
    });

    test('вызывает репозиторий без treeId, если он не передан', () async {
      // Arrange
      when(
        () => mockRepository.getAllPersons(treeId: null),
      ).thenAnswer((_) async => []);

      // Act
      await useCase.execute();

      // Assert
      verify(() => mockRepository.getAllPersons(treeId: null)).called(1);
    });
  });
}
