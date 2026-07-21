// test/unit/use_cases/tree/get_full_tree_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nm_gen/core/enums/gender.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/entities/family.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/entities/tree_node.dart';
import 'package:nm_gen/domain/repositories/family_repository.dart';
import 'package:nm_gen/domain/repositories/person_repository.dart';
import 'package:nm_gen/domain/use_cases/tree/get_full_tree.dart';
import '../../../test_utils/mocks.dart';

void main() {
  late MockPersonRepository mockPersonRepository;
  late MockFamilyRepository mockFamilyRepository;
  late GetFullTreeUseCase useCase;

  setUp(() {
    mockPersonRepository = MockPersonRepository();
    mockFamilyRepository = MockFamilyRepository();
    useCase = GetFullTreeUseCase(
      personRepository: mockPersonRepository,
      familyRepository: mockFamilyRepository,
    );
  });

  group('GetFullTreeUseCase', () {
    final now = DateTime.now();

    test('возвращает полное дерево для проекта', () async {
      // Arrange
      final person1 = Person(
        id: 'p1',
        treeId: 'tree_1',
        firstName: 'Иван',
        lastName: 'Иванов',
        gender: Gender.male,
        createdAt: now,
        updatedAt: now,
      );

      final person2 = Person(
        id: 'p2',
        treeId: 'tree_1',
        firstName: 'Мария',
        lastName: 'Иванова',
        gender: Gender.female,
        createdAt: now,
        updatedAt: now,
      );

      // Два человека без семей - оба должны быть корневыми
      when(
        () => mockPersonRepository.getAllPersons(treeId: 'tree_1'),
      ).thenAnswer((_) async => [person1, person2]);
      when(
        () => mockFamilyRepository.getAllFamilies(treeId: 'tree_1'),
      ).thenAnswer((_) async => []);

      // Act
      final result = await useCase.execute(treeId: 'tree_1');

      // Assert
      expect(result.isRight(), true);
      final rootNode = result.getOrElse(() => TreeNode(person: Person.empty()));
      expect(rootNode.person.id, 'virtual_root');
      // Два человека без семей -> оба становятся корневыми
      expect(rootNode.children.length, 2);
    });

    test('возвращает дерево с одним корнем если есть семья', () async {
      // Arrange
      final parent = Person(
        id: 'p1',
        treeId: 'tree_1',
        firstName: 'Иван',
        lastName: 'Иванов',
        gender: Gender.male,
        createdAt: now,
        updatedAt: now,
      );

      final child = Person(
        id: 'p2',
        treeId: 'tree_1',
        firstName: 'Петр',
        lastName: 'Иванов',
        gender: Gender.male,
        createdAt: now,
        updatedAt: now,
      );

      final family = Family(
        id: 'f1',
        treeId: 'tree_1',
        husbandId: parent.id,
        wifeId: null,
        childrenIds: [child.id],
      );

      when(
        () => mockPersonRepository.getAllPersons(treeId: 'tree_1'),
      ).thenAnswer((_) async => [parent, child]);
      when(
        () => mockFamilyRepository.getAllFamilies(treeId: 'tree_1'),
      ).thenAnswer((_) async => [family]);

      // Act
      final result = await useCase.execute(treeId: 'tree_1');

      // Assert
      expect(result.isRight(), true);
      final rootNode = result.getOrElse(() => TreeNode(person: Person.empty()));
      expect(rootNode.person.id, 'virtual_root');
      // Только родитель становится корнем
      expect(rootNode.children.length, 1);
    });

    test(
      'возвращает Left с NotFoundFailure если нет людей в проекте',
      () async {
        // Arrange
        when(
          () => mockPersonRepository.getAllPersons(treeId: 'tree_1'),
        ).thenAnswer((_) async => []);
        when(
          () => mockFamilyRepository.getAllFamilies(treeId: 'tree_1'),
        ).thenAnswer((_) async => []);

        // Act
        final result = await useCase.execute(treeId: 'tree_1');

        // Assert
        expect(result.isLeft(), true);
        expect(
          result.fold(
            (failure) =>
                failure is NotFoundFailure &&
                failure.message.contains('нет людей'),
            (_) => false,
          ),
          true,
        );
      },
    );

    test('возвращает дерево с выбранным человеком в центре', () async {
      // Arrange
      final person1 = Person(
        id: 'p1',
        treeId: 'tree_1',
        firstName: 'Иван',
        lastName: 'Иванов',
        gender: Gender.male,
        createdAt: now,
        updatedAt: now,
      );

      final person2 = Person(
        id: 'p2',
        treeId: 'tree_1',
        firstName: 'Мария',
        lastName: 'Иванова',
        gender: Gender.female,
        createdAt: now,
        updatedAt: now,
      );

      when(
        () => mockPersonRepository.getAllPersons(treeId: 'tree_1'),
      ).thenAnswer((_) async => [person1, person2]);
      when(
        () => mockFamilyRepository.getAllFamilies(treeId: 'tree_1'),
      ).thenAnswer((_) async => []);

      // Act
      final result = await useCase.execute(
        treeId: 'tree_1',
        selectedPersonId: 'p1',
      );

      // Assert
      expect(result.isRight(), true);
      final rootNode = result.getOrElse(() => TreeNode(person: Person.empty()));

      // Проверяем, что p1 отмечен как центр
      bool foundCenter = false;
      for (final child in rootNode.children) {
        if (child.person.id == 'p1' && child.isCenter == true) {
          foundCenter = true;
          break;
        }
      }
      expect(foundCenter, true);
    });

    test('возвращает Left с ServerFailure при ошибке репозитория', () async {
      // Arrange
      when(
        () => mockPersonRepository.getAllPersons(treeId: 'tree_1'),
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
  });
}
