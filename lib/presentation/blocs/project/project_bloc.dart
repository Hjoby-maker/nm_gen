import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:nm_gen/di/injector.dart';
import 'package:nm_gen/domain/entities/project.dart';
import 'package:nm_gen/domain/repositories/project_repository.dart';
import 'package:nm_gen/presentation/blocs/project/project_event.dart';
import 'package:nm_gen/presentation/blocs/project/project_state.dart';

class ProjectBloc extends Bloc<ProjectEvent, ProjectState> {
  ProjectBloc() : super(ProjectInitial()) {
    on<LoadProjectsEvent>(_onLoadProjects);
    on<AddProjectEvent>(_onAddProject);
    on<UpdateProjectEvent>(_onUpdateProject);
    on<DeleteProjectEvent>(_onDeleteProject);
    on<SelectProjectEvent>(_onSelectProject);
    on<CheckCanDeleteProjectEvent>(_onCheckCanDeleteProject);
    on<SetDefaultProjectEvent>(_onSetDefaultProject);
  }
  final ProjectRepository _repository = getIt<ProjectRepository>();

  Future<void> _onLoadProjects(
    LoadProjectsEvent event,
    Emitter<ProjectState> emit,
  ) async {
    emit(ProjectLoading());
    try {
      final projects = await _repository.getAllProjects();
      emit(ProjectsLoaded(projects: projects));
    } catch (e) {
      emit(ProjectError('Ошибка загрузки проектов: ${e.toString()}'));
    }
  }

  Future<void> _onAddProject(
    AddProjectEvent event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      await _repository.addProject(event.project);
      emit(ProjectOperationSuccess('Проект "${event.project.name}" создан'));
      add(LoadProjectsEvent());
    } catch (e) {
      emit(ProjectError('Ошибка создания проекта: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateProject(
    UpdateProjectEvent event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      await _repository.updateProject(event.project);
      emit(ProjectOperationSuccess('Проект "${event.project.name}" обновлен'));
      add(LoadProjectsEvent());
    } catch (e) {
      emit(ProjectError('Ошибка обновления проекта: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteProject(
    DeleteProjectEvent event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      // Проверяем, можно ли удалить проект
      final canDelete = await _repository.canDeleteProject(event.projectId);
      if (!canDelete) {
        emit(
          ProjectError(
            'Невозможно удалить проект: в нем есть персоны или семьи',
          ),
        );
        return;
      }

      await _repository.deleteProject(event.projectId);
      emit(const ProjectOperationSuccess('Проект удален'));
      add(LoadProjectsEvent());
    } catch (e) {
      emit(ProjectError('Ошибка удаления проекта: ${e.toString()}'));
    }
  }

  Future<void> _onCheckCanDeleteProject(
    CheckCanDeleteProjectEvent event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      final canDelete = await _repository.canDeleteProject(event.projectId);
      emit(
        ProjectCanDeleteResult(
          canDelete: canDelete,
          projectId: event.projectId,
        ),
      );
    } catch (e) {
      emit(ProjectError('Ошибка проверки: ${e.toString()}'));
    }
  }

  void _onSelectProject(SelectProjectEvent event, Emitter<ProjectState> emit) {
    final currentState = state;
    if (currentState is ProjectsLoaded) {
      final exists = currentState.projects.any((p) => p.id == event.projectId);
      if (exists) {
        emit(
          ProjectsLoaded(
            projects: currentState.projects,
            selectedProjectId: event.projectId,
          ),
        );
      }
    }
  }

  Future<void> _onSetDefaultProject(
    SetDefaultProjectEvent event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      await _repository.setDefaultProject(event.projectId);
      emit(
        const ProjectOperationSuccess(
          'Проект установлен как проект по умолчанию',
        ),
      );
      add(LoadProjectsEvent());
    } catch (e) {
      emit(
        ProjectError('Ошибка установки проекта по умолчанию: ${e.toString()}'),
      );
    }
  }
}
