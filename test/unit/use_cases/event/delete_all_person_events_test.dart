// test/unit/use_cases/event/delete_all_person_events_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/repositories/event_repository.dart';
import 'package:nm_gen/domain/use_cases/event/delete_all_person_events.dart';
import '../../../test_utils/mocks.dart';

void main() {
  late MockEventRepository mockRepository;
  late DeleteAllPersonEventsUseCase useCase;

  setUp(() {
    mockRepository = MockEventRepository();
    useCase = DeleteAllPersonEventsUseCase(mockRepository);
  });

  group('DeleteAllPersonEventsUseCase', () {
    test('успешно удаляет все события человека', () async {
      // Arrange
      const personId = 'p1';
      const treeId = 't1';

      when(
        () => mockRepository.deleteEventsByPersonId(personId, treeId: treeId),
      ).thenAnswer((_) async => {});

      // Act
      final result = await useCase.execute(personId, treeId: treeId);

      // Assert
      expect(result.isRight(), true);
      verify(
        () => mockRepository.deleteEventsByPersonId(personId, treeId: treeId),
      ).called(1);
    });

    test('возвращает Left с ValidationFailure при пустом personId', () async {
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
        () => mockRepository.deleteEventsByPersonId(
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
        () => mockRepository.deleteEventsByPersonId(personId, treeId: treeId),
      ).thenAnswer((_) async => {});

      // Act
      await useCase.execute(personId, treeId: treeId);

      // Assert
      verify(
        () => mockRepository.deleteEventsByPersonId(personId, treeId: treeId),
      ).called(1);
    });

    test('возвращает Left с ServerFailure при ошибке репозитория', () async {
      // Arrange
      const personId = 'p1';

      when(
        () => mockRepository.deleteEventsByPersonId(personId, treeId: null),
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
