import 'package:equatable/equatable.dart';
import 'package:nm_gen/domain/entities/event.dart';

abstract class EventState extends Equatable {
  const EventState();

  @override
  List<Object?> get props => [];
}

class EventInitial extends EventState {}

class EventLoading extends EventState {}

class EventsLoaded extends EventState {
  final List<Event> events;
  final String? treeId;
  const EventsLoaded({required this.events, this.treeId});
  @override
  List<Object?> get props => [events, treeId];
}

class EventOperationSuccess extends EventState {
  final String message;
  const EventOperationSuccess(this.message);
  @override
  List<Object> get props => [message];
}

class EventError extends EventState {
  final String message;
  const EventError(this.message);
  @override
  List<Object> get props => [message];
}
