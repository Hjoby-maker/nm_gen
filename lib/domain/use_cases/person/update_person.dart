import 'package:dartz/dartz.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/repositories/person_repository.dart';

/// Use Case: Обновление данных человека
class UpdatePersonUseCase {
  final PersonRepository repository;

  UpdatePersonUseCase(this.repository);

  Future<Either<Failure, Person>> execute(Person person) async {
    try {
      // Валидация
      if (person.id.isEmpty) {
        return Left(ValidationFailure('ID человека не может быть пустым'));
      }

      if (person.firstName.isEmpty || person.lastName.isEmpty) {
        return Left(
          ValidationFailure('Имя и фамилия обязательны для заполнения'),
        );
      }

      final result = await repository.updatePerson(person);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
