import 'package:dartz/dartz.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/repositories/person_repository.dart';

/// Use Case: Удаление человека
class DeletePersonUseCase {
  final PersonRepository repository;

  DeletePersonUseCase(this.repository);

  Future<Either<Failure, void>> execute(String id) async {
    try {
      if (id.isEmpty) {
        return Left(ValidationFailure('ID человека не может быть пустым'));
      }

      await repository.deletePerson(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
