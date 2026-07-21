// test/unit/use_cases/event/get_events_by_person_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/entities/event.dart';
import 'package:nm_gen/domain/repositories/event_repository.dart';
import 'package:nm_gen/domain/use_cases/event/get_events_by_person.dart';
import '../../../test_utils/test_helpers.dart';
import '../../../test_utils/mocks.dart';

void main() {
  late MockEventRepository mockRepository;
  late GetEventsByPersonUseCase useCase;

  setUpAll(() {
    registerFallbackValue(createTestEvent());
  });

  setUp(() {
    mockRepository = MockEventRepository();
    useCase = GetEventsByPersonUseCase(mockRepository);
  });

  group('GetEventsByPersonUseCase', () {
    test('возвращает список событий для человека', () async {
      // Arrange
      const personId = 'p1';
      final events = [
        createTestEvent(id: 'e1', personId: personId, title: 'Событие 1'),
        createTestEvent(id: 'e2', personId: personId, title: 'Событие 2'),
      ];

      when(
        () => mockRepository.getEventsByPersonId(personId, treeId: null),
      ).thenAnswer((_) async => events);

      // Act
      final result = await useCase.execute(personId);

      // Assert
      expect(result.isRight(), true);
      final resultEvents = result.getOrElse(() => []);
      expect(resultEvents.length, 2);
      expect(resultEvents[0].title, 'Событие 1');
      expect(resultEvents[1].title, 'Событие 2');
    });

    test('возвращает пустой список если у человека нет событий', () async {
      // Arrange
      const personId = 'p1';

      when(
        () => mockRepository.getEventsByPersonId(personId, treeId: null),
      ).thenAnswer((_) async => []);

      // Act
      final result = await useCase.execute(personId);

      // Assert
      expect(result.isRight(), true);
      final resultEvents = result.getOrElse(() => []);
      expect(resultEvents.isEmpty, true);
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
      verifyNever(
        () => mockRepository.getEventsByPersonId(
          any(),
          treeId: any(named: 'treeId'),
        ),
      );
    });

    test('передает treeId в репозиторий', () async {
      // Arrange
      const personId = 'p1';
      const treeId = 't1';

      when(
        () => mockRepository.getEventsByPersonId(personId, treeId: treeId),
      ).thenAnswer((_) async => []);

      // Act
      await useCase.execute(personId, treeId: treeId);

      // Assert
      verify(
        () => mockRepository.getEventsByPersonId(personId, treeId: treeId),
      ).called(1);
    });

    test('возвращает Left с ServerFailure при ошибке репозитория', () async {
      // Arrange
      const personId = 'p1';

      when(
        () => mockRepository.getEventsByPersonId(personId, treeId: null),
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
