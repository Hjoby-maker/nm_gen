import 'package:nm_gen/domain/entities/event.dart';

abstract class EventRepository {
  Future<Event> addEvent(Event event);
  Future<Event?> getEvent(String id);
  Future<List<Event>> getEventsByPersonId(String personId, {String? treeId});
  Future<List<Event>> getAllEvents({String? treeId});
  Future<Event> updateEvent(Event event);
  Future<void> deleteEvent(String id);
  Future<void> deleteEventsByPersonId(String personId, {String? treeId});
  Future<int> getEventsCountForPerson(String personId, {String? treeId});
}
