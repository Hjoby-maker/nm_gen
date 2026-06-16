import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nm_gen/domain/use_cases/tree/get_family_tree.dart';
import 'package:nm_gen/presentation/blocs/tree/tree_event.dart';
import 'package:nm_gen/presentation/blocs/tree/tree_state.dart';

class TreeBloc extends Bloc<TreeEvent, TreeState> {
  final GetFamilyTreeUseCase getFamilyTreeUseCase;

  TreeBloc({required this.getFamilyTreeUseCase}) : super(TreeInitial()) {
    on<LoadTreeEvent>(_onLoadTree);
    on<ChangeRootPersonEvent>(_onChangeRootPerson);
    on<SelectPersonEvent>(_onSelectPerson);
  }

  Future<void> _onLoadTree(LoadTreeEvent event, Emitter<TreeState> emit) async {
    emit(TreeLoading());

    final result = await getFamilyTreeUseCase.execute(event.rootPersonId);

    result.fold(
      (failure) => emit(TreeError(failure.message)),
      (rootNode) => emit(
        TreeLoaded(rootNode: rootNode, rootPersonId: event.rootPersonId),
      ),
    );
  }

  Future<void> _onChangeRootPerson(
    ChangeRootPersonEvent event,
    Emitter<TreeState> emit,
  ) async {
    emit(TreeLoading());

    final result = await getFamilyTreeUseCase.execute(event.personId);

    result.fold(
      (failure) => emit(TreeError(failure.message)),
      (rootNode) =>
          emit(TreeLoaded(rootNode: rootNode, rootPersonId: event.personId)),
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
        ),
      );
    }
  }
}
