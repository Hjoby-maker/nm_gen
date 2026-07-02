import 'package:dartz/dartz.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/entities/family.dart';
import 'package:nm_gen/domain/repositories/family_repository.dart';

/// Use Case: Получение всех семей, где участвует человек
class GetFamiliesByPersonUseCase {
  GetFamiliesByPersonUseCase(this.repository);
  final FamilyRepository repository;

  Future<Either<Failure, List<Family>>> execute(
    String personId, {
    String? treeId,
  }) async {
    try {
      if (personId.isEmpty) {
        return const Left(
          ValidationFailure('ID человека не может быть пустым'),
        );
      }

      final List<Family> families = await repository.getFamiliesByPerson(
        personId,
        treeId: treeId,
      );
      return Right(families);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
