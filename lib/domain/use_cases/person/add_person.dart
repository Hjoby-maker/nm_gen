import 'package:dartz/dartz.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/repositories/person_repository.dart';
import 'package:nm_gen/domain/use_cases/person/sync_person_events.dart';

/// Use Case: Добавление нового человека
class AddPersonUseCase {
  AddPersonUseCase(this._personRepository, this._syncPersonEventsUseCase);
  final PersonRepository _personRepository;
  final SyncPersonEventsUseCase _syncPersonEventsUseCase;

  Future<Either<Failure, Person>> execute(
    Person person, {
    String? treeId,
  }) async {
    try {
      // Валидация данных
      if (person.firstName.isEmpty || person.lastName.isEmpty) {
        return const Left(
          ValidationFailure('Имя и фамилия обязательны для заполнения'),
        );
      }

      // Добавляем treeId если его нет
      final personWithTree = person.treeId.isEmpty
          ? person.copyWith(treeId: treeId ?? 'default')
          : person;

      // Сохраняем человека
      final savedPerson = await _personRepository.addPerson(personWithTree);

      // Синхронизируем автоматические события (рождение, смерть)
      await _syncPersonEventsUseCase.execute(savedPerson);

      return Right(savedPerson);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
