import 'package:equatable/equatable.dart';
import 'package:nm_gen/domain/entities/project.dart';

abstract class ProjectState extends Equatable {
  const ProjectState();

  @override
  List<Object?> get props => [];
}

class ProjectInitial extends ProjectState {}

class ProjectLoading extends ProjectState {}

class ProjectsLoaded extends ProjectState {
  final List<Project> projects;
  final String? selectedProjectId;

  const ProjectsLoaded({required this.projects, this.selectedProjectId});

  Project? get selectedProject {
    try {
      return projects.firstWhere((p) => p.id == selectedProjectId);
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [projects, selectedProjectId];
}

class ProjectOperationSuccess extends ProjectState {
  final String message;
  const ProjectOperationSuccess(this.message);
  @override
  List<Object> get props => [message];
}

class ProjectCanDeleteResult extends ProjectState {
  final bool canDelete;
  final String projectId;
  const ProjectCanDeleteResult({
    required this.canDelete,
    required this.projectId,
  });
  @override
  List<Object> get props => [canDelete, projectId];
}

class ProjectError extends ProjectState {
  final String message;
  const ProjectError(this.message);
  @override
  List<Object> get props => [message];
}
