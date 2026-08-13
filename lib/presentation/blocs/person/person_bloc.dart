// lib/presentation/blocs/person/person_bloc.dart
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
import 'package:nm_gen/domain/use_cases/person/get_favorite_persons.dart';
import 'package:nm_gen/domain/use_cases/person/search_favorite_persons.dart';
import 'package:nm_gen/domain/use_cases/person/search_persons.dart';
import 'package:nm_gen/domain/use_cases/person/update_person.dart';
import 'package:nm_gen/presentation/blocs/person/person_event.dart';
import 'package:nm_gen/presentation/blocs/person/person_state.dart';

class PersonBloc extends Bloc<PersonEvent, PersonState> {
  PersonBloc({
    required this.getAllPersonsUseCase,
    required this.getFavoritePersonsUseCase,
    required this.addPersonUseCase,
    required this.updatePersonUseCase,
    required this.deletePersonUseCase,
    required this.searchPersonsUseCase,
    required this.searchFavoritePersonsUseCase,
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
    on<ToggleFavoriteEvent>(_onToggleFavorite);
    on<ToggleShowFavoritesEvent>(_onToggleShowFavorites);
  }

  final GetAllPersonsUseCase getAllPersonsUseCase;
  final GetFavoritePersonsUseCase getFavoritePersonsUseCase;
  final AddPersonUseCase addPersonUseCase;
  final UpdatePersonUseCase updatePersonUseCase;
  final DeletePersonUseCase deletePersonUseCase;
  final SearchPersonsUseCase searchPersonsUseCase;
  final SearchFavoritePersonsUseCase searchFavoritePersonsUseCase;
  final FamilyRepository familyRepository;
  final PersonRepository personRepository;

  /// Обработчик: Загрузка всех людей
  Future<void> _onLoadPersons(
    LoadPersonsEvent event,
    Emitter<PersonState> emit,
  ) async {
    emit(PersonLoading());

    late final result;

    if (event.onlyFavorites) {
      result = await getFavoritePersonsUseCase.execute(treeId: event.treeId);
    } else {
      result = await getAllPersonsUseCase.execute(treeId: event.treeId);
    }

    result.fold(
      (failure) => emit(PersonError(failure.message)),
      (persons) => emit(
        PersonsLoaded(
          persons: persons,
          treeId: event.treeId,
          onlyFavorites: event.onlyFavorites,
        ),
      ),
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
      add(LoadPersonsEvent(treeId: event.treeId, onlyFavorites: false));
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
      final currentState = state;
      if (currentState is PersonsLoaded) {
        add(
          LoadPersonsEvent(
            treeId: event.treeId ?? currentState.treeId,
            onlyFavorites: currentState.onlyFavorites,
          ),
        );
      } else {
        add(LoadPersonsEvent(treeId: event.treeId, onlyFavorites: false));
      }
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
      final currentState = state;
      if (currentState is PersonsLoaded) {
        add(
          LoadPersonsEvent(
            treeId: event.treeId ?? currentState.treeId,
            onlyFavorites: currentState.onlyFavorites,
          ),
        );
      } else {
        add(LoadPersonsEvent(treeId: event.treeId, onlyFavorites: false));
      }
      emit(const PersonOperationSuccess('Человек удален'));
    });
  }

  /// Обработчик: Поиск людей
  Future<void> _onSearchPersons(
    SearchPersonsEvent event,
    Emitter<PersonState> emit,
  ) async {
    if (event.query.isEmpty) {
      add(
        LoadPersonsEvent(
          treeId: event.treeId,
          onlyFavorites: event.onlyFavorites,
        ),
      );
      return;
    }

    emit(PersonLoading());

    late final result;

    if (event.onlyFavorites) {
      result = await searchFavoritePersonsUseCase.execute(
        event.query,
        treeId: event.treeId,
      );
    } else {
      result = await searchPersonsUseCase.execute(
        event.query,
        treeId: event.treeId,
      );
    }

    result.fold(
      (failure) => emit(PersonError(failure.message)),
      (persons) => emit(
        PersonsLoaded(
          persons: persons,
          isSearching: true,
          searchQuery: event.query,
          treeId: event.treeId,
          onlyFavorites: event.onlyFavorites,
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
      add(
        LoadPersonsEvent(
          treeId: currentState.treeId,
          onlyFavorites: currentState.onlyFavorites,
        ),
      );
    } else {
      add(const LoadPersonsEvent(onlyFavorites: false));
    }
  }

  /// Обработчик: Переключение избранного
  Future<void> _onToggleFavorite(
    ToggleFavoriteEvent event,
    Emitter<PersonState> emit,
  ) async {
    final Person updatedPerson = event.person.copyWith(
      isFavorite: !event.person.isFavorite,
      updatedAt: DateTime.now(),
    );

    final result = await updatePersonUseCase.execute(updatedPerson);

    result.fold((failure) => emit(PersonError(failure.message)), (person) {
      final currentState = state;
      if (currentState is PersonsLoaded) {
        add(
          LoadPersonsEvent(
            treeId: currentState.treeId,
            onlyFavorites: currentState.onlyFavorites,
          ),
        );
      } else {
        add(const LoadPersonsEvent(onlyFavorites: false));
      }
      emit(
        PersonOperationSuccess(
          person.isFavorite ? 'Добавлено в избранное' : 'Убрано из избранного',
        ),
      );
    });
  }

  /// Обработчик: Переключение фильтра "Только избранные"
  Future<void> _onToggleShowFavorites(
    ToggleShowFavoritesEvent event,
    Emitter<PersonState> emit,
  ) async {
    final currentState = state;
    if (currentState is PersonsLoaded) {
      add(
        LoadPersonsEvent(
          treeId: currentState.treeId,
          onlyFavorites: !currentState.onlyFavorites,
        ),
      );
    } else {
      add(const LoadPersonsEvent(onlyFavorites: true));
    }
  }

  /// Обработчик: Удаление всех людей
  Future<void> _onDeleteAllPersons(
    DeleteAllPersonsEvent event,
    Emitter<PersonState> emit,
  ) async {
    emit(PersonLoading());

    try {
      await compute(_deleteAllData, event.treeId);

      add(LoadPersonsEvent(treeId: event.treeId, onlyFavorites: false));
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
