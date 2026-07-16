import 'package:equatable/equatable.dart';
import 'package:nm_gen/domain/entities/project.dart';

abstract class ProjectState extends Equatable {
  const ProjectState();

  @override
  List<Object?> get props => <Object?>[];
}

class ProjectInitial extends ProjectState {}

class ProjectLoading extends ProjectState {}

class ProjectsLoaded extends ProjectState {
  const ProjectsLoaded({required this.projects, this.selectedProjectId});
  final List<Project> projects;
  final String? selectedProjectId;

  Project? get selectedProject {
    try {
      return projects.firstWhere((p) => p.id == selectedProjectId);
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => <Object?>[projects, selectedProjectId];
}

class ProjectOperationSuccess extends ProjectState {
  const ProjectOperationSuccess(this.message);
  final String message;
  @override
  List<Object> get props => <Object>[message];
}

class ProjectCanDeleteResult extends ProjectState {
  const ProjectCanDeleteResult({
    required this.canDelete,
    required this.projectId,
  });
  final bool canDelete;
  final String projectId;
  @override
  List<Object> get props => <Object>[canDelete, projectId];
}

class ProjectError extends ProjectState {
  const ProjectError(this.message);
  final String message;
  @override
  List<Object> get props => <Object>[message];
}
