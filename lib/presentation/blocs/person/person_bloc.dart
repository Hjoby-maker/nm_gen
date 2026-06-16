import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nm_gen/domain/use_cases/person/add_person.dart';
import 'package:nm_gen/domain/use_cases/person/delete_person.dart';
import 'package:nm_gen/domain/use_cases/person/get_all_persons.dart';
import 'package:nm_gen/domain/use_cases/person/search_persons.dart';
import 'package:nm_gen/domain/use_cases/person/update_person.dart';
import 'package:nm_gen/presentation/blocs/person/person_event.dart';
import 'package:nm_gen/presentation/blocs/person/person_state.dart';

/// BLoC для управления персонами
class PersonBloc extends Bloc<PersonEvent, PersonState> {
  final GetAllPersonsUseCase getAllPersonsUseCase;
  final AddPersonUseCase addPersonUseCase;
  final UpdatePersonUseCase updatePersonUseCase;
  final DeletePersonUseCase deletePersonUseCase;
  final SearchPersonsUseCase searchPersonsUseCase;

  PersonBloc({
    required this.getAllPersonsUseCase,
    required this.addPersonUseCase,
    required this.updatePersonUseCase,
    required this.deletePersonUseCase,
    required this.searchPersonsUseCase,
  }) : super(PersonInitial()) {
    // Регистрируем обработчики событий
    on<LoadPersonsEvent>(_onLoadPersons);
    on<AddPersonEvent>(_onAddPerson);
    on<UpdatePersonEvent>(_onUpdatePerson);
    on<DeletePersonEvent>(_onDeletePerson);
    on<SearchPersonsEvent>(_onSearchPersons);
    on<ClearSearchEvent>(_onClearSearch);
  }

  /// Обработчик: Загрузка всех людей
  Future<void> _onLoadPersons(
    LoadPersonsEvent event,
    Emitter<PersonState> emit,
  ) async {
    emit(PersonLoading());

    final result = await getAllPersonsUseCase.execute();

    result.fold(
      (failure) => emit(PersonError(failure.message)),
      (persons) => emit(PersonsLoaded(persons: persons)),
    );
  }

  /// Обработчик: Добавление человека
  Future<void> _onAddPerson(
    AddPersonEvent event,
    Emitter<PersonState> emit,
  ) async {
    emit(PersonLoading());

    final result = await addPersonUseCase.execute(event.person);

    result.fold((failure) => emit(PersonError(failure.message)), (person) {
      // После успешного добавления загружаем обновленный список
      add(LoadPersonsEvent());
      emit(PersonOperationSuccess('Человек "${person.displayName}" добавлен'));
    });
  }

  /// Обработчик: Обновление человека
  Future<void> _onUpdatePerson(
    UpdatePersonEvent event,
    Emitter<PersonState> emit,
  ) async {
    emit(PersonLoading());

    final result = await updatePersonUseCase.execute(event.person);

    result.fold((failure) => emit(PersonError(failure.message)), (person) {
      add(LoadPersonsEvent());
      emit(PersonOperationSuccess('Данные "${person.displayName}" обновлены'));
    });
  }

  /// Обработчик: Удаление человека
  Future<void> _onDeletePerson(
    DeletePersonEvent event,
    Emitter<PersonState> emit,
  ) async {
    emit(PersonLoading());

    final result = await deletePersonUseCase.execute(event.personId);

    result.fold((failure) => emit(PersonError(failure.message)), (_) {
      add(LoadPersonsEvent());
      emit(const PersonOperationSuccess('Человек удален'));
    });
  }

  /// Обработчик: Поиск людей
  Future<void> _onSearchPersons(
    SearchPersonsEvent event,
    Emitter<PersonState> emit,
  ) async {
    if (event.query.isEmpty) {
      add(LoadPersonsEvent());
      return;
    }

    emit(PersonLoading());

    final result = await searchPersonsUseCase.execute(event.query);

    result.fold(
      (failure) => emit(PersonError(failure.message)),
      (persons) => emit(
        PersonsLoaded(
          persons: persons,
          isSearching: true,
          searchQuery: event.query,
        ),
      ),
    );
  }

  /// Обработчик: Очистка поиска
  Future<void> _onClearSearch(
    ClearSearchEvent event,
    Emitter<PersonState> emit,
  ) async {
    add(LoadPersonsEvent());
  }
}
