import 'package:injectable/injectable.dart';
import 'package:nm_gen/data/datasources/local/event_local_datasource.dart';
import 'package:nm_gen/data/datasources/local/database/event_model.dart';
import 'package:nm_gen/domain/entities/event.dart';
import 'package:nm_gen/domain/repositories/event_repository.dart';

@Injectable(as: EventRepository)
class EventRepositoryImpl implements EventRepository {
  EventRepositoryImpl(this.localDataSource);
  final EventLocalDataSource localDataSource;

  @override
  Future<Event> addEvent(Event event) async {
    final model = EventModel.fromDomain(event);
    final savedModel = await localDataSource.insertEvent(model);
    return savedModel.toDomain();
  }

  @override
  Future<Event?> getEvent(String id) async {
    final model = await localDataSource.getEvent(id);
    return model?.toDomain();
  }

  @override
  Future<List<Event>> getEventsByPersonId(
    String personId, {
    String? treeId,
  }) async {
    final models = await localDataSource.getEventsByPersonId(
      personId,
      treeId: treeId,
    );
    return models.map((model) => model.toDomain()).toList();
  }

  @override
  Future<List<Event>> getAllEvents({String? treeId}) async {
    final models = await localDataSource.getAllEvents(treeId: treeId);
    return models.map((model) => model.toDomain()).toList();
  }

  @override
  Future<Event> updateEvent(Event event) async {
    final model = EventModel.fromDomain(event);
    final updatedModel = await localDataSource.updateEvent(model);
    return updatedModel.toDomain();
  }

  @override
  Future<void> deleteEvent(String id) async {
    await localDataSource.deleteEvent(id);
  }

  @override
  Future<void> deleteEventsByPersonId(String personId, {String? treeId}) async {
    await localDataSource.deleteEventsByPersonId(personId, treeId: treeId);
  }

  @override
  Future<int> getEventsCountForPerson(String personId, {String? treeId}) async {
    return await localDataSource.getEventsCountForPerson(
      personId,
      treeId: treeId,
    );
  }
}
