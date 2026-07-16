import 'package:equatable/equatable.dart';
import 'package:nm_gen/domain/entities/event.dart';

abstract class EventState extends Equatable {
  const EventState();

  @override
  List<Object?> get props => <Object?>[];
}

class EventInitial extends EventState {}

class EventLoading extends EventState {}

class EventsLoaded extends EventState {
  const EventsLoaded({required this.events, this.treeId});
  final List<Event> events;
  final String? treeId;
  @override
  List<Object?> get props => <Object?>[events, treeId];
}

class EventOperationSuccess extends EventState {
  const EventOperationSuccess(this.message);
  final String message;
  @override
  List<Object> get props => <Object>[message];
}

class EventError extends EventState {
  const EventError(this.message);
  final String message;
  @override
  List<Object> get props => <Object>[message];
}
