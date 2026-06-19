import 'package:dartz/dartz.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/repositories/family_repository.dart';

/// Use Case: Добавление ребенка в семью
class AddChildToFamilyUseCase {
  AddChildToFamilyUseCase(this.repository);
  final FamilyRepository repository;

  Future<Either<Failure, void>> execute(String familyId, String childId) async {
    try {
      if (familyId.isEmpty || childId.isEmpty) {
        return const Left(
          ValidationFailure('ID семьи и ребенка не могут быть пустыми'),
        );
      }

      await repository.addChildToFamily(familyId, childId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
