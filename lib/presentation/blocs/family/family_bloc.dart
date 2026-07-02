import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nm_gen/core/errors/failures.dart';
import 'package:nm_gen/domain/entities/person.dart';
import 'package:nm_gen/domain/entities/family.dart';
import 'package:nm_gen/domain/repositories/family_repository.dart';
import 'package:nm_gen/domain/repositories/person_repository.dart';
import 'package:nm_gen/domain/use_cases/family/add_child_to_family.dart';
import 'package:nm_gen/domain/use_cases/family/add_family.dart';
import 'package:nm_gen/domain/use_cases/family/get_families_by_person.dart';
import 'package:nm_gen/domain/use_cases/family/get_family_with_details.dart';
import 'package:nm_gen/domain/use_cases/family/remove_child_from_family.dart';
import 'package:nm_gen/presentation/blocs/family/family_event.dart';
import 'package:nm_gen/presentation/blocs/family/family_state.dart';

class FamilyBloc extends Bloc<FamilyEvent, FamilyState> {
  FamilyBloc({
    required this.getFamiliesByPersonUseCase,
    required this.getFamilyWithDetailsUseCase,
    required this.addFamilyUseCase,
    required this.addChildToFamilyUseCase,
    required this.removeChildFromFamilyUseCase,
    required this.personRepository,
    required this.familyRepository,
  }) : super(FamilyInitial()) {
    on<LoadFamiliesEvent>(_onLoadFamilies);
    on<LoadFamilyDetailsEvent>(_onLoadFamilyDetails);
    on<AddFamilyEvent>(_onAddFamily);
    on<UpdateFamilyEvent>(_onUpdateFamily);
    on<DeleteFamilyEvent>(_onDeleteFamily);
    on<AddChildToFamilyEvent>(_onAddChildToFamily);
    on<RemoveChildFromFamilyEvent>(_onRemoveChildFromFamily);
    on<SelectFamilyEvent>(_onSelectFamily);
  }

  final GetFamiliesByPersonUseCase getFamiliesByPersonUseCase;
  final GetFamilyWithDetailsUseCase getFamilyWithDetailsUseCase;
  final AddFamilyUseCase addFamilyUseCase;
  final AddChildToFamilyUseCase addChildToFamilyUseCase;
  final RemoveChildFromFamilyUseCase removeChildFromFamilyUseCase;
  final PersonRepository personRepository;
  final FamilyRepository familyRepository;

  String? _currentPersonId;
  String? _currentTreeId; // <-- ДОБАВЛЯЕМ

  Future<void> _onLoadFamilies(
    LoadFamiliesEvent event,
    Emitter<FamilyState> emit,
  ) async {
    _currentPersonId = event.personId;
    _currentTreeId = event.treeId; // <-- ДОБАВЛЯЕМ
    emit(FamilyLoading());

    final Either<Failure, List<Family>> result =
        await getFamiliesByPersonUseCase.execute(
          event.personId,
          treeId: event.treeId,
        );

    await result.fold(
      (Failure failure) async {
        emit(FamilyError(failure.message));
      },
      (List<Family> families) async {
        final Map<String, Person> persons = await _loadPersonsFromFamilies(
          families,
          treeId: event.treeId,
        );
        if (!emit.isDone) {
          emit(
            FamiliesLoaded(
              families: families,
              persons: persons,
              treeId: event.treeId,
            ),
          );
        }
      },
    );
  }

  Future<void> _onLoadFamilyDetails(
    LoadFamilyDetailsEvent event,
    Emitter<FamilyState> emit,
  ) async {
    emit(FamilyLoading());

    final Either<Failure, FamilyDetails> result =
        await getFamilyWithDetailsUseCase.execute(
          event.familyId,
          treeId: event.treeId,
        );

    await result.fold(
      (Failure failure) async {
        if (!emit.isDone) {
          emit(FamilyError(failure.message));
        }
      },
      (FamilyDetails details) async {
        if (!emit.isDone) {
          emit(FamilyDetailsLoaded(details, treeId: event.treeId));
        }
      },
    );
  }

  Future<void> _onAddFamily(
    AddFamilyEvent event,
    Emitter<FamilyState> emit,
  ) async {
    emit(FamilyLoading());

    // Добавляем treeId к семье
    final familyWithTree = event.family.treeId.isEmpty
        ? event.family.copyWith(treeId: event.treeId ?? 'default')
        : event.family;

    final Either<Failure, Family> result = await addFamilyUseCase.execute(
      familyWithTree,
    );

    await result.fold(
      (Failure failure) async {
        if (!emit.isDone) {
          emit(FamilyError(failure.message));
        }
      },
      (_) async {
        if (!emit.isDone) {
          emit(const FamilyOperationSuccess('Семья создана'));
        }
        if (_currentPersonId != null) {
          add(LoadFamiliesEvent(_currentPersonId!, treeId: event.treeId));
        }
      },
    );
  }

  Future<void> _onUpdateFamily(
    UpdateFamilyEvent event,
    Emitter<FamilyState> emit,
  ) async {
    emit(FamilyLoading());

    try {
      await familyRepository.updateFamily(event.family);
      if (!emit.isDone) {
        emit(const FamilyOperationSuccess('Семья обновлена'));
      }
      if (_currentPersonId != null) {
        add(LoadFamiliesEvent(_currentPersonId!, treeId: event.treeId));
      }
    } catch (e) {
      if (!emit.isDone) {
        emit(FamilyError(e.toString()));
      }
    }
  }

  Future<void> _onDeleteFamily(
    DeleteFamilyEvent event,
    Emitter<FamilyState> emit,
  ) async {
    emit(FamilyLoading());

    try {
      await familyRepository.deleteFamily(event.familyId);
      if (!emit.isDone) {
        emit(const FamilyOperationSuccess('Семья удалена'));
      }
      if (_currentPersonId != null) {
        add(LoadFamiliesEvent(_currentPersonId!, treeId: event.treeId));
      }
    } catch (e) {
      if (!emit.isDone) {
        emit(FamilyError(e.toString()));
      }
    }
  }

  Future<void> _onAddChildToFamily(
    AddChildToFamilyEvent event,
    Emitter<FamilyState> emit,
  ) async {
    emit(FamilyLoading());

    final Either<Failure, void> result = await addChildToFamilyUseCase.execute(
      event.familyId,
      event.childId,
    );

    await result.fold(
      (Failure failure) async {
        if (!emit.isDone) {
          emit(FamilyError(failure.message));
        }
      },
      (_) async {
        if (!emit.isDone) {
          emit(const FamilyOperationSuccess('Ребенок добавлен в семью'));
        }
        if (_currentPersonId != null) {
          add(LoadFamiliesEvent(_currentPersonId!, treeId: event.treeId));
        }
      },
    );
  }

  Future<void> _onRemoveChildFromFamily(
    RemoveChildFromFamilyEvent event,
    Emitter<FamilyState> emit,
  ) async {
    emit(FamilyLoading());

    final Either<Failure, void> result = await removeChildFromFamilyUseCase
        .execute(event.familyId, event.childId);

    await result.fold(
      (Failure failure) async {
        if (!emit.isDone) {
          emit(FamilyError(failure.message));
        }
      },
      (_) async {
        if (!emit.isDone) {
          emit(const FamilyOperationSuccess('Ребенок удален из семьи'));
        }
        if (_currentPersonId != null) {
          add(LoadFamiliesEvent(_currentPersonId!, treeId: event.treeId));
        }
      },
    );
  }

  void _onSelectFamily(SelectFamilyEvent event, Emitter<FamilyState> emit) {
    final FamilyState currentState = state;
    if (currentState is FamiliesLoaded) {
      emit(
        FamiliesLoaded(
          families: currentState.families,
          persons: currentState.persons,
          selectedFamilyId: event.familyId,
          treeId: event.treeId ?? currentState.treeId,
        ),
      );
    }
  }

  Future<Map<String, Person>> _loadPersonsFromFamilies(
    List<Family> families, {
    String? treeId,
  }) async {
    final Map<String, Person> persons = <String, Person>{};
    for (final Family family in families) {
      if (family.husbandId != null) {
        final Person? person = await personRepository.getPerson(
          family.husbandId!,
        );
        if (person != null) persons[family.husbandId!] = person;
      }
      if (family.wifeId != null) {
        final Person? person = await personRepository.getPerson(family.wifeId!);
        if (person != null) persons[family.wifeId!] = person;
      }
      for (final String childId in family.childrenIds) {
        final Person? person = await personRepository.getPerson(childId);
        if (person != null) persons[childId] = person;
      }
    }
    return persons;
  }
}
