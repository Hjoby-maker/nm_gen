import 'package:dartz/dartz.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/repositories/person_repository.dart';

/// Use Case: Добавление нового человека
class AddPersonUseCase {
  AddPersonUseCase(this.repository);
  final PersonRepository repository;

  /// Выполнить добавление человека
  /// Возвращает Either<Failure, Person> - либо ошибку, либо добавленного человека
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

      final Person result = await repository.addPerson(personWithTree);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
