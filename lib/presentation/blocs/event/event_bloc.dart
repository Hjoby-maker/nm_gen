import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:nm_gen/di/injector.dart';
import 'package:nm_gen/domain/entities/event.dart';
import 'package:nm_gen/domain/repositories/event_repository.dart';
import 'package:nm_gen/presentation/blocs/event/event_event.dart';
import 'package:nm_gen/presentation/blocs/event/event_state.dart';

class EventBloc extends Bloc<EventEvent, EventState> {
  EventBloc() : super(EventInitial()) {
    on<LoadPersonEventsEvent>(_onLoadPersonEvents);
    on<LoadAllEventsEvent>(_onLoadAllEvents);
    on<AddEventEvent>(_onAddEvent);
    on<UpdateEventEvent>(_onUpdateEvent);
    on<DeleteEventEvent>(_onDeleteEvent);
    on<DeleteAllPersonEventsEvent>(_onDeleteAllPersonEvents);
  }
  final EventRepository _repository = getIt<EventRepository>();

  Future<void> _onLoadPersonEvents(
    LoadPersonEventsEvent event,
    Emitter<EventState> emit,
  ) async {
    emit(EventLoading());
    try {
      final events = await _repository.getEventsByPersonId(
        event.personId,
        treeId: event.treeId,
      );
      emit(EventsLoaded(events: events, treeId: event.treeId));
    } catch (e) {
      emit(EventError('Ошибка загрузки событий: ${e.toString()}'));
    }
  }

  Future<void> _onLoadAllEvents(
    LoadAllEventsEvent event,
    Emitter<EventState> emit,
  ) async {
    emit(EventLoading());
    try {
      final events = await _repository.getAllEvents(treeId: event.treeId);
      emit(EventsLoaded(events: events, treeId: event.treeId));
    } catch (e) {
      emit(EventError('Ошибка загрузки событий: ${e.toString()}'));
    }
  }

  Future<void> _onAddEvent(
    AddEventEvent event,
    Emitter<EventState> emit,
  ) async {
    try {
      await _repository.addEvent(event.event);
      emit(const EventOperationSuccess('Событие добавлено'));
      add(
        LoadPersonEventsEvent(event.event.personId, treeId: event.event.treeId),
      );
    } catch (e) {
      emit(EventError('Ошибка добавления события: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateEvent(
    UpdateEventEvent event,
    Emitter<EventState> emit,
  ) async {
    try {
      await _repository.updateEvent(event.event);
      emit(const EventOperationSuccess('Событие обновлено'));
      add(
        LoadPersonEventsEvent(event.event.personId, treeId: event.event.treeId),
      );
    } catch (e) {
      emit(EventError('Ошибка обновления события: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteEvent(
    DeleteEventEvent event,
    Emitter<EventState> emit,
  ) async {
    try {
      final eventToDelete = await _repository.getEvent(event.eventId);
      if (eventToDelete != null) {
        await _repository.deleteEvent(event.eventId);
        emit(const EventOperationSuccess('Событие удалено'));
        add(
          LoadPersonEventsEvent(
            eventToDelete.personId,
            treeId: eventToDelete.treeId,
          ),
        );
      }
    } catch (e) {
      emit(EventError('Ошибка удаления события: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteAllPersonEvents(
    DeleteAllPersonEventsEvent event,
    Emitter<EventState> emit,
  ) async {
    try {
      await _repository.deleteEventsByPersonId(
        event.personId,
        treeId: event.treeId,
      );
      emit(const EventOperationSuccess('Все события удалены'));
      add(LoadPersonEventsEvent(event.personId, treeId: event.treeId));
    } catch (e) {
      emit(EventError('Ошибка удаления событий: ${e.toString()}'));
    }
  }
}