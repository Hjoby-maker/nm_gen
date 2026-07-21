// test/unit/use_cases/event/add_event_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/entities/event.dart';
import 'package:nm_gen/domain/repositories/event_repository.dart';
import 'package:nm_gen/domain/use_cases/event/add_event.dart';
import '../../../test_utils/test_helpers.dart';
import '../../../test_utils/mocks.dart';

void main() {
  late MockEventRepository mockRepository;
  late AddEventUseCase useCase;

  setUpAll(() {
    registerFallbackValue(createTestEvent());
  });

  setUp(() {
    mockRepository = MockEventRepository();
    useCase = AddEventUseCase(mockRepository);
  });

  group('AddEventUseCase', () {
    test('успешно добавляет событие с корректными данными', () async {
      // Arrange
      final event = createTestEvent(
        id: 'e1',
        personId: 'p1',
        treeId: 't1',
        title: 'Тестовое событие',
        startDate: DateTime(1980, 1, 1),
      );

      when(
        () => mockRepository.addEvent(any<Event>()),
      ).thenAnswer((_) async => event);

      // Act
      final result = await useCase.execute(event);

      // Assert
      expect(result.isRight(), true);
      final savedEvent = result.getOrElse(() => throw Exception());
      expect(savedEvent.id, 'e1');
      expect(savedEvent.title, 'Тестовое событие');
      verify(() => mockRepository.addEvent(any<Event>())).called(1);
    });

    test('возвращает Left с ValidationFailure при пустом названии', () async {
      // Arrange
      final event = createTestEvent(title: '');

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
      verifyNever(() => mockRepository.addEvent(any<Event>()));
    });

    test('возвращает Left с ValidationFailure при пустом personId', () async {
      // Arrange
      final event = createTestEvent(personId: '');

      // Act
      final result = await useCase.execute(event);

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
      verifyNever(() => mockRepository.addEvent(any<Event>()));
    });

    test('возвращает Left с ServerFailure при ошибке репозитория', () async {
      // Arrange
      final event = createTestEvent(title: 'Тест');

      when(
        () => mockRepository.addEvent(any<Event>()),
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
