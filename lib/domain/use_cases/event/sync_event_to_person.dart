// lib/domain/use_cases/event/sync_event_to_person.dart
import 'package:nm_gen/domain/entities/event.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/repositories/person_repository.dart';

/// Use Case: обратная синхронизация "событие -> человек" для рождения и
/// смерти.
///
/// Это зеркало SyncPersonEventsUseCase (lib/domain/use_cases/person/
/// sync_person_events.dart), который поддерживает событие birth/death в
/// актуальном состоянии, когда меняется person.birthDate/deathDate.
/// Раньше обратного пути не было вообще: если создать/отредактировать
/// событие "Рождение" напрямую через форму события, Person.birthDate не
/// обновлялся, и дата не появлялась в карточке человека.
///
/// Пишет в Person напрямую через PersonRepository.updatePerson, а НЕ через
/// UpdatePersonUseCase - иначе UpdatePersonUseCase снова вызвал бы
/// SyncPersonEventsUseCase и сделал бы лишний повторный write того же
/// события, которое мы только что сами сохранили (не зацикливание, но
/// бессмысленная двойная работа на каждое сохранение).
class SyncEventToPersonUseCase {
  SyncEventToPersonUseCase(this._personRepository);
  final PersonRepository _personRepository;

  /// Вызывается после успешного добавления/обновления события birth/death.
  /// Для остальных типов событий ничего не делает.
  Future<void> execute(Event event) async {
    if (event.type != EventType.birth && event.type != EventType.death) {
      return;
    }

    try {
      final Person? person = await _personRepository.getPerson(
        event.personId,
      );
      if (person == null) return;

      final Person updatedPerson = event.type == EventType.birth
          ? person.copyWith(
              birthDate: event.startDate,
              birthPlace: event.place,
            )
          : person.copyWith(
              deathDate: event.startDate,
              deathPlace: event.place,
            );

      await _personRepository.updatePerson(updatedPerson);
    } catch (e) {
      // Событие уже сохранено к этому моменту - синхронизация с человеком
      // не должна ронять основную операцию. Логируем и продолжаем,
      // аналогично поведению SyncPersonEventsUseCase.
      print('⚠️ Ошибка синхронизации события в карточку человека: $e');
    }
  }

  /// Вызывается после удаления события birth/death. Если удалили именно
  /// то событие, из которого была взята дата рождения/смерти человека,
  /// саму дату у человека тоже нужно очистить - иначе в карточке останется
  /// "призрачная" дата без соответствующего события.
  Future<void> executeOnDelete(Event deletedEvent) async {
    if (deletedEvent.type != EventType.birth &&
        deletedEvent.type != EventType.death) {
      return;
    }

    try {
      final Person? person = await _personRepository.getPerson(
        deletedEvent.personId,
      );
      if (person == null) return;

      // ⚠️ Person.copyWith не умеет сбрасывать поле в null (стандартный
      // паттерн `value ?? this.value` в copyWith этого физически не
      // позволяет) - поэтому здесь нужен прямой конструктор Person с
      // явным null для очищаемых полей, а не copyWith.
      final Person updatedPerson = deletedEvent.type == EventType.birth
          ? Person(
              id: person.id,
              treeId: person.treeId,
              firstName: person.firstName,
              lastName: person.lastName,
              middleName: person.middleName,
              gender: person.gender,
              birthDate: null,
              deathDate: person.deathDate,
              birthPlace: null,
              deathPlace: person.deathPlace,
              occupation: person.occupation,
              biography: person.biography,
              photoUrls: person.photoUrls,
              photoPath: person.photoPath,
              createdAt: person.createdAt,
              updatedAt: DateTime.now(),
            )
          : Person(
              id: person.id,
              treeId: person.treeId,
              firstName: person.firstName,
              lastName: person.lastName,
              middleName: person.middleName,
              gender: person.gender,
              birthDate: person.birthDate,
              deathDate: null,
              birthPlace: person.birthPlace,
              deathPlace: null,
              occupation: person.occupation,
              biography: person.biography,
              photoUrls: person.photoUrls,
              photoPath: person.photoPath,
              createdAt: person.createdAt,
              updatedAt: DateTime.now(),
            );

      await _personRepository.updatePerson(updatedPerson);
    } catch (e) {
      print('⚠️ Ошибка очистки даты человека после удаления события: $e');
    }
  }
}