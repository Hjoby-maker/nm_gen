// lib/domain/use_cases/event/delete_event.dart
import 'package:dartz/dartz.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/entities/event.dart';
import 'package:nm_gen/domain/repositories/event_repository.dart';

/// Use Case: Удаление события
class DeleteEventUseCase {
  DeleteEventUseCase(this._repository);
  final EventRepository _repository;

  Future<Either<Failure, Event?>> execute(String eventId) async {
    try {
      if (eventId.isEmpty) {
        return const Left(ValidationFailure('ID события не может быть пустым'));
      }

      // Получаем событие перед удалением, чтобы вернуть его ID
      final event = await _repository.getEvent(eventId);
      await _repository.deleteEvent(eventId);

      return Right(event);
    } catch (e) {
      return Left(ServerFailure('Ошибка удаления события: ${e.toString()}'));
    }
  }
}
