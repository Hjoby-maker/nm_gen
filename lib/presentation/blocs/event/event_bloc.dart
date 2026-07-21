// lib/presentation/blocs/event/event_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:nm_gen/di/injector.dart';
import 'package:nm_gen/domain/use_cases/event/add_event.dart';
import 'package:nm_gen/domain/use_cases/event/get_events_by_person.dart';
import 'package:nm_gen/domain/use_cases/event/get_all_events.dart';
import 'package:nm_gen/domain/use_cases/event/update_event.dart';
import 'package:nm_gen/domain/use_cases/event/delete_event.dart';
import 'package:nm_gen/domain/use_cases/event/delete_all_person_events.dart';
import 'package:nm_gen/presentation/blocs/event/event_event.dart';
import 'package:nm_gen/presentation/blocs/event/event_state.dart';

class EventBloc extends Bloc<EventEvent, EventState> {
  EventBloc({
    AddEventUseCase? addEventUseCase,
    GetEventsByPersonUseCase? getEventsByPersonUseCase,
    GetAllEventsUseCase? getAllEventsUseCase,
    UpdateEventUseCase? updateEventUseCase,
    DeleteEventUseCase? deleteEventUseCase,
    DeleteAllPersonEventsUseCase? deleteAllPersonEventsUseCase,
  }) : super(EventInitial()) {
    _addEventUseCase = addEventUseCase ?? getIt<AddEventUseCase>();
    _getEventsByPersonUseCase =
        getEventsByPersonUseCase ?? getIt<GetEventsByPersonUseCase>();
    _getAllEventsUseCase = getAllEventsUseCase ?? getIt<GetAllEventsUseCase>();
    _updateEventUseCase = updateEventUseCase ?? getIt<UpdateEventUseCase>();
    _deleteEventUseCase = deleteEventUseCase ?? getIt<DeleteEventUseCase>();
    _deleteAllPersonEventsUseCase =
        deleteAllPersonEventsUseCase ?? getIt<DeleteAllPersonEventsUseCase>();

    on<LoadPersonEventsEvent>(_onLoadPersonEvents);
    on<LoadAllEventsEvent>(_onLoadAllEvents);
    on<AddEventEvent>(_onAddEvent);
    on<UpdateEventEvent>(_onUpdateEvent);
    on<DeleteEventEvent>(_onDeleteEvent);
    on<DeleteAllPersonEventsEvent>(_onDeleteAllPersonEvents);
  }

  late final AddEventUseCase _addEventUseCase;
  late final GetEventsByPersonUseCase _getEventsByPersonUseCase;
  late final GetAllEventsUseCase _getAllEventsUseCase;
  late final UpdateEventUseCase _updateEventUseCase;
  late final DeleteEventUseCase _deleteEventUseCase;
  late final DeleteAllPersonEventsUseCase _deleteAllPersonEventsUseCase;

  Future<void> _onLoadPersonEvents(
    LoadPersonEventsEvent event,
    Emitter<EventState> emit,
  ) async {
    emit(EventLoading());
    final result = await _getEventsByPersonUseCase.execute(
      event.personId,
      treeId: event.treeId,
    );
    result.fold(
      (failure) => emit(EventError(failure.message)),
      (events) => emit(EventsLoaded(events: events, treeId: event.treeId)),
    );
  }

  Future<void> _onLoadAllEvents(
    LoadAllEventsEvent event,
    Emitter<EventState> emit,
  ) async {
    emit(EventLoading());
    final result = await _getAllEventsUseCase.execute(treeId: event.treeId);
    result.fold(
      (failure) => emit(EventError(failure.message)),
      (events) => emit(EventsLoaded(events: events, treeId: event.treeId)),
    );
  }

  Future<void> _onAddEvent(
    AddEventEvent event,
    Emitter<EventState> emit,
  ) async {
    emit(EventLoading());
    final result = await _addEventUseCase.execute(event.event);
    result.fold((failure) => emit(EventError(failure.message)), (savedEvent) {
      emit(const EventOperationSuccess('Событие добавлено'));
      add(
        LoadPersonEventsEvent(savedEvent.personId, treeId: savedEvent.treeId),
      );
    });
  }

  Future<void> _onUpdateEvent(
    UpdateEventEvent event,
    Emitter<EventState> emit,
  ) async {
    emit(EventLoading());
    final result = await _updateEventUseCase.execute(event.event);
    result.fold((failure) => emit(EventError(failure.message)), (updatedEvent) {
      emit(const EventOperationSuccess('Событие обновлено'));
      add(
        LoadPersonEventsEvent(
          updatedEvent.personId,
          treeId: updatedEvent.treeId,
        ),
      );
    });
  }

  Future<void> _onDeleteEvent(
    DeleteEventEvent event,
    Emitter<EventState> emit,
  ) async {
    emit(EventLoading());
    final result = await _deleteEventUseCase.execute(event.eventId);
    result.fold((failure) => emit(EventError(failure.message)), (deletedEvent) {
      emit(const EventOperationSuccess('Событие удалено'));
      if (deletedEvent != null) {
        add(
          LoadPersonEventsEvent(
            deletedEvent.personId,
            treeId: deletedEvent.treeId,
          ),
        );
      }
    });
  }

  Future<void> _onDeleteAllPersonEvents(
    DeleteAllPersonEventsEvent event,
    Emitter<EventState> emit,
  ) async {
    emit(EventLoading());
    final result = await _deleteAllPersonEventsUseCase.execute(
      event.personId,
      treeId: event.treeId,
    );
    result.fold((failure) => emit(EventError(failure.message)), (_) {
      emit(const EventOperationSuccess('Все события удалены'));
      add(LoadPersonEventsEvent(event.personId, treeId: event.treeId));
    });
  }
}
