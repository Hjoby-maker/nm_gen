// lib/domain/use_cases/event/get_all_events.dart
import 'package:dartz/dartz.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/entities/event.dart';
import 'package:nm_gen/domain/repositories/event_repository.dart';

/// Use Case: Получение всех событий в проекте
class GetAllEventsUseCase {
  GetAllEventsUseCase(this._repository);
  final EventRepository _repository;

  Future<Either<Failure, List<Event>>> execute({String? treeId}) async {
    try {
      final events = await _repository.getAllEvents(treeId: treeId);
      return Right(events);
    } catch (e) {
      return Left(ServerFailure('Ошибка загрузки событий: ${e.toString()}'));
    }
  }
}
