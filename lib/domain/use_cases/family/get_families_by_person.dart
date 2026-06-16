import 'package:dartz/dartz.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/entities/family.dart';
import 'package:nm_gen/domain/repositories/family_repository.dart';

/// Use Case: Получение всех семей, где участвует человек
class GetFamiliesByPersonUseCase {
  final FamilyRepository repository;

  GetFamiliesByPersonUseCase(this.repository);

  Future<Either<Failure, List<Family>>> execute(String personId) async {
    try {
      if (personId.isEmpty) {
        return Left(ValidationFailure('ID человека не может быть пустым'));
      }

      final families = await repository.getFamiliesByPerson(personId);
      return Right(families);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
