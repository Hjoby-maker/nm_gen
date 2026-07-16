// test/unit/use_cases/family/get_family_with_details_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/entities/family.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/repositories/family_repository.dart';
import 'package:nm_gen/domain/repositories/person_repository.dart';
import 'package:nm_gen/domain/use_cases/family/get_family_with_details.dart';
import '../../../test_utils/test_helpers.dart';
import '../../../test_utils/mocks.dart';

void main() {
  late MockFamilyRepository mockFamilyRepository;
  late MockPersonRepository mockPersonRepository;
  late GetFamilyWithDetailsUseCase useCase;

  setUp(() {
    mockFamilyRepository = MockFamilyRepository();
    mockPersonRepository = MockPersonRepository();
    useCase = GetFamilyWithDetailsUseCase(
      familyRepository: mockFamilyRepository,
      personRepository: mockPersonRepository,
    );

    // Регистрируем fallback значение для Person
    registerFallbackValue(createTestPerson(id: 'fallback'));
  });

  group('GetFamilyWithDetailsUseCase', () {
    test('возвращает FamilyDetails с супругами и детьми', () async {
      // Arrange
      const familyId = 'f1';
      const husbandId = 'p1';
      const wifeId = 'p2';
      const childId = 'c1';

      final family = Family(
        id: familyId,
        treeId: 'tree_1',
        husbandId: husbandId,
        wifeId: wifeId,
        childrenIds: [childId],
      );
      final husband = createTestPerson(id: husbandId, firstName: 'Иван');
      final wife = createTestPerson(id: wifeId, firstName: 'Мария');
      final child = createTestPerson(id: childId, firstName: 'Петр');

      when(
        () => mockFamilyRepository.getFamily(familyId),
      ).thenAnswer((_) async => family);
      when(
        () => mockPersonRepository.getPerson(husbandId),
      ).thenAnswer((_) async => husband);
      when(
        () => mockPersonRepository.getPerson(wifeId),
      ).thenAnswer((_) async => wife);
      when(
        () => mockPersonRepository.getPerson(childId),
      ).thenAnswer((_) async => child);

      // Act
      final result = await useCase.execute(familyId);

      // Assert
      expect(result.isRight(), true);
      final details = result.getOrElse(
        () => FamilyDetails(family: Family.empty()),
      );
      expect(details.family.id, familyId);
      expect(details.husband?.firstName, 'Иван');
      expect(details.wife?.firstName, 'Мария');
      expect(details.children.length, 1);
      expect(details.children[0].firstName, 'Петр');
      expect(details.memberCount, 3);
      expect(details.isComplete, true);

      verify(() => mockFamilyRepository.getFamily(familyId)).called(1);
      verify(() => mockPersonRepository.getPerson(husbandId)).called(1);
      verify(() => mockPersonRepository.getPerson(wifeId)).called(1);
      verify(() => mockPersonRepository.getPerson(childId)).called(1);
    });

    test(
      'возвращает FamilyDetails с частичными данными если нет супруга',
      () async {
        // Arrange
        const familyId = 'f1';
        const husbandId = 'p1';
        const childId = 'c1';

        final family = Family(
          id: familyId,
          treeId: 'tree_1',
          husbandId: husbandId,
          wifeId: null,
          childrenIds: [childId],
        );
        final husband = createTestPerson(id: husbandId, firstName: 'Иван');
        final child = createTestPerson(id: childId, firstName: 'Петр');

        when(
          () => mockFamilyRepository.getFamily(familyId),
        ).thenAnswer((_) async => family);
        when(
          () => mockPersonRepository.getPerson(husbandId),
        ).thenAnswer((_) async => husband);
        when(
          () => mockPersonRepository.getPerson(childId),
        ).thenAnswer((_) async => child);

        // Act
        final result = await useCase.execute(familyId);

        // Assert
        expect(result.isRight(), true);
        final details = result.getOrElse(
          () => FamilyDetails(family: Family.empty()),
        );
        expect(details.family.id, familyId);
        expect(details.husband?.firstName, 'Иван');
        expect(details.wife, null);
        expect(details.children.length, 1);
        expect(details.memberCount, 2);
        expect(details.isComplete, false);
      },
    );

    test('возвращает FamilyDetails без детей если их нет', () async {
      // Arrange
      const familyId = 'f1';
      const husbandId = 'p1';
      const wifeId = 'p2';

      final family = Family(
        id: familyId,
        treeId: 'tree_1',
        husbandId: husbandId,
        wifeId: wifeId,
        childrenIds: [],
      );
      final husband = createTestPerson(id: husbandId, firstName: 'Иван');
      final wife = createTestPerson(id: wifeId, firstName: 'Мария');

      when(
        () => mockFamilyRepository.getFamily(familyId),
      ).thenAnswer((_) async => family);
      when(
        () => mockPersonRepository.getPerson(husbandId),
      ).thenAnswer((_) async => husband);
      when(
        () => mockPersonRepository.getPerson(wifeId),
      ).thenAnswer((_) async => wife);

      // Act
      final result = await useCase.execute(familyId);

      // Assert
      expect(result.isRight(), true);
      final details = result.getOrElse(
        () => FamilyDetails(family: Family.empty()),
      );
      expect(details.children, isEmpty);
      expect(details.memberCount, 2);
      expect(details.isComplete, true);
    });

    test('возвращает Left с NotFoundFailure если семья не найдена', () async {
      // Arrange
      const familyId = 'nonexistent';

      when(
        () => mockFamilyRepository.getFamily(familyId),
      ).thenAnswer((_) async => null);

      // Act
      final result = await useCase.execute(familyId);

      // Assert
      expect(result.isLeft(), true);
      expect(
        result.fold(
          (failure) =>
              failure is NotFoundFailure &&
              failure.message.contains('не найдена'),
          (_) => false,
        ),
        true,
      );
      verify(() => mockFamilyRepository.getFamily(familyId)).called(1);
      verifyNever(() => mockPersonRepository.getPerson(any()));
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
      verifyNever(() => mockFamilyRepository.getFamily(any()));
    });

    test('обрабатывает отсутствие супругов', () async {
      // Arrange
      const familyId = 'f1';
      final family = Family(
        id: familyId,
        treeId: 'tree_1',
        husbandId: null,
        wifeId: null,
        childrenIds: [],
      );

      when(
        () => mockFamilyRepository.getFamily(familyId),
      ).thenAnswer((_) async => family);

      // Act
      final result = await useCase.execute(familyId);

      // Assert
      expect(result.isRight(), true);
      final details = result.getOrElse(
        () => FamilyDetails(family: Family.empty()),
      );
      expect(details.husband, null);
      expect(details.wife, null);
      expect(details.children, isEmpty);
      expect(details.memberCount, 0);
      expect(details.isComplete, false);
    });

    test(
      'возвращает Left с ServerFailure при ошибке репозитория семьи',
      () async {
        // Arrange
        const familyId = 'f1';

        when(
          () => mockFamilyRepository.getFamily(familyId),
        ).thenThrow(Exception('Database error'));

        // Act
        final result = await useCase.execute(familyId);

        // Assert
        expect(result.isLeft(), true);
        expect(
          result.fold((failure) => failure is ServerFailure, (_) => false),
          true,
        );
      },
    );

    test(
      'возвращает Left с ServerFailure при ошибке репозитория человека',
      () async {
        // Arrange
        const familyId = 'f1';
        const husbandId = 'p1';

        final family = Family(
          id: familyId,
          treeId: 'tree_1',
          husbandId: husbandId,
          wifeId: null,
          childrenIds: [],
        );

        when(
          () => mockFamilyRepository.getFamily(familyId),
        ).thenAnswer((_) async => family);
        when(
          () => mockPersonRepository.getPerson(husbandId),
        ).thenThrow(Exception('Person database error'));

        // Act
        final result = await useCase.execute(familyId);

        // Assert
        expect(result.isLeft(), true);
        expect(
          result.fold((failure) => failure is ServerFailure, (_) => false),
          true,
        );
      },
    );
  });
}
