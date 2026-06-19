import 'package:equatable/equatable.dart';

abstract class TreeEvent extends Equatable {
  const TreeEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class LoadTreeEvent extends TreeEvent {
  const LoadTreeEvent(this.rootPersonId);
  final String rootPersonId;

  @override
  List<Object?> get props => <Object?>[rootPersonId];
}

class ChangeRootPersonEvent extends TreeEvent {
  const ChangeRootPersonEvent(this.personId);
  final String personId;

  @override
  List<Object?> get props => <Object?>[personId];
}

class SelectPersonEvent extends TreeEvent {
  const SelectPersonEvent(this.personId);
  final String personId;

  @override
  List<Object?> get props => <Object?>[personId];
}
