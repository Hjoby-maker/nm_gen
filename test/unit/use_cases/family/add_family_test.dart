// test/unit/use_cases/family/add_family_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/entities/family.dart';
import 'package:nm_gen/domain/repositories/family_repository.dart';
import 'package:nm_gen/domain/use_cases/family/add_family.dart';
import '../../../test_utils/mocks.dart';

void main() {
  late MockFamilyRepository mockRepository;
  late AddFamilyUseCase useCase;

  setUp(() {
    mockRepository = MockFamilyRepository();
    useCase = AddFamilyUseCase(mockRepository);

    // Регистрируем fallback значение для Family
    registerFallbackValue(
      Family(
        id: 'fallback',
        treeId: 'fallback',
        husbandId: null,
        wifeId: null,
        childrenIds: [],
      ),
    );
  });

  group('AddFamilyUseCase', () {
    test('успешно добавляет семью с двумя родителями', () async {
      // Arrange
      final family = Family(
        id: 'f1',
        treeId: 'tree_1',
        husbandId: 'p1',
        wifeId: 'p2',
        childrenIds: [],
      );

      when(
        () => mockRepository.addFamily(any()),
      ).thenAnswer((_) async => family);

      // Act
      final result = await useCase.execute(family);

      // Assert
      expect(result.isRight(), true);
      final resultFamily = result.getOrElse(() => Family.empty());
      expect(resultFamily.id, 'f1');
      expect(resultFamily.husbandId, 'p1');
      expect(resultFamily.wifeId, 'p2');
      verify(() => mockRepository.addFamily(any())).called(1);
    });

    test('успешно добавляет семью с одним родителем', () async {
      // Arrange
      final family = Family(
        id: 'f1',
        treeId: 'tree_1',
        husbandId: 'p1',
        wifeId: null,
        childrenIds: [],
      );

      when(
        () => mockRepository.addFamily(any()),
      ).thenAnswer((_) async => family);

      // Act
      final result = await useCase.execute(family);

      // Assert
      expect(result.isRight(), true);
      final resultFamily = result.getOrElse(() => Family.empty());
      expect(resultFamily.id, 'f1');
      expect(resultFamily.husbandId, 'p1');
      expect(resultFamily.wifeId, null);
    });

    test('возвращает Left с ValidationFailure если нет родителей', () async {
      // Arrange
      final family = Family(
        id: 'f1',
        treeId: 'tree_1',
        husbandId: null,
        wifeId: null,
        childrenIds: [],
      );

      // Act
      final result = await useCase.execute(family);

      // Assert
      expect(result.isLeft(), true);
      expect(
        result.fold(
          (failure) =>
              failure is ValidationFailure &&
              failure.message.contains('хотя бы один родитель'),
          (_) => false,
        ),
        true,
      );
      verifyNever(() => mockRepository.addFamily(any()));
    });

    test('устанавливает treeId по умолчанию если его нет', () async {
      // Arrange
      final family = Family(
        id: 'f1',
        treeId: '',
        husbandId: 'p1',
        wifeId: 'p2',
        childrenIds: [],
      );
      final expectedFamily = family.copyWith(treeId: 'default');

      when(
        () => mockRepository.addFamily(any()),
      ).thenAnswer((_) async => expectedFamily);

      // Act
      final result = await useCase.execute(family);

      // Assert
      expect(result.isRight(), true);
      final resultFamily = result.getOrElse(() => Family.empty());
      expect(resultFamily.treeId, 'default');
    });

    test('сохраняет переданный treeId если он есть', () async {
      // Arrange
      const treeId = 'custom_tree';
      final family = Family(
        id: 'f1',
        treeId: treeId,
        husbandId: 'p1',
        wifeId: 'p2',
        childrenIds: [],
      );
      final expectedFamily = family.copyWith(treeId: treeId);

      when(
        () => mockRepository.addFamily(any()),
      ).thenAnswer((_) async => expectedFamily);

      // Act
      final result = await useCase.execute(family, treeId: treeId);

      // Assert
      expect(result.isRight(), true);
      final resultFamily = result.getOrElse(() => Family.empty());
      expect(resultFamily.treeId, treeId);
    });

    test('возвращает Left с ServerFailure при ошибке репозитория', () async {
      // Arrange
      final family = Family(
        id: 'f1',
        treeId: 'tree_1',
        husbandId: 'p1',
        wifeId: 'p2',
        childrenIds: [],
      );

      when(
        () => mockRepository.addFamily(any()),
      ).thenThrow(Exception('Database error'));

      // Act
      final result = await useCase.execute(family);

      // Assert
      expect(result.isLeft(), true);
      expect(
        result.fold((failure) => failure is ServerFailure, (_) => false),
        true,
      );
    });
  });
}
