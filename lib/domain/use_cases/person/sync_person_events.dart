// lib/domain/use_cases/person/sync_person_events.dart
import 'package:dartz/dartz.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/entities/event.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/repositories/event_repository.dart';

/// Use Case: Синхронизация автоматических событий человека (рождение, смерть)
class SyncPersonEventsUseCase {
  SyncPersonEventsUseCase(this._eventRepository);
  final EventRepository _eventRepository;

  /// Синхронизировать события рождения и смерти с данными человека
  Future<Either<Failure, void>> execute(Person person) async {
    try {
      // Получаем все существующие события человека
      final existingEvents = await _eventRepository.getEventsByPersonId(
        person.id,
        treeId: person.treeId,
      );

      // Синхронизируем событие рождения
      await _syncBirthEvent(person, existingEvents);

      // Синхронизируем событие смерти
      await _syncDeathEvent(person, existingEvents);

      return const Right(null);
    } catch (e) {
      return Left(
        ServerFailure('Ошибка синхронизации событий: ${e.toString()}'),
      );
    }
  }

  /// Синхронизация события рождения
  Future<void> _syncBirthEvent(
    Person person,
    List<Event> existingEvents,
  ) async {
    final birthEvent = existingEvents.firstWhere(
      (e) => e.type == EventType.birth,
      orElse: () => Event(
        id: '',
        personId: person.id,
        treeId: person.treeId,
        type: EventType.birth,
        title: 'Рождение ${person.displayName}',
      ),
    );

    if (person.birthDate != null) {
      // Если есть дата рождения — создаем или обновляем событие.
      //
      // ⚠️ РАНЬШЕ здесь new-событие сохранялось с id: '' (сентинел из
      // orElse выше просто пролетал через copyWith, который id не
      // трогает). Для первого человека это проходило (INSERT ... id='' -
      // одна такая строка допустима), а для любого следующего человека,
      // которому тоже требовалось новое событие рождения, падало с
      // "UNIQUE constraint failed: events.id", т.к. '' уже была занята.
      // Комбинация timestamp+personId+тип события гарантированно уникальна
      // даже при массовом импорте, когда события создаются в цикле подряд.
      final bool isNewEvent = birthEvent.id.isEmpty;
      final String eventId = isNewEvent
          ? '${DateTime.now().millisecondsSinceEpoch}_${person.id}_birth'
          : birthEvent.id;

      final updatedEvent = birthEvent.copyWith(
        id: eventId,
        personId: person.id,
        treeId: person.treeId,
        type: EventType.birth,
        title: 'Рождение ${person.displayName}',
        startDate: person.birthDate,
        place: person.birthPlace,
        updatedAt: DateTime.now(),
      );

      if (isNewEvent) {
        // Создаем новое событие
        try {
          await _eventRepository.addEvent(updatedEvent);
        } catch (e) {
          // Если ошибка, просто логируем и продолжаем
          print('⚠️ Ошибка создания события рождения: $e');
        }
      } else {
        // Обновляем существующее
        try {
          await _eventRepository.updateEvent(updatedEvent);
        } catch (e) {
          // Если ошибка, просто логируем и продолжаем
          print('⚠️ Ошибка обновления события рождения: $e');
        }
      }
    } else {
      // Если даты рождения нет — удаляем событие
      if (birthEvent.id.isNotEmpty) {
        try {
          await _eventRepository.deleteEvent(birthEvent.id);
        } catch (e) {
          // Если ошибка, просто логируем и продолжаем
          print('⚠️ Ошибка удаления события рождения: $e');
        }
      }
    }
  }

  /// Синхронизация события смерти
  Future<void> _syncDeathEvent(
    Person person,
    List<Event> existingEvents,
  ) async {
    final deathEvent = existingEvents.firstWhere(
      (e) => e.type == EventType.death,
      orElse: () => Event(
        id: '',
        personId: person.id,
        treeId: person.treeId,
        type: EventType.death,
        title: 'Смерть ${person.displayName}',
      ),
    );

    if (person.deathDate != null) {
      // Если есть дата смерти — создаем или обновляем событие (та же
      // причина генерировать настоящий id для нового события, что и в
      // _syncBirthEvent выше - см. комментарий там).
      final bool isNewEvent = deathEvent.id.isEmpty;
      final String eventId = isNewEvent
          ? '${DateTime.now().millisecondsSinceEpoch}_${person.id}_death'
          : deathEvent.id;

      final updatedEvent = deathEvent.copyWith(
        id: eventId,
        personId: person.id,
        treeId: person.treeId,
        type: EventType.death,
        title: 'Смерть ${person.displayName}',
        startDate: person.deathDate,
        place: person.deathPlace,
        updatedAt: DateTime.now(),
      );

      if (isNewEvent) {
        // Создаем новое событие
        try {
          await _eventRepository.addEvent(updatedEvent);
        } catch (e) {
          // Если ошибка, просто логируем и продолжаем
          print('⚠️ Ошибка создания события смерти: $e');
        }
      } else {
        // Обновляем существующее
        try {
          await _eventRepository.updateEvent(updatedEvent);
        } catch (e) {
          // Если ошибка, просто логируем и продолжаем
          print('⚠️ Ошибка обновления события смерти: $e');
        }
      }
    } else {
      // Если даты смерти нет — удаляем событие
      if (deathEvent.id.isNotEmpty) {
        try {
          await _eventRepository.deleteEvent(deathEvent.id);
        } catch (e) {
          // Если ошибка, просто логируем и продолжаем
          print('⚠️ Ошибка удаления события смерти: $e');
        }
      }
    }
  }
}