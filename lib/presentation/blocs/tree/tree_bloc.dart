import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nm_gen/domain/use_cases/tree/get_family_tree.dart';
import 'package:nm_gen/presentation/blocs/tree/tree_event.dart';
import 'package:nm_gen/presentation/blocs/tree/tree_state.dart';

/// BLoC для управления генеалогическим древом
class TreeBloc extends Bloc<TreeEvent, TreeState> {
  final GetFamilyTreeUseCase getFamilyTreeUseCase;

  TreeBloc({required this.getFamilyTreeUseCase}) : super(TreeInitial()) {
    on<LoadTreeEvent>(_onLoadTree);
    on<ChangeRootPersonEvent>(_onChangeRootPerson);
  }

  /// Обработчик: Загрузка древа
  Future<void> _onLoadTree(LoadTreeEvent event, Emitter<TreeState> emit) async {
    emit(TreeLoading());

    final result = await getFamilyTreeUseCase.execute(event.rootPersonId);

    result.fold(
      (failure) => emit(TreeError(failure.message)),
      (familyTree) => emit(
        TreeLoaded(familyTree: familyTree, rootPersonId: event.rootPersonId),
      ),
    );
  }

  /// Обработчик: Смена корневого человека
  Future<void> _onChangeRootPerson(
    ChangeRootPersonEvent event,
    Emitter<TreeState> emit,
  ) async {
    emit(TreeLoading());

    final result = await getFamilyTreeUseCase.execute(event.personId);

    result.fold(
      (failure) => emit(TreeError(failure.message)),
      (familyTree) => emit(
        TreeLoaded(familyTree: familyTree, rootPersonId: event.personId),
      ),
    );
  }
}
