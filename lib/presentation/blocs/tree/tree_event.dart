import 'package:equatable/equatable.dart';

abstract class TreeEvent extends Equatable {
  const TreeEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class LoadTreeEvent extends TreeEvent {
  const LoadTreeEvent(this.rootPersonId, {this.treeId});
  final String rootPersonId;
  final String? treeId;

  @override
  List<Object?> get props => <Object?>[rootPersonId, treeId];
}

class ChangeRootPersonEvent extends TreeEvent {
  const ChangeRootPersonEvent(this.personId, {this.treeId});
  final String personId;
  final String? treeId;

  @override
  List<Object?> get props => <Object?>[personId, treeId];
}

class SelectPersonEvent extends TreeEvent {
  const SelectPersonEvent(this.personId, {this.treeId});
  final String personId;
  final String? treeId;

  @override
  List<Object?> get props => <Object?>[personId, treeId];
}
