import 'package:dartz/dartz.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/repositories/family_repository.dart';

/// Use Case: Удаление ребенка из семьи
class RemoveChildFromFamilyUseCase {
  RemoveChildFromFamilyUseCase(this.repository);
  final FamilyRepository repository;

  Future<Either<Failure, void>> execute(
    String familyId,
    String childId, {
    String? treeId,
  }) async {
    try {
      if (familyId.isEmpty || childId.isEmpty) {
        return const Left(
          ValidationFailure('ID семьи и ребенка не могут быть пустыми'),
        );
      }

      await repository.removeChildFromFamily(familyId, childId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
