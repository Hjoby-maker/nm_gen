import 'package:equatable/equatable.dart';

abstract class TreeEvent extends Equatable {
  const TreeEvent();

  @override
  List<Object?> get props => [];
}

class LoadTreeEvent extends TreeEvent {
  final String rootPersonId;
  const LoadTreeEvent(this.rootPersonId);

  @override
  List<Object?> get props => [rootPersonId];
}

class ChangeRootPersonEvent extends TreeEvent {
  final String personId;
  const ChangeRootPersonEvent(this.personId);

  @override
  List<Object?> get props => [personId];
}

class SelectPersonEvent extends TreeEvent {
  final String personId;
  const SelectPersonEvent(this.personId);

  @override
  List<Object?> get props => [personId];
}
