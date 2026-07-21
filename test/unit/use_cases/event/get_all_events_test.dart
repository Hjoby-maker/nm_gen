// test/unit/use_cases/event/get_all_events_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/entities/event.dart';
import 'package:nm_gen/domain/repositories/event_repository.dart';
import 'package:nm_gen/domain/use_cases/event/get_all_events.dart';
import '../../../test_utils/test_helpers.dart';
import '../../../test_utils/mocks.dart';

void main() {
  late MockEventRepository mockRepository;
  late GetAllEventsUseCase useCase;

  setUpAll(() {
    registerFallbackValue(createTestEvent());
  });

  setUp(() {
    mockRepository = MockEventRepository();
    useCase = GetAllEventsUseCase(mockRepository);
  });

  group('GetAllEventsUseCase', () {
    test('возвращает список всех событий', () async {
      // Arrange
      final events = [
        createTestEvent(id: 'e1', title: 'Событие 1'),
        createTestEvent(id: 'e2', title: 'Событие 2'),
      ];

      when(
        () => mockRepository.getAllEvents(treeId: null),
      ).thenAnswer((_) async => events);

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result.isRight(), true);
      final resultEvents = result.getOrElse(() => []);
      expect(resultEvents.length, 2);
    });

    test('возвращает пустой список если событий нет', () async {
      // Arrange
      when(
        () => mockRepository.getAllEvents(treeId: null),
      ).thenAnswer((_) async => []);

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result.isRight(), true);
      final resultEvents = result.getOrElse(() => []);
      expect(resultEvents.isEmpty, true);
    });

    test('передает treeId в репозиторий', () async {
      // Arrange
      const treeId = 't1';

      when(
        () => mockRepository.getAllEvents(treeId: treeId),
      ).thenAnswer((_) async => []);

      // Act
      await useCase.execute(treeId: treeId);

      // Assert
      verify(() => mockRepository.getAllEvents(treeId: treeId)).called(1);
    });

    test('возвращает Left с ServerFailure при ошибке репозитория', () async {
      // Arrange
      when(
        () => mockRepository.getAllEvents(treeId: null),
      ).thenThrow(Exception('Database error'));

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result.isLeft(), true);
      expect(
        result.fold((failure) => failure is ServerFailure, (_) => false),
        true,
      );
    });
  });
}
