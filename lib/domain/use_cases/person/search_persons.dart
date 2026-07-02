import 'package:dartz/dartz.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/repositories/person_repository.dart';

/// Use Case: Поиск людей по запросу
class SearchPersonsUseCase {
  SearchPersonsUseCase(this.repository);
  final PersonRepository repository;

  Future<Either<Failure, List<Person>>> execute(
    String query, {
    String? treeId,
  }) async {
    try {
      final List<Person> persons = await repository.searchPersons(
        query,
        treeId: treeId,
      );
      return Right(persons);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
