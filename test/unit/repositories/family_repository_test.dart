// test/unit/repositories/family_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nm_gen/data/datasources/local/family_local_datasource.dart';
import 'package:nm_gen/data/repositories/family_repository_impl.dart';
import 'package:nm_gen/domain/entities/family.dart';
import '../../test_utils/mocks.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nm_gen/data/datasources/local/database/family_model.dart';

void main() {
  late MockFamilyLocalDataSource mockDataSource;
  late FamilyRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockFamilyLocalDataSource();
    repository = FamilyRepositoryImpl(mockDataSource);

    // Регистрируем fallback значения для типов, которые могут быть null
    registerFallbackValue(
      FamilyModel(
        id: 'fallback',
        treeId: 'fallback',
        husbandId: null,
        wifeId: null,
        childrenIds: '',
        marriageDate: null,
        divorceDate: null,
        marriagePlace: null,
        notes: null,
      ),
    );
  });

  group('FamilyRepository', () {
    const familyId = 'family_1';
    const treeId = 'tree_1';
    const husbandId = 'person_1';
    const wifeId = 'person_2';
    const childId = 'child_1';

    test('addFamily добавляет новую семью', () async {
      // Arrange
      final family = Family(
        id: familyId,
        treeId: treeId,
        husbandId: husbandId,
        wifeId: wifeId,
        childrenIds: [],
      );
      final model = FamilyModel.fromDomain(family);

      when(
        () => mockDataSource.insertFamily(any()),
      ).thenAnswer((_) async => model);

      // Act
      final result = await repository.addFamily(family);

      // Assert
      expect(result.id, familyId);
      expect(result.treeId, treeId);
      expect(result.husbandId, husbandId);
      expect(result.wifeId, wifeId);
      verify(() => mockDataSource.insertFamily(any())).called(1);
    });

    test('getFamily возвращает семью по ID', () async {
      // Arrange
      final model = FamilyModel(
        id: familyId,
        treeId: treeId,
        husbandId: husbandId,
        wifeId: wifeId,
        childrenIds: '',
        marriageDate: null,
        divorceDate: null,
        marriagePlace: null,
        notes: null,
      );

      when(
        () => mockDataSource.getFamily(familyId),
      ).thenAnswer((_) async => model);

      // Act
      final result = await repository.getFamily(familyId);

      // Assert
      expect(result, isNotNull);
      expect(result!.id, familyId);
      expect(result.husbandId, husbandId);
      expect(result.wifeId, wifeId);
    });

    test('getFamily возвращает null если семья не найдена', () async {
      // Arrange
      when(
        () => mockDataSource.getFamily('nonexistent'),
      ).thenAnswer((_) async => null);

      // Act
      final result = await repository.getFamily('nonexistent');

      // Assert
      expect(result, null);
    });

    test('getAllFamilies возвращает список семей', () async {
      // Arrange
      final models = [
        FamilyModel(
          id: familyId,
          treeId: treeId,
          husbandId: husbandId,
          wifeId: wifeId,
          childrenIds: '',
          marriageDate: null,
          divorceDate: null,
          marriagePlace: null,
          notes: null,
        ),
      ];

      when(
        () => mockDataSource.getAllFamilies(treeId: treeId),
      ).thenAnswer((_) async => models);

      // Act
      final result = await repository.getAllFamilies(treeId: treeId);

      // Assert
      expect(result.length, 1);
      expect(result[0].id, familyId);
      verify(() => mockDataSource.getAllFamilies(treeId: treeId)).called(1);
    });

    test('getAllFamilies возвращает пустой список если семей нет', () async {
      // Arrange
      when(
        () => mockDataSource.getAllFamilies(treeId: treeId),
      ).thenAnswer((_) async => []);

      // Act
      final result = await repository.getAllFamilies(treeId: treeId);

      // Assert
      expect(result, isEmpty);
    });

    test('updateFamily обновляет семью', () async {
      // Arrange
      final family = Family(
        id: familyId,
        treeId: treeId,
        husbandId: husbandId,
        wifeId: wifeId,
        childrenIds: ['child_1'],
      );
      final model = FamilyModel.fromDomain(family);

      when(
        () => mockDataSource.updateFamily(any()),
      ).thenAnswer((_) async => model);

      // Act
      final result = await repository.updateFamily(family);

      // Assert
      expect(result.id, familyId);
      expect(result.childrenIds, ['child_1']);
      verify(() => mockDataSource.updateFamily(any())).called(1);
    });

    test('deleteFamily удаляет семью', () async {
      // Arrange
      when(
        () => mockDataSource.deleteFamily(familyId),
      ).thenAnswer((_) async => {});

      // Act
      await repository.deleteFamily(familyId);

      // Assert
      verify(() => mockDataSource.deleteFamily(familyId)).called(1);
    });

    test('deleteAllFamilies удаляет все семьи', () async {
      // Arrange
      when(
        () => mockDataSource.deleteAllFamilies(treeId: treeId),
      ).thenAnswer((_) async => {});

      // Act
      await repository.deleteAllFamilies(treeId: treeId);

      // Assert
      verify(() => mockDataSource.deleteAllFamilies(treeId: treeId)).called(1);
    });

    test('getFamiliesByPerson возвращает семьи с участием человека', () async {
      // Arrange
      final models = [
        FamilyModel(
          id: familyId,
          treeId: treeId,
          husbandId: husbandId,
          wifeId: wifeId,
          childrenIds: '',
          marriageDate: null,
          divorceDate: null,
          marriagePlace: null,
          notes: null,
        ),
      ];

      when(
        () => mockDataSource.getFamiliesByPerson(husbandId, treeId: treeId),
      ).thenAnswer((_) async => models);

      // Act
      final result = await repository.getFamiliesByPerson(
        husbandId,
        treeId: treeId,
      );

      // Assert
      expect(result.length, 1);
      expect(result[0].husbandId, husbandId);
      verify(
        () => mockDataSource.getFamiliesByPerson(husbandId, treeId: treeId),
      ).called(1);
    });

    test(
      'getFamiliesAsParent возвращает семьи где человек является родителем',
      () async {
        // Arrange
        final models = [
          FamilyModel(
            id: familyId,
            treeId: treeId,
            husbandId: husbandId,
            wifeId: wifeId,
            childrenIds: 'child_1',
            marriageDate: null,
            divorceDate: null,
            marriagePlace: null,
            notes: null,
          ),
        ];

        when(
          () => mockDataSource.getFamiliesAsParent(husbandId, treeId: treeId),
        ).thenAnswer((_) async => models);

        // Act
        final result = await repository.getFamiliesAsParent(
          husbandId,
          treeId: treeId,
        );

        // Assert
        expect(result.length, 1);
        expect(result[0].husbandId, husbandId);
      },
    );

    test(
      'getFamiliesAsChild возвращает семьи где человек является ребенком',
      () async {
        // Arrange
        final childId = 'child_1';
        final models = [
          FamilyModel(
            id: familyId,
            treeId: treeId,
            husbandId: husbandId,
            wifeId: wifeId,
            childrenIds: childId,
            marriageDate: null,
            divorceDate: null,
            marriagePlace: null,
            notes: null,
          ),
        ];

        when(
          () => mockDataSource.getFamiliesAsChild(childId, treeId: treeId),
        ).thenAnswer((_) async => models);

        // Act
        final result = await repository.getFamiliesAsChild(
          childId,
          treeId: treeId,
        );

        // Assert
        expect(result.length, 1);
        expect(result[0].childrenIds, [childId]);
      },
    );

    test('addChildToFamily добавляет ребенка', () async {
      // Arrange
      when(
        () => mockDataSource.addChildToFamily(familyId, childId),
      ).thenAnswer((_) async => {});

      // Act
      await repository.addChildToFamily(familyId, childId);

      // Assert
      verify(
        () => mockDataSource.addChildToFamily(familyId, childId),
      ).called(1);
    });

    test('removeChildFromFamily удаляет ребенка', () async {
      // Arrange
      when(
        () => mockDataSource.removeChildFromFamily(familyId, childId),
      ).thenAnswer((_) async => {});

      // Act
      await repository.removeChildFromFamily(familyId, childId);

      // Assert
      verify(
        () => mockDataSource.removeChildFromFamily(familyId, childId),
      ).called(1);
    });
  });
}
