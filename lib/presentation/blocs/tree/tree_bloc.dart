import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nm_gen/di/injector.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/use_cases/tree/get_full_tree.dart';
import 'package:nm_gen/presentation/blocs/tree/tree_event.dart';
import 'package:nm_gen/presentation/blocs/tree/tree_state.dart';

class TreeBloc extends Bloc<TreeEvent, TreeState> {
  TreeBloc() : super(TreeInitial()) {
    on<LoadTreeEvent>(_onLoadTree);
    on<ChangeRootPersonEvent>(_onChangeRootPerson);
    on<SelectPersonEvent>(_onSelectPerson);
  }
  final GetFullTreeUseCase _getFullTreeUseCase = getIt<GetFullTreeUseCase>();

  Future<void> _onLoadTree(LoadTreeEvent event, Emitter<TreeState> emit) async {
    emit(TreeLoading());

    final result = await _getFullTreeUseCase.execute(
      treeId: event.treeId ?? 'default',
      selectedPersonId: event.rootPersonId.isNotEmpty
          ? event.rootPersonId
          : null,
    );

    result.fold(
      (failure) => emit(TreeError(failure.message)),
      (rootNode) => emit(
        TreeLoaded(
          rootNode: rootNode,
          rootPersonId: event.rootPersonId,
          selectedPersonId: event.rootPersonId.isNotEmpty
              ? event.rootPersonId
              : null,
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

    final result = await _getFullTreeUseCase.execute(
      treeId: event.treeId ?? 'default',
      selectedPersonId: event.personId,
    );

    result.fold(
      (failure) => emit(TreeError(failure.message)),
      (rootNode) => emit(
        TreeLoaded(
          rootNode: rootNode,
          rootPersonId: event.personId,
          selectedPersonId: event.personId,
          treeId: event.treeId,
        ),
      ),
    );
  }

  void _onSelectPerson(SelectPersonEvent event, Emitter<TreeState> emit) {
    final currentState = state;
    if (currentState is TreeLoaded) {
      // Перезагружаем дерево с выбранным человеком
      add(
        LoadTreeEvent(
          event.personId,
          treeId: event.treeId ?? currentState.treeId,
        ),
      );
    }
  }
}
