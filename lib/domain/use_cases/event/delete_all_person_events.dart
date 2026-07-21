// lib/domain/use_cases/event/delete_all_person_events.dart
import 'package:dartz/dartz.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/repositories/event_repository.dart';

/// Use Case: Удаление всех событий человека
class DeleteAllPersonEventsUseCase {
  DeleteAllPersonEventsUseCase(this._repository);
  final EventRepository _repository;

  Future<Either<Failure, void>> execute(
    String personId, {
    String? treeId,
  }) async {
    try {
      if (personId.isEmpty) {
        return const Left(
          ValidationFailure('ID человека не может быть пустым'),
        );
      }

      await _repository.deleteEventsByPersonId(personId, treeId: treeId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Ошибка удаления событий: ${e.toString()}'));
    }
  }
}
