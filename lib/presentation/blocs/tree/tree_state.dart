import 'package:equatable/equatable.dart';
import 'package:nm_gen/domain/entities/tree_node.dart';

abstract class TreeState extends Equatable {
  const TreeState();

  @override
  List<Object?> get props => [];
}

class TreeInitial extends TreeState {}

class TreeLoading extends TreeState {}

class TreeLoaded extends TreeState {
  final TreeNode rootNode;
  final String rootPersonId;
  final String? selectedPersonId;

  const TreeLoaded({
    required this.rootNode,
    required this.rootPersonId,
    this.selectedPersonId,
  });

  @override
  List<Object?> get props => [rootNode, rootPersonId, selectedPersonId];
}

class TreeError extends TreeState {
  final String message;
  const TreeError(this.message);

  @override
  List<Object?> get props => [message];
}
