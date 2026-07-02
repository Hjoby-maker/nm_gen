import 'package:injectable/injectable.dart';
import 'package:nm_gen/data/datasources/local/family_local_datasource.dart';
import 'package:nm_gen/data/datasources/local/database/family_model.dart';
import 'package:nm_gen/domain/entities/family.dart';
import 'package:nm_gen/domain/repositories/family_repository.dart';

@Injectable(as: FamilyRepository)
class FamilyRepositoryImpl implements FamilyRepository {
  FamilyRepositoryImpl(this.localDataSource);
  final FamilyLocalDataSource localDataSource;

  @override
  Future<Family> addFamily(Family family) async {
    final FamilyModel model = FamilyModel.fromDomain(family);
    final FamilyModel savedModel = await localDataSource.insertFamily(model);
    return savedModel.toDomain();
  }

  @override
  Future<Family?> getFamily(String id) async {
    final FamilyModel? model = await localDataSource.getFamily(id);
    return model?.toDomain();
  }

  @override
  Future<List<Family>> getAllFamilies({String? treeId}) async {
    final models = await localDataSource.getAllFamilies(treeId: treeId);
    return models.map((model) => model.toDomain()).toList();
  }

  @override
  Future<Family> updateFamily(Family family) async {
    final FamilyModel model = FamilyModel.fromDomain(family);
    final FamilyModel updatedModel = await localDataSource.updateFamily(model);
    return updatedModel.toDomain();
  }

  @override
  Future<void> deleteFamily(String id) async {
    await localDataSource.deleteFamily(id);
  }

  @override
  Future<void> deleteAllFamilies({String? treeId}) async {
    await localDataSource.deleteAllFamilies(treeId: treeId);
  }

  @override
  Future<List<Family>> getFamiliesByPerson(
    String personId, {
    String? treeId,
  }) async {
    final List<FamilyModel> models = await localDataSource.getFamiliesByPerson(
      personId,
      treeId: treeId,
    );
    return models.map((model) => model.toDomain()).toList();
  }

  @override
  Future<List<Family>> getFamiliesAsParent(
    String personId, {
    String? treeId,
  }) async {
    final List<FamilyModel> models = await localDataSource.getFamiliesAsParent(
      personId,
      treeId: treeId,
    );
    return models.map((model) => model.toDomain()).toList();
  }

  @override
  Future<List<Family>> getFamiliesAsChild(
    String personId, {
    String? treeId,
  }) async {
    final List<FamilyModel> models = await localDataSource.getFamiliesAsChild(
      personId,
      treeId: treeId,
    );
    return models.map((model) => model.toDomain()).toList();
  }

  @override
  Future<void> addChildToFamily(String familyId, String childId) async {
    await localDataSource.addChildToFamily(familyId, childId);
  }

  @override
  Future<void> removeChildFromFamily(String familyId, String childId) async {
    await localDataSource.removeChildFromFamily(familyId, childId);
  }
}
