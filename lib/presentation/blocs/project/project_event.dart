import 'package:equatable/equatable.dart';
import 'package:nm_gen/domain/entities/project.dart';

abstract class ProjectEvent extends Equatable {
  const ProjectEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class LoadProjectsEvent extends ProjectEvent {}

class AddProjectEvent extends ProjectEvent {
  const AddProjectEvent(this.project);
  final Project project;
  @override
  List<Object?> get props => <Object?>[project];
}

class UpdateProjectEvent extends ProjectEvent {
  const UpdateProjectEvent(this.project);
  final Project project;
  @override
  List<Object?> get props => <Object?>[project];
}

class DeleteProjectEvent extends ProjectEvent {
  const DeleteProjectEvent(this.projectId);
  final String projectId;
  @override
  List<Object?> get props => <Object?>[projectId];
}

class SelectProjectEvent extends ProjectEvent {
  const SelectProjectEvent(this.projectId);
  final String projectId;
  @override
  List<Object?> get props => <Object?>[projectId];
}

class CheckCanDeleteProjectEvent extends ProjectEvent {
  const CheckCanDeleteProjectEvent(this.projectId);
  final String projectId;
  @override
  List<Object?> get props => <Object?>[projectId];
}

class SetDefaultProjectEvent extends ProjectEvent {
  const SetDefaultProjectEvent(this.projectId);
  // <-- ДОБАВЛЯЕМ
  final String projectId;
  @override
  List<Object?> get props => <Object?>[projectId];
}
