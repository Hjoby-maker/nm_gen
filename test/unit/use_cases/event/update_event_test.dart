// test/unit/use_cases/event/update_event_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/entities/event.dart';
import 'package:nm_gen/domain/repositories/event_repository.dart';
import 'package:nm_gen/domain/use_cases/event/update_event.dart';
import 'package:nm_gen/domain/use_cases/event/sync_event_to_person.dart';
import '../../../test_utils/test_helpers.dart';
import '../../../test_utils/mocks.dart';

/// ⚠️ UpdateEventUseCase теперь принимает второй параметр -
/// SyncEventToPersonUseCase (обратная синхронизация "событие -> человек"
/// для событий рождения/смерти). Мок объявлен прямо здесь, а не в
/// ../../../test_utils/mocks.dart - если у вас там уже есть общий
/// MockSyncEventToPersonUseCase (например, добавленный вместе с
/// add_event_test.dart), удалите дубликат и используйте общий.
class MockSyncEventToPersonUseCase extends Mock
    implements SyncEventToPersonUseCase {}

void main() {
  late MockEventRepository mockRepository;
  late MockSyncEventToPersonUseCase mockSyncEventToPerson;
  late UpdateEventUseCase useCase;

  setUpAll(() {
    registerFallbackValue(createTestEvent());
  });

  setUp(() {
    mockRepository = MockEventRepository();
    mockSyncEventToPerson = MockSyncEventToPersonUseCase();
    useCase = UpdateEventUseCase(mockRepository, mockSyncEventToPerson);

    when(
      () => mockSyncEventToPerson.execute(any<Event>()),
    ).thenAnswer((_) async {});
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

    test(
      'после успешного обновления вызывает синхронизацию с человеком '
      '(SyncEventToPersonUseCase.execute) с обновлённым событием',
      () async {
        // Arrange
        final event = createTestEvent(id: 'e1', title: 'Старое название');
        final updatedEvent = event.copyWith(title: 'Новое название');

        when(
          () => mockRepository.updateEvent(any<Event>()),
        ).thenAnswer((_) async => updatedEvent);

        // Act
        await useCase.execute(updatedEvent);

        // Assert
        final captured = verify(
          () => mockSyncEventToPerson.execute(captureAny<Event>()),
        ).captured;
        expect(captured, hasLength(1));
        expect((captured.first as Event).title, 'Новое название');
      },
    );

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
      verifyNever(() => mockSyncEventToPerson.execute(any<Event>()));
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
      verifyNever(() => mockSyncEventToPerson.execute(any<Event>()));
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
      verifyNever(() => mockSyncEventToPerson.execute(any<Event>()));
    });
  });
}