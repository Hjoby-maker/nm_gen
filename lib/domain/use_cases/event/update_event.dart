// lib/domain/use_cases/event/update_event.dart
import 'package:dartz/dartz.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/entities/event.dart';
import 'package:nm_gen/domain/repositories/event_repository.dart';
import 'package:nm_gen/domain/use_cases/event/sync_event_to_person.dart';

/// Use Case: Обновление события
class UpdateEventUseCase {
  UpdateEventUseCase(this._repository, this._syncEventToPersonUseCase);
  final EventRepository _repository;
  final SyncEventToPersonUseCase _syncEventToPersonUseCase;

  Future<Either<Failure, Event>> execute(Event event) async {
    try {
      // Валидация
      if (event.id.isEmpty) {
        return const Left(ValidationFailure('ID события не может быть пустым'));
      }

      if (event.title.isEmpty) {
        return const Left(
          ValidationFailure('Название события не может быть пустым'),
        );
      }

      final updatedEvent = await _repository.updateEvent(event);

      // Обратная синхронизация: если это событие рождения/смерти, новая
      // дата/место переносятся обратно в Person.birthDate/deathDate.
      await _syncEventToPersonUseCase.execute(updatedEvent);

      return Right(updatedEvent);
    } catch (e) {
      return Left(ServerFailure('Ошибка обновления события: ${e.toString()}'));
    }
  }
}