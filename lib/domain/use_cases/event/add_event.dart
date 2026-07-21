// lib/domain/use_cases/event/add_event.dart
import 'package:dartz/dartz.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/entities/event.dart';
import 'package:nm_gen/domain/repositories/event_repository.dart';

/// Use Case: Добавление нового события
class AddEventUseCase {
  AddEventUseCase(this._repository);
  final EventRepository _repository;

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
      return Right(savedEvent);
    } catch (e) {
      return Left(ServerFailure('Ошибка добавления события: ${e.toString()}'));
    }
  }
}
