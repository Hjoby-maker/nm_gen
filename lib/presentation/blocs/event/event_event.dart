import 'package:equatable/equatable.dart';
import 'package:nm_gen/domain/entities/event.dart';

abstract class EventEvent extends Equatable {
  const EventEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class LoadPersonEventsEvent extends EventEvent {
  const LoadPersonEventsEvent(this.personId, {this.treeId});
  final String personId;
  final String? treeId;
  @override
  List<Object?> get props => <Object?>[personId, treeId];
}

class LoadAllEventsEvent extends EventEvent {
  const LoadAllEventsEvent({this.treeId});
  final String? treeId;
  @override
  List<Object?> get props => <Object?>[treeId];
}

class AddEventEvent extends EventEvent {
  const AddEventEvent(this.event);
  final Event event;
  @override
  List<Object?> get props => <Object?>[event];
}

class UpdateEventEvent extends EventEvent {
  const UpdateEventEvent(this.event);
  final Event event;
  @override
  List<Object?> get props => <Object?>[event];
}

class DeleteEventEvent extends EventEvent {
  const DeleteEventEvent(this.eventId);
  final String eventId;
  @override
  List<Object?> get props => <Object?>[eventId];
}

class DeleteAllPersonEventsEvent extends EventEvent {
  const DeleteAllPersonEventsEvent(this.personId, {this.treeId});
  final String personId;
  final String? treeId;
  @override
  List<Object?> get props => <Object?>[personId, treeId];
}