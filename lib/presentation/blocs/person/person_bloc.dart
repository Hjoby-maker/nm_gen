import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nm_gen/di/injector.dart';
import 'package:nm_gen/domain/entities/family.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/repositories/family_repository.dart';
import 'package:nm_gen/domain/repositories/person_repository.dart';
import 'package:nm_gen/domain/use_cases/person/add_person.dart';
import 'package:nm_gen/domain/use_cases/person/delete_person.dart';
import 'package:nm_gen/domain/use_cases/person/get_all_persons.dart';
import 'package:nm_gen/domain/use_cases/person/search_persons.dart';
import 'package:nm_gen/domain/use_cases/person/update_person.dart';
import 'package:nm_gen/presentation/blocs/person/person_event.dart';
import 'package:nm_gen/presentation/blocs/person/person_state.dart';

class PersonBloc extends Bloc<PersonEvent, PersonState> {
  PersonBloc({
    required this.getAllPersonsUseCase,
    required this.addPersonUseCase,
    required this.updatePersonUseCase,
    required this.deletePersonUseCase,
    required this.searchPersonsUseCase,
    required this.familyRepository,
    required this.personRepository,
  }) : super(PersonInitial()) {
    on<LoadPersonsEvent>(_onLoadPersons);
    on<AddPersonEvent>(_onAddPerson);
    on<UpdatePersonEvent>(_onUpdatePerson);
    on<DeletePersonEvent>(_onDeletePerson);
    on<SearchPersonsEvent>(_onSearchPersons);
    on<ClearSearchEvent>(_onClearSearch);
    on<DeleteAllPersonsEvent>(_onDeleteAllPersons);
  }
  final GetAllPersonsUseCase getAllPersonsUseCase;
  final AddPersonUseCase addPersonUseCase;
  final UpdatePersonUseCase updatePersonUseCase;
  final DeletePersonUseCase deletePersonUseCase;
  final SearchPersonsUseCase searchPersonsUseCase;
  final FamilyRepository familyRepository;
  final PersonRepository personRepository;

  /// Обработчик: Загрузка всех людей
  Future<void> _onLoadPersons(
    LoadPersonsEvent event,
    Emitter<PersonState> emit,
  ) async {
    emit(PersonLoading());

    final result = await getAllPersonsUseCase.execute(treeId: event.treeId);

    result.fold(
      (failure) => emit(PersonError(failure.message)),
      (persons) => emit(PersonsLoaded(persons: persons, treeId: event.treeId)),
    );
  }

  /// Обработчик: Добавление человека
  Future<void> _onAddPerson(
    AddPersonEvent event,
    Emitter<PersonState> emit,
  ) async {
    emit(PersonLoading());

    // Добавляем treeId к человеку
    final personWithTree = event.person.treeId.isEmpty
        ? event.person.copyWith(treeId: event.treeId ?? 'default')
        : event.person;

    final result = await addPersonUseCase.execute(personWithTree);

    result.fold((failure) => emit(PersonError(failure.message)), (person) {
      add(LoadPersonsEvent(treeId: event.treeId));
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
      add(LoadPersonsEvent(treeId: event.treeId));
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
      add(LoadPersonsEvent(treeId: event.treeId));
      emit(const PersonOperationSuccess('Человек удален'));
    });
  }

  /// Обработчик: Поиск людей
  Future<void> _onSearchPersons(
    SearchPersonsEvent event,
    Emitter<PersonState> emit,
  ) async {
    if (event.query.isEmpty) {
      add(LoadPersonsEvent(treeId: event.treeId));
      return;
    }

    emit(PersonLoading());

    final result = await searchPersonsUseCase.execute(
      event.query,
      treeId: event.treeId,
    );

    result.fold(
      (failure) => emit(PersonError(failure.message)),
      (persons) => emit(
        PersonsLoaded(
          persons: persons,
          isSearching: true,
          searchQuery: event.query,
          treeId: event.treeId,
        ),
      ),
    );
  }

  /// Обработчик: Очистка поиска
  Future<void> _onClearSearch(
    ClearSearchEvent event,
    Emitter<PersonState> emit,
  ) async {
    final currentState = state;
    if (currentState is PersonsLoaded) {
      add(LoadPersonsEvent(treeId: currentState.treeId));
    } else {
      add(const LoadPersonsEvent());
    }
  }

  /// Обработчик: Удаление всех людей
  Future<void> _onDeleteAllPersons(
    DeleteAllPersonsEvent event,
    Emitter<PersonState> emit,
  ) async {
    emit(PersonLoading());

    try {
      // Выполняем удаление в отдельном изоляте для предотвращения зависания UI
      await compute(_deleteAllData, event.treeId);

      add(LoadPersonsEvent(treeId: event.treeId));
      emit(const PersonOperationSuccess('Все данные успешно удалены'));
    } catch (e) {
      emit(PersonError('Ошибка при удалении: ${e.toString()}'));
    }
  }
}

/// Функция для выполнения в отдельном изоляте
Future<void> _deleteAllData(String? treeId) async {
  final FamilyRepository familyRepo = getIt<FamilyRepository>();
  final PersonRepository personRepo = getIt<PersonRepository>();

  final List<Family> allFamilies = await familyRepo.getAllFamilies(
    treeId: treeId,
  );
  for (final Family family in allFamilies) {
    await familyRepo.deleteFamily(family.id);
  }

  final List<Person> allPersons = await personRepo.getAllPersons(
    treeId: treeId,
  );
  for (final Person person in allPersons) {
    await personRepo.deletePerson(person.id);
  }
}
