// test/unit/use_cases/event/update_event_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/entities/event.dart';
import 'package:nm_gen/domain/repositories/event_repository.dart';
import 'package:nm_gen/domain/use_cases/event/update_event.dart';
import '../../../test_utils/test_helpers.dart';
import '../../../test_utils/mocks.dart';

void main() {
  late MockEventRepository mockRepository;
  late UpdateEventUseCase useCase;

  setUpAll(() {
    registerFallbackValue(createTestEvent());
  });

  setUp(() {
    mockRepository = MockEventRepository();
    useCase = UpdateEventUseCase(mockRepository);
  });

  group('UpdateEventUseCase', () {
    test('успешно обновляет событие с корректными данными', () async {
      // Arrange
      final event = createTestEvent(id: 'e1', title: 'Старое название');
      final updatedEvent = event.copyWith(title: 'Новое название');

      when(
        () => mockRepository.updateEvent(any<Event>()),
      ).thenAnswer((_) async => updatedEvent);

      // Act
      final result = await useCase.execute(updatedEvent);

      // Assert
      expect(result.isRight(), true);
      final savedEvent = result.getOrElse(() => throw Exception());
      expect(savedEvent.title, 'Новое название');
      verify(() => mockRepository.updateEvent(any<Event>())).called(1);
    });

    test('возвращает Left с ValidationFailure при пустом ID', () async {
      // Arrange
      final event = createTestEvent(id: '');

      // Act
      final result = await useCase.execute(event);

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
      verifyNever(() => mockRepository.updateEvent(any<Event>()));
    });

    test('возвращает Left с ValidationFailure при пустом названии', () async {
      // Arrange
      final event = createTestEvent(id: 'e1', title: '');

      // Act
      final result = await useCase.execute(event);

      // Assert
      expect(result.isLeft(), true);
      expect(
        result.fold(
          (failure) =>
              failure is ValidationFailure &&
              failure.message.contains('Название события не может быть пустым'),
          (_) => false,
        ),
        true,
      );
      verifyNever(() => mockRepository.updateEvent(any<Event>()));
    });

    test('возвращает Left с ServerFailure при ошибке репозитория', () async {
      // Arrange
      final event = createTestEvent(id: 'e1', title: 'Тест');

      when(
        () => mockRepository.updateEvent(any<Event>()),
      ).thenThrow(Exception('Database error'));

      // Act
      final result = await useCase.execute(event);

      // Assert
      expect(result.isLeft(), true);
      expect(
        result.fold((failure) => failure is ServerFailure, (_) => false),
        true,
      );
    });
  });
}
