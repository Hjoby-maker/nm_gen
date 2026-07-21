// lib/domain/use_cases/event/get_events_by_person.dart
import 'package:dartz/dartz.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/entities/event.dart';
import 'package:nm_gen/domain/repositories/event_repository.dart';

/// Use Case: Получение всех событий человека
class GetEventsByPersonUseCase {
  GetEventsByPersonUseCase(this._repository);
  final EventRepository _repository;

  Future<Either<Failure, List<Event>>> execute(
    String personId, {
    String? treeId,
  }) async {
    try {
      if (personId.isEmpty) {
        return const Left(
          ValidationFailure('ID человека не может быть пустым'),
        );
      }

      final events = await _repository.getEventsByPersonId(
        personId,
        treeId: treeId,
      );
      return Right(events);
    } catch (e) {
      return Left(ServerFailure('Ошибка загрузки событий: ${e.toString()}'));
    }
  }
}
