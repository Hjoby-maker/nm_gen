import 'package:equatable/equatable.dart';
import 'package:nm_gen/domain/entities/event.dart';

abstract class EventEvent extends Equatable {
  const EventEvent();

  @override
  List<Object?> get props => [];
}

class LoadPersonEventsEvent extends EventEvent {
  final String personId;
  final String? treeId;
  const LoadPersonEventsEvent(this.personId, {this.treeId});
  @override
  List<Object?> get props => [personId, treeId];
}

class LoadAllEventsEvent extends EventEvent {
  final String? treeId;
  const LoadAllEventsEvent({this.treeId});
  @override
  List<Object?> get props => [treeId];
}

class AddEventEvent extends EventEvent {
  final Event event;
  const AddEventEvent(this.event);
  @override
  List<Object?> get props => [event];
}

class UpdateEventEvent extends EventEvent {
  final Event event;
  const UpdateEventEvent(this.event);
  @override
  List<Object?> get props => [event];
}

class DeleteEventEvent extends EventEvent {
  final String eventId;
  const DeleteEventEvent(this.eventId);
  @override
  List<Object?> get props => [eventId];
}

class DeleteAllPersonEventsEvent extends EventEvent {
  final String personId;
  final String? treeId;
  const DeleteAllPersonEventsEvent(this.personId, {this.treeId});
  @override
  List<Object?> get props => [personId, treeId];
}
