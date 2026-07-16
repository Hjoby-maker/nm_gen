// test/unit/use_cases/person/delete_person_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/repositories/person_repository.dart';
import 'package:nm_gen/domain/use_cases/person/delete_person.dart';
import '../../../test_utils/mocks.dart';

void main() {
  late MockPersonRepository mockRepository;
  late DeletePersonUseCase useCase;

  setUp(() {
    mockRepository = MockPersonRepository();
    useCase = DeletePersonUseCase(mockRepository);
  });

  group('DeletePersonUseCase', () {
    test('успешно удаляет человека по ID', () async {
      // Arrange
      const personId = 'p1';
      when(
        () => mockRepository.deletePerson(personId),
      ).thenAnswer((_) async => {});

      // Act
      final result = await useCase.execute(personId);

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRepository.deletePerson(personId)).called(1);
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
              failure.message.contains('ID человека не может быть пустым'),
          (_) => false,
        ),
        true,
      );
      verifyNever(() => mockRepository.deletePerson(any()));
    });

    test('возвращает Left с ServerFailure при ошибке репозитория', () async {
      // Arrange
      const personId = 'p1';
      when(
        () => mockRepository.deletePerson(personId),
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
