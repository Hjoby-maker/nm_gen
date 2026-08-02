// test/unit/use_cases/event/delete_event_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/entities/event.dart';
import 'package:nm_gen/domain/repositories/event_repository.dart';
import 'package:nm_gen/domain/use_cases/event/delete_event.dart';
import 'package:nm_gen/domain/use_cases/event/sync_event_to_person.dart';
import '../../../test_utils/test_helpers.dart';
import '../../../test_utils/mocks.dart';

/// ⚠️ DeleteEventUseCase теперь принимает второй параметр -
/// SyncEventToPersonUseCase (обратная синхронизация "событие -> человек").
/// Для удаления используется отдельный метод executeOnDelete, а не
/// execute() - см. sync_event_to_person.dart. Мок объявлен прямо здесь -
/// если у вас уже есть общий MockSyncEventToPersonUseCase в
/// test_utils/mocks.dart, удалите дубликат.
class MockSyncEventToPersonUseCase extends Mock
    implements SyncEventToPersonUseCase {}

void main() {
  late MockEventRepository mockRepository;
  late MockSyncEventToPersonUseCase mockSyncEventToPerson;
  late DeleteEventUseCase useCase;

  setUpAll(() {
    registerFallbackValue(createTestEvent());
  });

  setUp(() {
    mockRepository = MockEventRepository();
    mockSyncEventToPerson = MockSyncEventToPersonUseCase();
    useCase = DeleteEventUseCase(mockRepository, mockSyncEventToPerson);

    when(
      () => mockSyncEventToPerson.executeOnDelete(any<Event>()),
    ).thenAnswer((_) async {});
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

    test(
      'после удаления существующего события вызывает '
      'SyncEventToPersonUseCase.executeOnDelete с этим событием',
      () async {
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
        await useCase.execute(eventId);

        // Assert
        final captured = verify(
          () => mockSyncEventToPerson.executeOnDelete(captureAny<Event>()),
        ).captured;
        expect(captured, hasLength(1));
        expect((captured.first as Event).id, eventId);
      },
    );

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

    test(
      'НЕ вызывает синхронизацию с человеком, если событие не найдено '
      '(нечего синхронизировать - объекта события просто нет)',
      () async {
        // Arrange
        const eventId = 'nonexistent';

        when(
          () => mockRepository.getEvent(eventId),
        ).thenAnswer((_) async => null);
        when(
          () => mockRepository.deleteEvent(eventId),
        ).thenAnswer((_) async => {});

        // Act
        await useCase.execute(eventId);

        // Assert
        verifyNever(
          () => mockSyncEventToPerson.executeOnDelete(any<Event>()),
        );
      },
    );

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
      verifyNever(() => mockSyncEventToPerson.executeOnDelete(any<Event>()));
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
      verifyNever(() => mockSyncEventToPerson.executeOnDelete(any<Event>()));
    });
  });
}