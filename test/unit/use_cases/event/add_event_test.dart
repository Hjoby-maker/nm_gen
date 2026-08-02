// test/unit/use_cases/event/add_event_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/entities/event.dart';
import 'package:nm_gen/domain/repositories/event_repository.dart';
import 'package:nm_gen/domain/use_cases/event/add_event.dart';
import 'package:nm_gen/domain/use_cases/event/sync_event_to_person.dart';
import '../../../test_utils/test_helpers.dart';
import '../../../test_utils/mocks.dart';

/// ⚠️ AddEventUseCase теперь принимает второй параметр -
/// SyncEventToPersonUseCase (обратная синхронизация "событие -> человек"
/// для событий рождения/смерти). Мок объявлен прямо здесь, а не в
/// ../../../test_utils/mocks.dart, чтобы не трогать общий файл моков
/// вслепую - если у вас там уже есть общий MockSyncEventToPersonUseCase,
/// смело удалите этот локальный класс и используйте общий.
class MockSyncEventToPersonUseCase extends Mock
    implements SyncEventToPersonUseCase {}

void main() {
  late MockEventRepository mockRepository;
  late MockSyncEventToPersonUseCase mockSyncEventToPerson;
  late AddEventUseCase useCase;

  setUpAll(() {
    registerFallbackValue(createTestEvent());
  });

  setUp(() {
    mockRepository = MockEventRepository();
    mockSyncEventToPerson = MockSyncEventToPersonUseCase();
    useCase = AddEventUseCase(mockRepository, mockSyncEventToPerson);

    // По умолчанию синхронизация с человеком просто ничего не делает -
    // конкретные тесты переопределяют это через verify(), если нужно
    // проверить сам факт вызова.
    when(
      () => mockSyncEventToPerson.execute(any<Event>()),
    ).thenAnswer((_) async {});
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

    test(
      'после успешного добавления вызывает синхронизацию с человеком '
      '(SyncEventToPersonUseCase.execute) с сохранённым событием',
      () async {
        // Arrange
        final event = createTestEvent(
          id: 'e1',
          personId: 'p1',
          treeId: 't1',
          title: 'Рождение',
          startDate: DateTime(1980, 1, 1),
        );

        when(
          () => mockRepository.addEvent(any<Event>()),
        ).thenAnswer((_) async => event);

        // Act
        await useCase.execute(event);

        // Assert
        final captured = verify(
          () => mockSyncEventToPerson.execute(captureAny<Event>()),
        ).captured;
        expect(captured, hasLength(1));
        expect((captured.first as Event).id, 'e1');
      },
    );

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
      verifyNever(() => mockSyncEventToPerson.execute(any<Event>()));
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
      verifyNever(() => mockSyncEventToPerson.execute(any<Event>()));
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
      verifyNever(() => mockSyncEventToPerson.execute(any<Event>()));
    });
  });
}