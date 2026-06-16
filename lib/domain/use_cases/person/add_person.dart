import 'package:dartz/dartz.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/repositories/person_repository.dart';

/// Use Case: Добавление нового человека
class AddPersonUseCase {
  final PersonRepository repository;

  AddPersonUseCase(this.repository);

  /// Выполнить добавление человека
  /// Возвращает Either<Failure, Person> - либо ошибку, либо добавленного человека
  Future<Either<Failure, Person>> execute(Person person) async {
    try {
      // Валидация данных
      if (person.firstName.isEmpty || person.lastName.isEmpty) {
        return Left(
          ValidationFailure('Имя и фамилия обязательны для заполнения'),
        );
      }

      // Проверка на дубликат (по желанию)
      // Здесь можно добавить проверку на существование человека с таким же именем

      final result = await repository.addPerson(person);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
