import 'package:equatable/equatable.dart';
import 'package:nm_gen/domain/entities/tree_node.dart';

abstract class TreeState extends Equatable {
  const TreeState();

  @override
  List<Object?> get props => <Object?>[];
}

class TreeInitial extends TreeState {}

class TreeLoading extends TreeState {}

class TreeLoaded extends TreeState {
  const TreeLoaded({
    required this.rootNode,
    required this.rootPersonId,
    this.selectedPersonId,
    this.treeId, // <-- ДОБАВЛЯЕМ
  });
  final TreeNode rootNode;
  final String rootPersonId;
  final String? selectedPersonId;
  final String? treeId; // <-- ДОБАВЛЯЕМ

  @override
  List<Object?> get props => <Object?>[
    rootNode,
    rootPersonId,
    selectedPersonId,
    treeId, // <-- ДОБАВЛЯЕМ
  ];
}

class TreeError extends TreeState {
  const TreeError(this.message);
  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}
