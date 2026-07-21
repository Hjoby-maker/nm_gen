// test/unit/use_cases/tree/get_family_tree_test.dart
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
import 'package:nm_gen/domain/use_cases/tree/get_family_tree.dart';
import '../../../test_utils/mocks.dart';

void main() {
  late MockPersonRepository mockPersonRepository;
  late MockFamilyRepository mockFamilyRepository;
  late GetFamilyTreeUseCase useCase;

  setUp(() {
    mockPersonRepository = MockPersonRepository();
    mockFamilyRepository = MockFamilyRepository();
    useCase = GetFamilyTreeUseCase(
      personRepository: mockPersonRepository,
      familyRepository: mockFamilyRepository,
    );
  });

  group('GetFamilyTreeUseCase', () {
    final now = DateTime.now();

    test('возвращает дерево для существующего человека', () async {
      // Arrange
      final person = Person(
        id: 'p1',
        treeId: 'tree_1',
        firstName: 'Иван',
        lastName: 'Иванов',
        gender: Gender.male,
        createdAt: now,
        updatedAt: now,
      );

      final spouse = Person(
        id: 'p2',
        treeId: 'tree_1',
        firstName: 'Мария',
        lastName: 'Иванова',
        gender: Gender.female,
        createdAt: now,
        updatedAt: now,
      );

      final child = Person(
        id: 'p3',
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
        husbandId: person.id,
        wifeId: spouse.id,
        childrenIds: [child.id],
      );

      when(
        () => mockPersonRepository.getPerson('p1'),
      ).thenAnswer((_) async => person);
      when(
        () => mockPersonRepository.getAllPersons(treeId: 'tree_1'),
      ).thenAnswer((_) async => [person, spouse, child]);
      when(
        () => mockFamilyRepository.getAllFamilies(treeId: 'tree_1'),
      ).thenAnswer((_) async => [family]);

      // Act
      final result = await useCase.execute('p1', treeId: 'tree_1');

      // Assert
      expect(result.isRight(), true);
      final rootNode = result.getOrElse(() => TreeNode(person: Person.empty()));

      // В логике GetFamilyTreeUseCase корень - это человек без родителей
      // p1 не имеет родителей, поэтому он становится корнем
      expect(rootNode.person.id, 'p1');
      // Проверяем, что у корня есть супруг и дети
      expect(rootNode.spouses.isNotEmpty, true);
      expect(rootNode.children.isNotEmpty, true);
    });

    test('возвращает дерево с центром на p1', () async {
      // Arrange
      final person = Person(
        id: 'p1',
        treeId: 'tree_1',
        firstName: 'Иван',
        lastName: 'Иванов',
        gender: Gender.male,
        createdAt: now,
        updatedAt: now,
      );

      final spouse = Person(
        id: 'p2',
        treeId: 'tree_1',
        firstName: 'Мария',
        lastName: 'Иванова',
        gender: Gender.female,
        createdAt: now,
        updatedAt: now,
      );

      final child = Person(
        id: 'p3',
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
        husbandId: person.id,
        wifeId: spouse.id,
        childrenIds: [child.id],
      );

      when(
        () => mockPersonRepository.getPerson('p1'),
      ).thenAnswer((_) async => person);
      when(
        () => mockPersonRepository.getAllPersons(treeId: 'tree_1'),
      ).thenAnswer((_) async => [person, spouse, child]);
      when(
        () => mockFamilyRepository.getAllFamilies(treeId: 'tree_1'),
      ).thenAnswer((_) async => [family]);

      // Act
      final result = await useCase.execute('p1', treeId: 'tree_1');

      // Assert
      expect(result.isRight(), true);
      final rootNode = result.getOrElse(() => TreeNode(person: Person.empty()));

      // p1 должен быть центром
      expect(rootNode.person.id, 'p1');

      // Проверяем, что узел помечен как центр
      expect(rootNode.isCenter, true);
    });

    test('возвращает Left с NotFoundFailure если человек не найден', () async {
      // Arrange
      when(
        () => mockPersonRepository.getPerson('nonexistent'),
      ).thenAnswer((_) async => null);

      // Act
      final result = await useCase.execute('nonexistent');

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

    test('возвращает Left с ServerFailure при ошибке репозитория', () async {
      // Arrange
      when(
        () => mockPersonRepository.getPerson('p1'),
      ).thenThrow(Exception('Database error'));

      // Act
      final result = await useCase.execute('p1');

      // Assert
      expect(result.isLeft(), true);
      expect(
        result.fold((failure) => failure is ServerFailure, (_) => false),
        true,
      );
    });
  });
}
