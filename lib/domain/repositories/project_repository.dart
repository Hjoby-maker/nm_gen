import 'package:nm_gen/domain/entities/project.dart';

abstract class ProjectRepository {
  Future<List<Project>> getAllProjects();
  Future<Project?> getProjectById(String id);
  Future<Project> addProject(Project project);
  Future<Project> updateProject(Project project);
  Future<void> deleteProject(String id);
  Future<bool> canDeleteProject(String id); // <-- ДОБАВЛЯЕМ
  Future<Project?> getDefaultProject(); // <-- ДОБАВЛЯЕМ
  Future<void> setDefaultProject(String id);
}
