// lib/domain/use_cases/event/update_event.dart
import 'package:dartz/dartz.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/entities/event.dart';
import 'package:nm_gen/domain/repositories/event_repository.dart';

/// Use Case: Обновление события
class UpdateEventUseCase {
  UpdateEventUseCase(this._repository);
  final EventRepository _repository;

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
      return Right(updatedEvent);
    } catch (e) {
      return Left(ServerFailure('Ошибка обновления события: ${e.toString()}'));
    }
  }
}
