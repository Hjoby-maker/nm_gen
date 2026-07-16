// test/unit/use_cases/family/get_families_by_person_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/entities/family.dart';
import 'package:nm_gen/domain/repositories/family_repository.dart';
import 'package:nm_gen/domain/use_cases/family/get_families_by_person.dart';
import '../../../test_utils/mocks.dart';

void main() {
  late MockFamilyRepository mockRepository;
  late GetFamiliesByPersonUseCase useCase;

  setUp(() {
    mockRepository = MockFamilyRepository();
    useCase = GetFamiliesByPersonUseCase(mockRepository);
  });

  group('GetFamiliesByPersonUseCase', () {
    test('возвращает список семей для человека', () async {
      // Arrange
      const personId = 'p1';
      final families = [
        Family(
          id: 'f1',
          treeId: 'tree_1',
          husbandId: personId,
          wifeId: 'p2',
          childrenIds: [],
        ),
        Family(
          id: 'f2',
          treeId: 'tree_1',
          husbandId: 'p3',
          wifeId: personId,
          childrenIds: ['c1'],
        ),
      ];

      when(
        () => mockRepository.getFamiliesByPerson(personId, treeId: null),
      ).thenAnswer((_) async => families);

      // Act
      final result = await useCase.execute(personId);

      // Assert
      expect(result.isRight(), true);
      final resultFamilies = result.getOrElse(() => []);
      expect(resultFamilies.length, 2);
      expect(resultFamilies[0].husbandId, personId);
      expect(resultFamilies[1].wifeId, personId);
      verify(
        () => mockRepository.getFamiliesByPerson(personId, treeId: null),
      ).called(1);
    });

    test('возвращает пустой список если у человека нет семей', () async {
      // Arrange
      const personId = 'p1';

      when(
        () => mockRepository.getFamiliesByPerson(personId, treeId: null),
      ).thenAnswer((_) async => []);

      // Act
      final result = await useCase.execute(personId);

      // Assert
      expect(result.isRight(), true);
      final resultFamilies = result.getOrElse(() => []);
      expect(resultFamilies, isEmpty);
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
      verifyNever(
        () => mockRepository.getFamiliesByPerson(
          any(),
          treeId: any(named: 'treeId'),
        ),
      );
    });

    test('передает treeId в репозиторий', () async {
      // Arrange
      const personId = 'p1';
      const treeId = 'tree_1';

      when(
        () => mockRepository.getFamiliesByPerson(personId, treeId: treeId),
      ).thenAnswer((_) async => []);

      // Act
      await useCase.execute(personId, treeId: treeId);

      // Assert
      verify(
        () => mockRepository.getFamiliesByPerson(personId, treeId: treeId),
      ).called(1);
    });

    test('возвращает Left с ServerFailure при ошибке репозитория', () async {
      // Arrange
      const personId = 'p1';

      when(
        () => mockRepository.getFamiliesByPerson(personId, treeId: null),
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
