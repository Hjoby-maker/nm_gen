import 'package:injectable/injectable.dart';
import 'package:nm_gen/data/datasources/local/person_local_datasource.dart';
import 'package:nm_gen/data/datasources/local/database/person_model.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/repositories/person_repository.dart';

@Injectable(as: PersonRepository)
class PersonRepositoryImpl implements PersonRepository {
  final PersonLocalDataSource localDataSource;

  PersonRepositoryImpl(this.localDataSource);

  @override
  Future<Person> addPerson(Person person) async {
    final model = PersonModel.fromDomain(person);
    final savedModel = await localDataSource.insertPerson(model);
    return savedModel.toDomain();
  }

  @override
  Future<Person?> getPerson(String id) async {
    final model = await localDataSource.getPerson(id);
    return model?.toDomain();
  }

  @override
  Future<List<Person>> getAllPersons() async {
    final models = await localDataSource.getAllPersons();
    return models.map((model) => model.toDomain()).toList();
  }

  @override
  Future<Person> updatePerson(Person person) async {
    final model = PersonModel.fromDomain(person);
    final updatedModel = await localDataSource.updatePerson(model);
    return updatedModel.toDomain();
  }

  @override
  Future<void> deletePerson(String id) async {
    await localDataSource.deletePerson(id);
  }

  @override
  Future<List<Person>> searchPersons(String query) async {
    if (query.isEmpty) {
      return getAllPersons();
    }
    final models = await localDataSource.searchPersons(query);
    return models.map((model) => model.toDomain()).toList();
  }

  @override
  Future<List<Person>> getPersonsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final models = await localDataSource.getPersonsByIds(ids);
    return models.map((model) => model.toDomain()).toList();
  }
}
