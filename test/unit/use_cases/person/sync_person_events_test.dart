// test/unit/use_cases/person/sync_person_events_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nm_gen/domain/entities/event.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/repositories/event_repository.dart';
import 'package:nm_gen/domain/use_cases/person/sync_person_events.dart';
import '../../../test_utils/test_helpers.dart';
import '../../../test_utils/mocks.dart';

void main() {
  late MockEventRepository mockEventRepository;
  late SyncPersonEventsUseCase useCase;

  setUpAll(() {
    registerFallbackValue(createTestEvent());
    registerFallbackValue(createTestPerson());
  });

  setUp(() {
    mockEventRepository = MockEventRepository();
    useCase = SyncPersonEventsUseCase(mockEventRepository);
  });

  group('SyncPersonEventsUseCase', () {
    test('создает событие рождения, если есть дата рождения', () async {
      // Arrange
      final person = createTestPerson(
        id: 'p1',
        birthDate: DateTime(1980, 1, 1),
        birthPlace: 'Москва',
      );

      when(
        () => mockEventRepository.getEventsByPersonId(
          person.id,
          treeId: person.treeId,
        ),
      ).thenAnswer((_) async => []);

      when(
        () => mockEventRepository.addEvent(any<Event>()),
      ).thenAnswer((_) async => createTestEvent());

      // Act
      final result = await useCase.execute(person);

      // Assert
      expect(result.isRight(), true);
      verify(() => mockEventRepository.addEvent(any<Event>())).called(1);
    });

    test('создает событие смерти, если есть дата смерти', () async {
      // Arrange
      final person = createTestPerson(
        id: 'p1',
        birthDate: DateTime(1980, 1, 1),
        deathDate: DateTime(2020, 1, 1),
        deathPlace: 'СПб',
      );

      when(
        () => mockEventRepository.getEventsByPersonId(
          person.id,
          treeId: person.treeId,
        ),
      ).thenAnswer((_) async => []);

      when(
        () => mockEventRepository.addEvent(any<Event>()),
      ).thenAnswer((_) async => createTestEvent());

      // Act
      final result = await useCase.execute(person);

      // Assert
      expect(result.isRight(), true);
      verify(
        () => mockEventRepository.addEvent(any<Event>()),
      ).called(2); // birth + death
    });

    test('обновляет существующее событие рождения', () async {
      // Arrange
      final person = createTestPerson(
        id: 'p1',
        birthDate: DateTime(1980, 1, 1),
      );
      final existingEvent = createTestEvent(
        id: 'e1',
        personId: person.id,
        type: EventType.birth,
        title: 'Рождение ${person.displayName}',
      );

      when(
        () => mockEventRepository.getEventsByPersonId(
          person.id,
          treeId: person.treeId,
        ),
      ).thenAnswer((_) async => [existingEvent]);

      when(
        () => mockEventRepository.updateEvent(any<Event>()),
      ).thenAnswer((_) async => existingEvent);

      // Act
      final result = await useCase.execute(person);

      // Assert
      expect(result.isRight(), true);
      verify(() => mockEventRepository.updateEvent(any<Event>())).called(1);
    });

    test('удаляет событие рождения, если дата рождения удалена', () async {
      // Arrange
      final person = createTestPerson(
        id: 'p1',
        birthDate: null, // Дата рождения удалена
      );
      final existingEvent = createTestEvent(
        id: 'e1',
        personId: person.id,
        type: EventType.birth,
        title: 'Рождение ${person.displayName}',
      );

      when(
        () => mockEventRepository.getEventsByPersonId(
          person.id,
          treeId: person.treeId,
        ),
      ).thenAnswer((_) async => [existingEvent]);

      // Мокаем deleteEvent - он должен быть вызван
      when(
        () => mockEventRepository.deleteEvent(existingEvent.id),
      ).thenAnswer((_) async => Future<void>.value());

      // Act
      final result = await useCase.execute(person);

      // Assert
      expect(result.isRight(), true);
      // Проверяем, что deleteEvent был вызван
      verify(() => mockEventRepository.deleteEvent(existingEvent.id)).called(1);
      // Проверяем, что updateEvent НЕ был вызван
      verifyNever(() => mockEventRepository.updateEvent(any<Event>()));
      // Проверяем, что addEvent НЕ был вызван
      verifyNever(() => mockEventRepository.addEvent(any<Event>()));
    });

    test(
      'не создает событие рождения, если нет даты рождения и нет существующего события',
      () async {
        // Arrange
        final person = createTestPerson(id: 'p1', birthDate: null);

        when(
          () => mockEventRepository.getEventsByPersonId(
            person.id,
            treeId: person.treeId,
          ),
        ).thenAnswer((_) async => []);

        // Act
        final result = await useCase.execute(person);

        // Assert
        expect(result.isRight(), true);
        verifyNever(() => mockEventRepository.addEvent(any<Event>()));
        verifyNever(() => mockEventRepository.deleteEvent(any()));
        verifyNever(() => mockEventRepository.updateEvent(any<Event>()));
      },
    );

    test('возвращает Left с ServerFailure при ошибке', () async {
      // Arrange
      final person = createTestPerson(id: 'p1');

      when(
        () => mockEventRepository.getEventsByPersonId(
          person.id,
          treeId: person.treeId,
        ),
      ).thenThrow(Exception('Database error'));

      // Act
      final result = await useCase.execute(person);

      // Assert
      expect(result.isLeft(), true);
      expect(
        result.fold((failure) => failure is ServerFailure, (_) => false),
        true,
      );
    });
  });
}
