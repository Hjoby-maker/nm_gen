import 'package:equatable/equatable.dart';

/// Базовый класс для всех событий Tree
abstract class TreeEvent extends Equatable {
  const TreeEvent();

  @override
  List<Object?> get props => [];
}

/// Событие: Загрузить древо
class LoadTreeEvent extends TreeEvent {
  final String rootPersonId;
  const LoadTreeEvent(this.rootPersonId);

  @override
  List<Object?> get props => [rootPersonId];
}

/// Событие: Выбрать нового корневого человека
class ChangeRootPersonEvent extends TreeEvent {
  final String personId;
  const ChangeRootPersonEvent(this.personId);

  @override
  List<Object?> get props => [personId];
}
