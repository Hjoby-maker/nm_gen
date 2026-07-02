import 'package:injectable/injectable.dart';
import 'package:nm_gen/data/datasources/local/person_local_datasource.dart';
import 'package:nm_gen/data/datasources/local/database/person_model.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/repositories/person_repository.dart';

@Injectable(as: PersonRepository)
class PersonRepositoryImpl implements PersonRepository {
  PersonRepositoryImpl(this.localDataSource);
  final PersonLocalDataSource localDataSource;

  @override
  Future<Person> addPerson(Person person) async {
    final PersonModel model = PersonModel.fromDomain(person);
    final PersonModel savedModel = await localDataSource.insertPerson(model);
    return savedModel.toDomain();
  }

  @override
  Future<Person?> getPerson(String id) async {
    final PersonModel? model = await localDataSource.getPerson(id);
    return model?.toDomain();
  }

  @override
  Future<List<Person>> getAllPersons({String? treeId}) async {
    final models = await localDataSource.getAllPersons(treeId: treeId);
    return models.map((model) => model.toDomain()).toList();
  }

  @override
  Future<Person> updatePerson(Person person) async {
    final PersonModel model = PersonModel.fromDomain(person);
    final PersonModel updatedModel = await localDataSource.updatePerson(model);
    return updatedModel.toDomain();
  }

  @override
  Future<void> deletePerson(String id) async {
    await localDataSource.deletePerson(id);
  }

  @override
  Future<void> deleteAllPersons({String? treeId}) async {
    await localDataSource.deleteAllPersons(treeId: treeId);
  }

  @override
  Future<List<Person>> searchPersons(String query, {String? treeId}) async {
    if (query.isEmpty) {
      return getAllPersons(treeId: treeId);
    }
    final List<PersonModel> models = await localDataSource.searchPersons(
      query,
      treeId: treeId,
    );
    return models.map((model) => model.toDomain()).toList();
  }

  @override
  Future<List<Person>> getPersonsByIds(
    List<String> ids, {
    String? treeId,
  }) async {
    if (ids.isEmpty) return <Person>[];
    final List<PersonModel> models = await localDataSource.getPersonsByIds(
      ids,
      treeId: treeId,
    );
    return models.map((model) => model.toDomain()).toList();
  }

  @override
  Future<int> getPersonsCount({String? treeId}) async {
    return await localDataSource.getPersonsCount(treeId: treeId);
  }
}
