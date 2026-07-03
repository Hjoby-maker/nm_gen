import 'package:dartz/dartz.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/repositories/person_repository.dart';
import 'package:nm_gen/domain/use_cases/person/sync_person_events.dart';

/// Use Case: Обновление данных человека
class UpdatePersonUseCase {
  UpdatePersonUseCase(this._personRepository, this._syncPersonEventsUseCase);
  final PersonRepository _personRepository;
  final SyncPersonEventsUseCase _syncPersonEventsUseCase;

  Future<Either<Failure, Person>> execute(
    Person person, {
    String? treeId,
  }) async {
    try {
      // Валидация
      if (person.id.isEmpty) {
        return const Left(
          ValidationFailure('ID человека не может быть пустым'),
        );
      }

      if (person.firstName.isEmpty || person.lastName.isEmpty) {
        return const Left(
          ValidationFailure('Имя и фамилия обязательны для заполнения'),
        );
      }

      // Обновляем treeId если передан
      final personWithTree = treeId != null && person.treeId != treeId
          ? person.copyWith(treeId: treeId)
          : person;

      // Сохраняем изменения
      final updatedPerson = await _personRepository.updatePerson(
        personWithTree,
      );

      // Синхронизируем автоматические события (рождение, смерть)
      await _syncPersonEventsUseCase.execute(updatedPerson);

      return Right(updatedPerson);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
