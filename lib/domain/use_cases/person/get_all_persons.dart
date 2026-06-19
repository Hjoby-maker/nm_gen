import 'package:dartz/dartz.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/repositories/person_repository.dart';

/// Use Case: Получение всех людей
class GetAllPersonsUseCase {
  GetAllPersonsUseCase(this.repository);
  final PersonRepository repository;

  Future<Either<Failure, List<Person>>> execute() async {
    try {
      final List<Person> persons = await repository.getAllPersons();
      return Right(persons);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
