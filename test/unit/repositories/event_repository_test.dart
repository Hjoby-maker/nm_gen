// test/unit/repositories/event_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nm_gen/data/datasources/local/database/event_model.dart';
import 'package:nm_gen/data/datasources/local/event_local_datasource.dart';
import 'package:nm_gen/data/repositories/event_repository_impl.dart';
import 'package:nm_gen/domain/entities/event.dart';
import '../../test_utils/test_helpers.dart';
import '../../test_utils/mocks.dart';

void main() {
  late MockEventLocalDataSource mockDataSource;
  late EventRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockEventLocalDataSource();
    repository = EventRepositoryImpl(mockDataSource);

    registerFallbackValue(
      EventModel(
        id: 'fallback',
        personId: 'fallback',
        treeId: 'fallback',
        type: 'birth',
        title: 'fallback',
      ),
    );
  });

  group('EventRepository', () {
    const eventId = 'e1';
    const personId = 'p1';
    const treeId = 't1';

    test('addEvent добавляет новое событие', () async {
      // Arrange
      final event = createTestEvent(
        id: eventId,
        personId: personId,
        treeId: treeId,
        title: 'Тестовое событие',
      );
      final model = EventModel.fromDomain(event);

      when(
        () => mockDataSource.insertEvent(any()),
      ).thenAnswer((_) async => model);

      // Act
      final result = await repository.addEvent(event);

      // Assert
      expect(result.id, eventId);
      expect(result.title, 'Тестовое событие');
      verify(() => mockDataSource.insertEvent(any())).called(1);
    });

    test('getEvent возвращает событие по ID', () async {
      // Arrange
      final event = createTestEvent(id: eventId, title: 'Тестовое событие');
      final model = EventModel.fromDomain(event);

      when(
        () => mockDataSource.getEvent(eventId),
      ).thenAnswer((_) async => model);

      // Act
      final result = await repository.getEvent(eventId);

      // Assert
      expect(result, isNotNull);
      expect(result!.id, eventId);
      expect(result.title, 'Тестовое событие');
    });

    test('getEvent возвращает null если событие не найдено', () async {
      // Arrange
      when(
        () => mockDataSource.getEvent('nonexistent'),
      ).thenAnswer((_) async => null);

      // Act
      final result = await repository.getEvent('nonexistent');

      // Assert
      expect(result, null);
    });

    test('getEventsByPersonId возвращает список событий человека', () async {
      // Arrange
      final events = [
        createTestEvent(id: 'e1', personId: personId, title: 'Событие 1'),
        createTestEvent(id: 'e2', personId: personId, title: 'Событие 2'),
      ];
      final models = events.map(EventModel.fromDomain).toList();

      when(
        () => mockDataSource.getEventsByPersonId(personId, treeId: treeId),
      ).thenAnswer((_) async => models);

      // Act
      final result = await repository.getEventsByPersonId(
        personId,
        treeId: treeId,
      );

      // Assert
      expect(result.length, 2);
      expect(result[0].title, 'Событие 1');
      expect(result[1].title, 'Событие 2');
    });

    test('getAllEvents возвращает список всех событий', () async {
      // Arrange
      final events = [
        createTestEvent(id: 'e1', title: 'Событие 1'),
        createTestEvent(id: 'e2', title: 'Событие 2'),
      ];
      final models = events.map(EventModel.fromDomain).toList();

      when(
        () => mockDataSource.getAllEvents(treeId: treeId),
      ).thenAnswer((_) async => models);

      // Act
      final result = await repository.getAllEvents(treeId: treeId);

      // Assert
      expect(result.length, 2);
    });

    test('updateEvent обновляет событие', () async {
      // Arrange
      final event = createTestEvent(id: eventId, title: 'Старое название');
      final updatedEvent = event.copyWith(title: 'Новое название');
      final model = EventModel.fromDomain(updatedEvent);

      when(
        () => mockDataSource.updateEvent(any()),
      ).thenAnswer((_) async => model);

      // Act
      final result = await repository.updateEvent(updatedEvent);

      // Assert
      expect(result.title, 'Новое название');
      verify(() => mockDataSource.updateEvent(any())).called(1);
    });

    test('deleteEvent удаляет событие', () async {
      // Arrange
      when(
        () => mockDataSource.deleteEvent(eventId),
      ).thenAnswer((_) async => {});

      // Act
      await repository.deleteEvent(eventId);

      // Assert
      verify(() => mockDataSource.deleteEvent(eventId)).called(1);
    });

    test('deleteEventsByPersonId удаляет все события человека', () async {
      // Arrange
      when(
        () => mockDataSource.deleteEventsByPersonId(personId, treeId: treeId),
      ).thenAnswer((_) async => {});

      // Act
      await repository.deleteEventsByPersonId(personId, treeId: treeId);

      // Assert
      verify(
        () => mockDataSource.deleteEventsByPersonId(personId, treeId: treeId),
      ).called(1);
    });

    test('getEventsCountForPerson возвращает количество событий', () async {
      // Arrange
      when(
        () => mockDataSource.getEventsCountForPerson(personId, treeId: treeId),
      ).thenAnswer((_) async => 5);

      // Act
      final result = await repository.getEventsCountForPerson(
        personId,
        treeId: treeId,
      );

      // Assert
      expect(result, 5);
    });
  });
}
