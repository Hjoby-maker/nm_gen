import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/entities/family.dart';
import 'package:nm_gen/domain/use_cases/person/add_person.dart';
import 'package:nm_gen/domain/use_cases/person/delete_person.dart';
import 'package:nm_gen/domain/use_cases/person/get_all_persons.dart';
import 'package:nm_gen/domain/use_cases/person/search_persons.dart';
import 'package:nm_gen/domain/use_cases/person/update_person.dart';
import 'package:nm_gen/presentation/blocs/person/person_event.dart';
import 'package:nm_gen/presentation/blocs/person/person_state.dart';
import 'package:nm_gen/domain/repositories/family_repository.dart';
import 'package:nm_gen/domain/repositories/person_repository.dart';
import 'package:nm_gen/di/injector.dart';

/// BLoC для управления персонами
class PersonBloc extends Bloc<PersonEvent, PersonState> {
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
    on<DeleteAllPersonsEvent>(_onDeleteAllPersons);
  }
  final GetAllPersonsUseCase getAllPersonsUseCase;
  final AddPersonUseCase addPersonUseCase;
  final UpdatePersonUseCase updatePersonUseCase;
  final DeletePersonUseCase deletePersonUseCase;
  final SearchPersonsUseCase searchPersonsUseCase;

  /// Обработчик: Загрузка всех людей
  Future<void> _onLoadPersons(
    LoadPersonsEvent event,
    Emitter<PersonState> emit,
  ) async {
    emit(PersonLoading());

    final Either<Failure, List<Person>> result = await getAllPersonsUseCase
        .execute();

    result.fold(
      (Failure failure) => emit(PersonError(failure.message)),
      (List<Person> persons) => emit(PersonsLoaded(persons: persons)),
    );
  }

  /// Обработчик: Добавление человека
  Future<void> _onAddPerson(
    AddPersonEvent event,
    Emitter<PersonState> emit,
  ) async {
    emit(PersonLoading());

    final Either<Failure, Person> result = await addPersonUseCase.execute(
      event.person,
    );

    result.fold((Failure failure) => emit(PersonError(failure.message)), (
      Person person,
    ) {
      // После успешного добавления загружаем обновленный список
      add(const LoadPersonsEvent());
      emit(PersonOperationSuccess('Человек "${person.displayName}" добавлен'));
    });
  }

  /// Обработчик: Обновление человека
  Future<void> _onUpdatePerson(
    UpdatePersonEvent event,
    Emitter<PersonState> emit,
  ) async {
    emit(PersonLoading());

    final Either<Failure, Person> result = await updatePersonUseCase.execute(
      event.person,
    );

    result.fold((Failure failure) => emit(PersonError(failure.message)), (
      Person person,
    ) {
      add(const LoadPersonsEvent());
      emit(PersonOperationSuccess('Данные "${person.displayName}" обновлены'));
    });
  }

  /// Обработчик: Удаление человека
  Future<void> _onDeletePerson(
    DeletePersonEvent event,
    Emitter<PersonState> emit,
  ) async {
    emit(PersonLoading());

    final Either<Failure, void> result = await deletePersonUseCase.execute(
      event.personId,
    );

    result.fold((Failure failure) => emit(PersonError(failure.message)), (_) {
      add(const LoadPersonsEvent());
      emit(const PersonOperationSuccess('Человек удален'));
    });
  }

  /// Обработчик: Поиск людей
  Future<void> _onSearchPersons(
    SearchPersonsEvent event,
    Emitter<PersonState> emit,
  ) async {
    if (event.query.isEmpty) {
      add(const LoadPersonsEvent());
      return;
    }

    emit(PersonLoading());

    final Either<Failure, List<Person>> result = await searchPersonsUseCase
        .execute(event.query);

    result.fold(
      (Failure failure) => emit(PersonError(failure.message)),
      (List<Person> persons) => emit(
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
    add(const LoadPersonsEvent());
  }

  Future<void> _onDeleteAllPersons(
    DeleteAllPersonsEvent event,
    Emitter<PersonState> emit,
  ) async {
    emit(PersonLoading());

    try {
      // Получаем репозитории из DI
      final FamilyRepository familyRepo = getIt<FamilyRepository>();
      final PersonRepository personRepo = getIt<PersonRepository>();

      // Сначала удаляем все семьи (чтобы не было нарушений внешних ключей)
      final List<Family> allFamilies = await familyRepo.getAllFamilies();
      for (final Family family in allFamilies) {
        await familyRepo.deleteFamily(family.id);
      }

      // Затем удаляем всех людей
      final List<Person> allPersons = await personRepo.getAllPersons();
      for (final Person person in allPersons) {
        await personRepo.deletePerson(person.id);
      }

      // Обновляем список
      add(const LoadPersonsEvent());
      emit(const PersonOperationSuccess('Все данные успешно удалены'));
    } catch (e) {
      emit(PersonError('Ошибка при удалении: ${e.toString()}'));
    }
  }
}
