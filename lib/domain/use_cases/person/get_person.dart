import 'package:dartz/dartz.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/repositories/person_repository.dart';

/// Use Case: Получение человека по ID
class GetPersonUseCase {
  GetPersonUseCase(this.repository);
  final PersonRepository repository;

  Future<Either<Failure, Person>> execute(String id, {String? treeId}) async {
    try {
      if (id.isEmpty) {
        return const Left(
          ValidationFailure('ID человека не может быть пустым'),
        );
      }

      final Person? person = await repository.getPerson(id);

      if (person == null) {
        return Left(NotFoundFailure('Человек с ID $id не найден'));
      }

      // Проверяем, что человек принадлежит текущему древу
      if (treeId != null && person.treeId != treeId) {
        return Left(NotFoundFailure('Человек не найден в текущем древе'));
      }

      return Right(person);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
