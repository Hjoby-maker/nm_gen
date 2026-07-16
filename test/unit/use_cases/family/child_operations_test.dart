// test/unit/use_cases/family/child_operations_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/repositories/family_repository.dart';
import 'package:nm_gen/domain/use_cases/family/add_child_to_family.dart';
import 'package:nm_gen/domain/use_cases/family/remove_child_from_family.dart';
import '../../../test_utils/mocks.dart';

void main() {
  group('Child Operations Use Cases', () {
    late MockFamilyRepository mockRepository;

    setUp(() {
      mockRepository = MockFamilyRepository();
    });

    group('AddChildToFamilyUseCase', () {
      late AddChildToFamilyUseCase useCase;

      setUp(() {
        useCase = AddChildToFamilyUseCase(mockRepository);
      });

      test('успешно добавляет ребенка в семью', () async {
        // Arrange
        const familyId = 'f1';
        const childId = 'c1';

        when(
          () => mockRepository.addChildToFamily(familyId, childId),
        ).thenAnswer((_) async => {});

        // Act
        final result = await useCase.execute(familyId, childId);

        // Assert
        expect(result.isRight(), true);
        verify(
          () => mockRepository.addChildToFamily(familyId, childId),
        ).called(1);
      });

      test('возвращает Left с ValidationFailure при пустом familyId', () async {
        // Act
        final result = await useCase.execute('', 'c1');

        // Assert
        expect(result.isLeft(), true);
        expect(
          result.fold(
            (failure) =>
                failure is ValidationFailure &&
                failure.message.contains('не могут быть пустыми'),
            (_) => false,
          ),
          true,
        );
        verifyNever(() => mockRepository.addChildToFamily(any(), any()));
      });

      test('возвращает Left с ValidationFailure при пустом childId', () async {
        // Act
        final result = await useCase.execute('f1', '');

        // Assert
        expect(result.isLeft(), true);
        expect(
          result.fold(
            (failure) =>
                failure is ValidationFailure &&
                failure.message.contains('не могут быть пустыми'),
            (_) => false,
          ),
          true,
        );
        verifyNever(() => mockRepository.addChildToFamily(any(), any()));
      });

      test('возвращает Left с ServerFailure при ошибке репозитория', () async {
        // Arrange
        const familyId = 'f1';
        const childId = 'c1';

        when(
          () => mockRepository.addChildToFamily(familyId, childId),
        ).thenThrow(Exception('Database error'));

        // Act
        final result = await useCase.execute(familyId, childId);

        // Assert
        expect(result.isLeft(), true);
        expect(
          result.fold((failure) => failure is ServerFailure, (_) => false),
          true,
        );
      });
    });

    group('RemoveChildFromFamilyUseCase', () {
      late RemoveChildFromFamilyUseCase useCase;

      setUp(() {
        useCase = RemoveChildFromFamilyUseCase(mockRepository);
      });

      test('успешно удаляет ребенка из семьи', () async {
        // Arrange
        const familyId = 'f1';
        const childId = 'c1';

        when(
          () => mockRepository.removeChildFromFamily(familyId, childId),
        ).thenAnswer((_) async => {});

        // Act
        final result = await useCase.execute(familyId, childId);

        // Assert
        expect(result.isRight(), true);
        verify(
          () => mockRepository.removeChildFromFamily(familyId, childId),
        ).called(1);
      });

      test('возвращает Left с ValidationFailure при пустом familyId', () async {
        // Act
        final result = await useCase.execute('', 'c1');

        // Assert
        expect(result.isLeft(), true);
        expect(
          result.fold(
            (failure) =>
                failure is ValidationFailure &&
                failure.message.contains('не могут быть пустыми'),
            (_) => false,
          ),
          true,
        );
        verifyNever(() => mockRepository.removeChildFromFamily(any(), any()));
      });

      test('возвращает Left с ServerFailure при ошибке репозитория', () async {
        // Arrange
        const familyId = 'f1';
        const childId = 'c1';

        when(
          () => mockRepository.removeChildFromFamily(familyId, childId),
        ).thenThrow(Exception('Database error'));

        // Act
        final result = await useCase.execute(familyId, childId);

        // Assert
        expect(result.isLeft(), true);
        expect(
          result.fold((failure) => failure is ServerFailure, (_) => false),
          true,
        );
      });
    });
  });
}
