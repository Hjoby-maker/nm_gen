// lib/domain/use_cases/event/add_event.dart
import 'package:dartz/dartz.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/entities/event.dart';
import 'package:nm_gen/domain/repositories/event_repository.dart';
import 'package:nm_gen/domain/use_cases/event/sync_event_to_person.dart';

/// Use Case: Добавление нового события
class AddEventUseCase {
  AddEventUseCase(this._repository, this._syncEventToPersonUseCase);
  final EventRepository _repository;
  final SyncEventToPersonUseCase _syncEventToPersonUseCase;

  Future<Either<Failure, Event>> execute(Event event) async {
    try {
      // Валидация
      if (event.title.isEmpty) {
        return const Left(
          ValidationFailure('Название события не может быть пустым'),
        );
      }

      if (event.personId.isEmpty) {
        return const Left(
          ValidationFailure('ID человека не может быть пустым'),
        );
      }

      final savedEvent = await _repository.addEvent(event);

      // Обратная синхронизация: если это событие рождения/смерти, дата и
      // место переносятся обратно в Person.birthDate/deathDate. Раньше
      // этого шага не было, и дата, введённая через форму события, не
      // появлялась в карточке человека.
      await _syncEventToPersonUseCase.execute(savedEvent);

      return Right(savedEvent);
    } catch (e) {
      return Left(ServerFailure('Ошибка добавления события: ${e.toString()}'));
    }
  }
}