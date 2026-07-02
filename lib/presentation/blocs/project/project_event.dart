import 'package:equatable/equatable.dart';
import 'package:nm_gen/domain/entities/project.dart';

abstract class ProjectEvent extends Equatable {
  const ProjectEvent();

  @override
  List<Object?> get props => [];
}

class LoadProjectsEvent extends ProjectEvent {}

class AddProjectEvent extends ProjectEvent {
  final Project project;
  const AddProjectEvent(this.project);
  @override
  List<Object?> get props => [project];
}

class UpdateProjectEvent extends ProjectEvent {
  final Project project;
  const UpdateProjectEvent(this.project);
  @override
  List<Object?> get props => [project];
}

class DeleteProjectEvent extends ProjectEvent {
  final String projectId;
  const DeleteProjectEvent(this.projectId);
  @override
  List<Object?> get props => [projectId];
}

class SelectProjectEvent extends ProjectEvent {
  final String projectId;
  const SelectProjectEvent(this.projectId);
  @override
  List<Object?> get props => [projectId];
}

class CheckCanDeleteProjectEvent extends ProjectEvent {
  final String projectId;
  const CheckCanDeleteProjectEvent(this.projectId);
  @override
  List<Object?> get props => [projectId];
}

class SetDefaultProjectEvent extends ProjectEvent {
  // <-- ДОБАВЛЯЕМ
  final String projectId;
  const SetDefaultProjectEvent(this.projectId);
  @override
  List<Object?> get props => [projectId];
}
