import 'package:dartz/dartz.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/entities/family.dart';
import 'package:nm_gen/domain/repositories/family_repository.dart';

/// Use Case: Добавление новой семьи
class AddFamilyUseCase {
  AddFamilyUseCase(this.repository);
  final FamilyRepository repository;

  Future<Either<Failure, Family>> execute(Family family) async {
    try {
      // Валидация: должна быть хотя бы один родитель
      if (family.husbandId == null && family.wifeId == null) {
        return const Left(
          ValidationFailure('В семье должен быть хотя бы один родитель'),
        );
      }

      final Family result = await repository.addFamily(family);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
