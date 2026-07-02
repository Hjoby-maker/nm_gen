import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/repositories/person_repository.dart';
import 'package:nm_gen/domain/use_cases/tree/get_family_tree.dart';
import 'package:nm_gen/presentation/blocs/tree/tree_event.dart';
import 'package:nm_gen/presentation/blocs/tree/tree_state.dart';
import 'package:nm_gen/di/injector.dart';

class TreeBloc extends Bloc<TreeEvent, TreeState> {
  final GetFamilyTreeUseCase getFamilyTreeUseCase;

  TreeBloc({required this.getFamilyTreeUseCase}) : super(TreeInitial()) {
    on<LoadTreeEvent>(_onLoadTree);
    on<ChangeRootPersonEvent>(_onChangeRootPerson);
    on<SelectPersonEvent>(_onSelectPerson);
  }

  Future<void> _onLoadTree(LoadTreeEvent event, Emitter<TreeState> emit) async {
    emit(TreeLoading());

    String rootId = event.rootPersonId;

    // Если ID пустой, находим первого человека
    if (rootId.isEmpty) {
      final personRepo = getIt<PersonRepository>();
      final allPersons = await personRepo.getAllPersons(treeId: event.treeId);
      if (allPersons.isNotEmpty) {
        rootId = allPersons.first.id;
      } else {
        emit(TreeError('Нет людей для отображения'));
        return;
      }
    }

    final result = await getFamilyTreeUseCase.execute(
      rootId,
      treeId: event.treeId,
    );

    result.fold(
      (failure) => emit(TreeError(failure.message)),
      (rootNode) => emit(
        TreeLoaded(
          rootNode: rootNode,
          rootPersonId: rootId,
          treeId: event.treeId,
        ),
      ),
    );
  }

  Future<void> _onChangeRootPerson(
    ChangeRootPersonEvent event,
    Emitter<TreeState> emit,
  ) async {
    emit(TreeLoading());

    final result = await getFamilyTreeUseCase.execute(
      event.personId,
      treeId: event.treeId,
    );

    result.fold(
      (failure) => emit(TreeError(failure.message)),
      (rootNode) => emit(
        TreeLoaded(
          rootNode: rootNode,
          rootPersonId: event.personId,
          treeId: event.treeId,
        ),
      ),
    );
  }

  void _onSelectPerson(SelectPersonEvent event, Emitter<TreeState> emit) {
    final currentState = state;
    if (currentState is TreeLoaded) {
      emit(
        TreeLoaded(
          rootNode: currentState.rootNode,
          rootPersonId: currentState.rootPersonId,
          selectedPersonId: event.personId,
          treeId: event.treeId ?? currentState.treeId,
        ),
      );
    }
  }
}
