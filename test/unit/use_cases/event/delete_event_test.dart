// test/unit/use_cases/event/delete_event_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/entities/event.dart';
import 'package:nm_gen/domain/repositories/event_repository.dart';
import 'package:nm_gen/domain/use_cases/event/delete_event.dart';
import '../../../test_utils/test_helpers.dart';
import '../../../test_utils/mocks.dart';

void main() {
  late MockEventRepository mockRepository;
  late DeleteEventUseCase useCase;

  setUpAll(() {
    registerFallbackValue(createTestEvent());
  });

  setUp(() {
    mockRepository = MockEventRepository();
    useCase = DeleteEventUseCase(mockRepository);
  });

  group('DeleteEventUseCase', () {
    test('успешно удаляет событие и возвращает его', () async {
      // Arrange
      const eventId = 'e1';
      final event = createTestEvent(id: eventId, title: 'Тестовое событие');

      when(
        () => mockRepository.getEvent(eventId),
      ).thenAnswer((_) async => event);
      when(
        () => mockRepository.deleteEvent(eventId),
      ).thenAnswer((_) async => {});

      // Act
      final result = await useCase.execute(eventId);

      // Assert
      expect(result.isRight(), true);
      final deletedEvent = result.getOrElse(() => throw Exception());
      expect(deletedEvent?.id, eventId);
      verify(() => mockRepository.getEvent(eventId)).called(1);
      verify(() => mockRepository.deleteEvent(eventId)).called(1);
    });

    test('возвращает Right с null если событие не найдено', () async {
      // Arrange
      const eventId = 'nonexistent';

      when(
        () => mockRepository.getEvent(eventId),
      ).thenAnswer((_) async => null);
      when(
        () => mockRepository.deleteEvent(eventId),
      ).thenAnswer((_) async => {});

      // Act
      final result = await useCase.execute(eventId);

      // Assert
      expect(result.isRight(), true);
      final deletedEvent = result.getOrElse(() => throw Exception());
      expect(deletedEvent, null);
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
              failure.message.contains('ID события не может быть пустым'),
          (_) => false,
        ),
        true,
      );
      verifyNever(() => mockRepository.getEvent(any()));
      verifyNever(() => mockRepository.deleteEvent(any()));
    });

    test('возвращает Left с ServerFailure при ошибке репозитория', () async {
      // Arrange
      const eventId = 'e1';

      when(
        () => mockRepository.getEvent(eventId),
      ).thenThrow(Exception('Database error'));

      // Act
      final result = await useCase.execute(eventId);

      // Assert
      expect(result.isLeft(), true);
      expect(
        result.fold((failure) => failure is ServerFailure, (_) => false),
        true,
      );
    });
  });
}
