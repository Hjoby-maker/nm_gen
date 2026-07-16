// test/unit/use_cases/person/get_person_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/repositories/person_repository.dart';
import 'package:nm_gen/domain/use_cases/person/get_person.dart';
import '../../../test_utils/test_helpers.dart';
import '../../../test_utils/mocks.dart';

void main() {
  late MockPersonRepository mockRepository;
  late GetPersonUseCase useCase;

  setUp(() {
    mockRepository = MockPersonRepository();
    useCase = GetPersonUseCase(mockRepository);
  });

  group('GetPersonUseCase', () {
    test('возвращает человека при успешном поиске по ID', () async {
      // Arrange
      const personId = 'p1';
      final expectedPerson = createTestPerson(id: personId, firstName: 'Иван');

      when(
        () => mockRepository.getPerson(personId),
      ).thenAnswer((_) async => expectedPerson);

      // Act
      final result = await useCase.execute(personId);

      // Assert
      expect(result.isRight(), true);
      final person = result.getOrElse(() => Person.empty());
      expect(person.id, personId);
      expect(person.firstName, 'Иван');
      verify(() => mockRepository.getPerson(personId)).called(1);
    });

    test('возвращает Left с ValidationFailure при пустом ID', () async {
      // Act
      final result = await useCase.execute('');

      // Assert
      expect(result.isLeft(), true);
      expect(
        result.fold(
          (failure) =>
              failure is ValidationFailure &&
              failure.message.contains('не может быть пустым'),
          (_) => false,
        ),
        true,
      );
      verifyNever(() => mockRepository.getPerson(any()));
    });

    test('возвращает Left с NotFoundFailure, если человек не найден', () async {
      // Arrange
      const personId = 'nonexistent';

      when(
        () => mockRepository.getPerson(personId),
      ).thenAnswer((_) async => null);

      // Act
      final result = await useCase.execute(personId);

      // Assert
      expect(result.isLeft(), true);
      expect(
        result.fold(
          (failure) =>
              failure is NotFoundFailure &&
              failure.message.contains('не найден'),
          (_) => false,
        ),
        true,
      );
    });

    test(
      'возвращает Left с NotFoundFailure, если treeId не совпадает',
      () async {
        // Arrange
        const personId = 'p1';
        final person = createTestPerson(
          id: personId,
          treeId: 'wrong_tree',
          firstName: 'Иван',
        );

        when(
          () => mockRepository.getPerson(personId),
        ).thenAnswer((_) async => person);

        // Act
        final result = await useCase.execute(personId, treeId: 'tree_1');

        // Assert
        expect(result.isLeft(), true);
        expect(
          result.fold(
            (failure) =>
                failure is NotFoundFailure &&
                failure.message.contains('не найден в текущем древе'),
            (_) => false,
          ),
          true,
        );
      },
    );

    test('возвращает человека, если treeId совпадает', () async {
      // Arrange
      const personId = 'p1';
      const treeId = 'tree_1';
      final expectedPerson = createTestPerson(
        id: personId,
        treeId: treeId,
        firstName: 'Иван',
      );

      when(
        () => mockRepository.getPerson(personId),
      ).thenAnswer((_) async => expectedPerson);

      // Act
      final result = await useCase.execute(personId, treeId: treeId);

      // Assert
      expect(result.isRight(), true);
      final person = result.getOrElse(() => Person.empty());
      expect(person.treeId, treeId);
    });

    test('возвращает Left с ServerFailure при ошибке репозитория', () async {
      // Arrange
      const personId = 'p1';

      when(
        () => mockRepository.getPerson(personId),
      ).thenThrow(Exception('Database error'));

      // Act
      final result = await useCase.execute(personId);

      // Assert
      expect(result.isLeft(), true);
      expect(
        result.fold((failure) => failure is ServerFailure, (_) => false),
        true,
      );
    });
  });
}
