import 'package:injectable/injectable.dart';
import 'package:nm_gen/data/datasources/local/project_local_datasource.dart';
import 'package:nm_gen/data/datasources/local/database/project_model.dart';
import 'package:nm_gen/domain/entities/project.dart';
import 'package:nm_gen/domain/repositories/project_repository.dart';

@Injectable(as: ProjectRepository)
class ProjectRepositoryImpl implements ProjectRepository {
  ProjectRepositoryImpl(this.localDataSource);
  final ProjectLocalDataSource localDataSource;

  @override
  Future<List<Project>> getAllProjects() async {
    final models = await localDataSource.getAllProjects();
    final List<Project> projects = [];

    for (final model in models) {
      final personCount = await localDataSource.getPersonsCountForProject(
        treeId: model.id,
      );
      final familyCount = await localDataSource.getFamiliesCountForProject(
        treeId: model.id,
      );

      projects.add(
        model.toDomain(personCount: personCount, familyCount: familyCount),
      );
    }

    return projects;
  }

  @override
  Future<Project?> getProjectById(String id) async {
    final model = await localDataSource.getProjectById(id);
    if (model == null) return null;

    final personCount = await localDataSource.getPersonsCountForProject(
      treeId: id,
    );
    final familyCount = await localDataSource.getFamiliesCountForProject(
      treeId: id,
    );

    return model.toDomain(personCount: personCount, familyCount: familyCount);
  }

  @override
  Future<Project> addProject(Project project) async {
    final model = ProjectModel.fromDomain(project);
    await localDataSource.insertProject(model);
    return project;
  }

  @override
  Future<Project> updateProject(Project project) async {
    final updatedProject = project.copyWith(updatedAt: DateTime.now());
    final model = ProjectModel.fromDomain(updatedProject);
    await localDataSource.updateProject(model);
    return updatedProject;
  }

  @override
  Future<void> deleteProject(String id) async {
    // Проверяем, не является ли проект проектом по умолчанию
    final defaultProject = await getDefaultProject();
    if (defaultProject?.id == id) {
      throw Exception('Нельзя удалить проект по умолчанию');
    }

    await localDataSource.deleteAllProjectData(treeId: id);
    await localDataSource.deleteProject(id);
  }

  @override
  Future<bool> canDeleteProject(String id) async {
    // Нельзя удалить проект по умолчанию
    final defaultProject = await getDefaultProject();
    if (defaultProject?.id == id) {
      return false;
    }
    return await localDataSource.canDeleteProject(treeId: id);
  }

  @override
  Future<Project?> getDefaultProject() async {
    final model = await localDataSource.getDefaultProject();
    if (model == null) return null;

    final personCount = await localDataSource.getPersonsCountForProject(
      treeId: model.id,
    );
    final familyCount = await localDataSource.getFamiliesCountForProject(
      treeId: model.id,
    );

    return model.toDomain(personCount: personCount, familyCount: familyCount);
  }

  @override
  Future<void> setDefaultProject(String id) async {
    await localDataSource.setDefaultProject(id);
  }
}
